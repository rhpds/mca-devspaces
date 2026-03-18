# Developer Lightspeed for MTA - DevSpaces

Red Hat OpenShift Dev Spaces container and devfile for [Developer Lightspeed for MTA](https://developers.redhat.com/products/mta/developer-lightspeed).

## Features

- Python 3.11, Java 17, Node.js, Maven
- MTA VS Code extension (v8.0.5) pre-installed
- 10Gi memory allocation

## Usage

1. Add this repository to your Dev Spaces workspace or build your own devFile using the container file.
2. The example devfile automatically provisions the container with all dependencies

## Container

Built from `quay.io/devfile/universal-developer-image:ubi9-latest` with Developer lightspeed requirements.

Image: `quay.io/sshaaf/dls-devspaces:latest`
