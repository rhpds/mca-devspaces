# Developer Lightspeed for MTA - DevSpaces

Red Hat OpenShift Dev Spaces container and devfile for [Developer Lightspeed for MTA](https://developers.redhat.com/products/mta/developer-lightspeed).

## Features

- Python 3.11, Java 17, Node.js, Maven (from [Universal Developer Image](https://quay.io/repository/devfile/universal-developer-image))
- Red Hat Java + MTA VS Code extensions (8.1.1) pre-installed via `DEFAULT_EXTENSIONS` (see below)
- 10Gi memory allocation

## How extensions are installed (first-time and every time)

**Yes, the approach is correct for this product.** In OpenShift Dev Spaces, the default editor (che-code) uses the UDI as its runtime. The `DEFAULT_EXTENSIONS` environment variable is the supported way to point at `.vsix` paths so the editor installs them in the background right after the workspace and editor start—without relying on a user to run “Install from VSIX.” Multiple paths are separated with semicolons, as in the [Eclipse Che administration guide for default extensions](https://eclipse.dev/che/docs/stable/administration-guide/default-extensions-for-microsoft-visual-studio-code/).

This image stores `.vsix` files under `/opt/vscode-extensions/` in the image and sets `DEFAULT_EXTENSIONS` there. The same variable is also set in `devfile.yaml` so the workspace spec is easy to read and review.

**Cluster policy:** if extension installation is blocked, check your platform’s [extension installation / policy ConfigMaps](https://eclipse.dev/che/docs/stable/administration-guide/manage-extension-installation/) and allow the IDs you need.

**Note:** Java support is a separate `.vsix` from the published Red Hat build (linux-x64); the MTA extension expects a Java language stack, so install order is Java, then MTA core, then MTA Java.

## Usage

1. Add this repository to your Dev Spaces workspace or use the devfile in your project.
2. The devfile points at the published image and `DEFAULT_EXTENSIONS` for the tool container.

## Warming a workspace (before a user opens the browser)

The editor process starts when the `DevWorkspace` is running, so the extension background install is triggered on workspace start—not only on first open of the web UI. To validate images or dependencies before a class opens the URL:

- **Kubernetes / OpenShift:** start the `DevWorkspace` (factory link, dashboard, or API), then wait until it is **Running**. You can use `scripts/wait-devworkspace-running.sh` (requires `kubectl` or `oc` and a kube context).
- **REST / gitops:** the controller is the DevWorkspace (workspace.devfile.io) API. Typical pattern: create or update a `DevWorkspace` in the user namespace, poll `status.phase` until it is `Running` (or use `kubectl wait` with a JSONPath on `status.phase` as in the script). A generic “Che HTTP” endpoint is not required for *extension* pre-install; the important part is a successful workspace run so che-code can read `DEFAULT_EXTENSIONS` and run the install.

**Limitation:** a fully interactive “all MTA wizards and Java LSP are idle-ready” test still means opening a project in the editor at least once; the script only ensures the pod and editor lifecycle have completed.

## Container

Built from `quay.io/devfile/universal-developer-image:ubi9-latest` with extension `.vsix` and `DEFAULT_EXTENSIONS` in `containerfile`.

Image: `quay.io/sshaaf/dls-devspaces:latest`
