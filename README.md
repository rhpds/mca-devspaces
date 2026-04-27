# Developer Lightspeed for MTA - DevSpaces

Red Hat OpenShift Dev Spaces container and devfile for [Developer Lightspeed for MTA](https://developers.redhat.com/products/mta/developer-lightspeed).

## Features
- Red Hat Java extension (1.54.0)
- MTA VS Code extension (v8.1.1) pre-installed
- 10Gi memory allocation

## Usage

1. Add this repository to your Dev Spaces workspace or build your own devFile using the container file.
2. The example devfile automatically provisions the container with all dependencies

## Container

Built from `quay.io/devfile/universal-developer-image:ubi9-latest` with Developer lightspeed requirements.

Image: `quay.io/sshaaf/dls-devspaces:latest`
