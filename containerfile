# Red Hat OpenShift Dev Spaces: che-code runs in the UDI; DEFAULT_EXTENSIONS is read at editor
# startup to install .vsix files in the background. See:
# https://eclipse.dev/che/docs/stable/administration-guide/default-extensions-for-microsoft-visual-studio-code/
FROM quay.io/devfile/universal-developer-image:ubi9-latest

USER 0

ARG VSIX_DIR=/opt/vscode-extensions
RUN mkdir -p "${VSIX_DIR}" && \
  curl -fsSL -o "${VSIX_DIR}/redhat-java-extension-linux-x64.vsix" \
    "https://github.com/redhat-developer/vscode-java/releases/download/v1.53.0/java-linux-x64-1.53.0-873.vsix" && \
  curl -fsSL -o "${VSIX_DIR}/mta-vscode-extension-core.vsix" \
    "https://github.com/migtools/editor-extensions/releases/download/v8.1.1/mta-core-8.1.1.vsix" && \
  curl -fsSL -o "${VSIX_DIR}/mta-vscode-extension-java.vsix" \
    "https://github.com/migtools/editor-extensions/releases/download/v8.1.1/mta-java-8.1.1.vsix" && \
  chgrp -R 0 "${VSIX_DIR}" && chmod -R g=u "${VSIX_DIR}" && chmod -R a+r "${VSIX_DIR}"

# Order: language support first, then MTA (per MTA + Java common setup).
ENV DEFAULT_EXTENSIONS="${VSIX_DIR}/redhat-java-extension-linux-x64.vsix;${VSIX_DIR}/mta-vscode-extension-core.vsix;${VSIX_DIR}/mta-vscode-extension-java.vsix"

USER 10001
