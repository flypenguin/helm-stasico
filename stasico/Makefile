SHELL := $(shell which bash)
.SHELLFLAGS := -eo pipefail -c

_minor:
	bumpversion minor

_major:
	bumpversion major

_patch:
	bumpversion patch

_chart:
	helm lint
	helm package -d ../docs .
	source .chart-settings.sh \
	&& helm repo index --url $$REPO_URL ../docs

minor: _minor _chart

major: _major _chart

patch: _patch _chart

chart: _chart
