# Developer Lightspeed for MTA - DevSpaces

Red Hat OpenShift Dev Spaces container and devfile for [Developer Lightspeed for MTA](https://developers.redhat.com/products/mta/developer-lightspeed).

## Features

- Red Hat Java extension and Java Extension Pack (preloaded as VSIX in the custom image; see `containerfile`)
- MTA VS Code extensions (v8.1.1) pre-installed
- 10Gi memory limit on the main dev container
- Che Code (VS Code–compatible) editor configuration via `config/che-editor` (settings, policy, `product.json`)

## Repository layout

| Path | Purpose |
|------|---------|
| `devfile.yaml` | Devfile 2.2.0: component image, `projects` (e.g. sample app), optional setup commands |
| `containerfile` | Builds the workshop image: downloads VSIX bundles and sets `DEFAULT_EXTENSIONS` for the Universal Developer Image base |
| `config/che-editor/` | Files merged into the Che **`vscode-editor-configurations`** ConfigMap (`settings.json`, `extensions.json`, `product.json`, `configurations.json`, `policy.json`) |
| `scripts/devspaces-create-and-start.sh` | Creates a `DevWorkspace` from a local devfile and applies the editor ConfigMap (Kubernetes API, Dev Spaces 3.x) |
| `ansible/devspaces_devworkspace.yml` | Same flow as the script, via `kubernetes.core` |
| `ansible/run-dls-playbook.sh` | Runs the playbook with a venv that has the `kubernetes` Python package |

## Prerequisites

- An **OpenShift** cluster with **OpenShift Dev Spaces** installed, and a **namespace** where you can create a `DevWorkspace` (often your personal `-che` or team project).
- **Logged in** with `oc login` (or `kubectl` with a valid context). The automation uses the current project when you do not pass a namespace explicitly.
- For `scripts/devspaces-create-and-start.sh`: **[mikefarah/yq](https://github.com/mikefarah/yq) v4+** (not the PyPI `yq` wrapper around `jq`).

## Using this repository

### 1) Open a workspace from Git (browser / “factory”)

Use this when the devfile is available at a **raw** URL (for example on GitHub: **Raw** file, not the HTML page).

1. Build the factory link (replace the base URL with your Dev Spaces route, e.g. `https://devspaces.apps.<cluster>.com`):

   ```bash
   ./scripts/devspaces-create-and-start.sh factory-url \
     --devspaces-base 'https://devspaces.apps.mycluster.com' \
     --raw-devfile-url 'https://raw.githubusercontent.com/ORG/REPO/BRANCH/devfile.yaml'
   ```

2. Open the printed URL in a browser where you are **logged into OpenShift**. Dev Spaces will clone the devfile and start the workspace.

**Ansible equivalent** (no `yq` required for this mode):

```bash
cd ansible
./run-dls-playbook.sh -e dls_mode=factory \
  -e dls_devspaces_base='https://devspaces.apps.mycluster.com' \
  -e dls_raw_devfile_url='https://raw.githubusercontent.com/ORG/REPO/BRANCH/devfile.yaml'
```

### 2) Create a DevWorkspace from a local clone (script)

From the root of this repository (after `git clone`):

1. Select the target project (or pass `-n <namespace>`):

   ```bash
   oc project <your-dev-spaces-namespace>
   ```

2. Create and start the workspace (applies the `vscode-editor-configurations` ConfigMap from `config/che-editor/`, then applies the `DevWorkspace`):

   ```bash
   ./scripts/devspaces-create-and-start.sh
   ```

   Common options: `-f path/to/devfile.yaml`, `-n NAMESPACE`, `-w devworkspace-name`, `--dry-run`, `--no-wait`. See the script header for the full list.

3. If the wait succeeds, the script prints a **Workspace URL** from `DevWorkspace` status. You can also use the Dev Spaces dashboard for that namespace.

**Override editor config directory** (defaults to `./config/che-editor`):

```bash
VSCODE_EDITOR_CONFIG_DIR=/path/to/editor-config ./scripts/devspaces-create-and-start.sh
```

**Skip the ConfigMap** (only for debugging; the cluster will not merge your `config/che-editor` files):

```bash
./scripts/devspaces-create-and-start.sh --skip-vscode-editor-config
```

### 3) Create a DevWorkspace with Ansible

```bash
cd ansible
./setup-venv.sh          # once: creates .venv and installs dependencies
./run-dls-playbook.sh -e dls_k8s_namespace=your-namespace
```

See `ansible/devspaces_devworkspace.yml` for extra variables (`dls_dry_run`, `dls_apply_vscode_editor_configmap`, `dls_che_editor_config_dir`, factory mode, etc.).

### 4) Custom container image (optional)

The `devfile.yaml` references a prebuilt image. To use your own:

1. Build and push from `containerfile` (example with Podman; tag and registry are yours):

   ```bash
   podman build -f containerfile -t quay.io/yourorg/dls-devspaces:tag .
   podman push quay.io/yourorg/dls-devspaces:tag
   ```

2. Point the devfile at the new image: in `devfile.yaml`, under `components[].container`, set `image:` to your tag.

3. Re-create or update the `DevWorkspace` so the new image is pulled (policy and pull secrets are cluster-specific).

Base image: `quay.io/devfile/universal-developer-image:ubi9-latest`, with Red Hat Java / Java pack / MTA VSIX paths listed in `ENV DEFAULT_EXTENSIONS=...` in `containerfile`.

## Container image reference

Published example: `quay.io/sshaaf/dls-devspaces:latest` (built from `containerfile` on `quay.io/devfile/universal-developer-image:ubi9-latest`).

## Further reading

- [Editor configurations for Microsoft Visual Studio Code (Eclipse Che)](https://eclipse.dev/che/docs/stable/administration-guide/editor-configurations-for-microsoft-visual-studio-code/) (explains the `vscode-editor-configurations` ConfigMap keys used under `config/che-editor/`)
