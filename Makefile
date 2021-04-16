SHELL := $(shell which bash)
.SHELLFLAGS := -eo pipefail -c

REPO_URL := https://flypenguin.github.io/helm-stasico/


_lint:
	helm lint stasico
.PHONY: _lint

_minor: _lint
	bumpversion minor
.PHONY: _minor

_major: _lint
	bumpversion major
.PHONY: _major

_patch: _lint
	bumpversion patch
.PHONY: _patch

_package:
	helm repo index --url ${REPO_URL} ./docs
	helm package -d ./docs stasico
.PHONY: _package

_commit:
	@if ! git diff --quiet docs/ ; then \
	  git add docs/ ; \
	  git commit -m "add new version binary" ; \
	fi ; \
	echo "Execute 'make upload' for pushing."
.PHONY: _commit


minor: _minor _package _commit
.PHONY: minor

major: _major _package _commit
.PHONY: major

patch: _patch _package _commit
.PHONY: patch

chart: _chart _commit
.PHONY: chart

package: _package
.PHONY: package

commit: _commit
.PHONY: commit

upload:
	@git diff --quiet || (echo "Please commit before uploading, working dir is dirty." && false)
	git push && git push --tags
.PHONY: upload
