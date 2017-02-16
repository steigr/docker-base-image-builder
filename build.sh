#!/usr/bin/env bash

set -x
set -eo pipefail

vars() {
	export GITHUB_DOCKER_IMAGES_REPO="${GITHUB_DOCKER_IMAGES_REPO:-git@github.com:steigr/docker-base-images.git}"
}

main() {
	prepare
	build "$@"
}

images() {
	 git ls-remote --refs "${GITHUB_DOCKER_IMAGES_REPO}" | awk '{print $2}' | cut -f3- -d/ | sort -n
}

create_image() {
	make -C "$1" scratch
	make -C "$1" Dockerfile
}

clean_git() {
		mkdir ../temp
		mv * ../temp
		git checkout -b master
		git branch -D "$1"
		git checkout --orphan "$1"
		git rm --cached -r .
		rm -fr ./*
		mv ../temp/* .
		rm -rf ../temp
		git add .
		git commit -m "update $1 - $(date +%Y%m%d)"
}

prepare() {
	[[ ! -d temp ]] || rm -rf temp
	[[ ! -d build ]] || rm -rf build
	git config --global user.name "CircleCI"
	git config --global user.email circleci@stei.gr
	ssh-add -L
}

build() {
	for image in $(images); do
		set +e
		git clone --branch "$image" "${GITHUB_DOCKER_IMAGES_REPO}" "build"
		pushd build
		target="$(find * -name Makefile -exec dirname '{}' ';' | head -1)"
		create_image "$target"
		clean_git "$image"
		[[ "$DRY_RUN" ]] || git push -f origin "$image"
		popd
		rm -rf "build"
		set -eo pipefail
	done
}

vars
main "$@"