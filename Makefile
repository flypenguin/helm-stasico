SHELL := $(shell which bash)
.SHELLFLAGS := -eo pipefail -c

REPO_URL := https://flypenguin.github.io/helm-stasico/


_lint:
	helm lint stasico

_minor: _lint
	bumpversion minor

_major: _lint
	bumpversion major

_patch: _lint
	bumpversion patch

_chart:
	helm package -d ./docs stasico
	echo helm repo index --url ${REPO_URL} ./docs

minor: _minor _chart

major: _major _chart

patch: _patch _chart

chart: _chart
