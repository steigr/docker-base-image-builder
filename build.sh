#!/usr/bin/env bash

set -eo pipefail

vars() {
	export GITHUB_DOCKER_IMAGES_REPO="${GITHUB_DOCKER_IMAGES_REPO:-git@github.com:steigr/docker-base-images.git}"
}

main() {
	build "$@"
}

images() {
	 git ls-remote --refs "${GITHUB_DOCKER_IMAGES_REPO}" | awk '{print $2}' | cut -f3- -d/
}

create_image() {
	make -C "$1" scratch
	make -C "$1" Dockerfile
}

clean_git() {
		mkdir ../temp
		mv * ../temp
		git checkout master
		git branch -D "$1"
		git checkout --orphan "$1"
		git rm --cached -r .
		rm -fr ./*
		mv ../temp/* .
		rm -rf ../temp
		git add .
		git commit -m "update $1 - $(date +%Y%m%d)"
}

build() {
	for image in $(images); do
		git clone --branch "$image" "${GITHUB_DOCKER_IMAGES_REPO}" "build"
		pushd build
		target="$(find * -name Makefile -exec dirname '{}' ';' | head -1)"
		create_image "$target"
		clean_git "$image"
		git push -f origin "$image"
		popd
		rm -rf "build"
	done
}

vars
main "$@"