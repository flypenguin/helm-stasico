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

_helm_index:
	helm repo index --url ${REPO_URL} ./docs
.PHONY: _helm_index

_helm_package:
	helm package -d ./docs stasico
.PHONY: _helm_package

_chart: _helm_package _helm_index
.PHONY: _chart

minor: _minor _chart
.PHONY: minor

major: _major _chart
.PHONY: major

patch: _patch _chart
.PHONY: patch

chart: _chart
.PHONY: chart

index: _helm_index
.PHONY: index

upload:
	git add docs/
	git commit -m "add new version binary"
	git push
.PHONY: upload
