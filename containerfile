# Use official Dev Spaces base 
FROM quay.io/devfile/universal-developer-image:ubi9-latest

USER root

# Add MTA and Java extensions
RUN curl -L -o /mta-vscode-extension-core.vsix https://github.com/migtools/editor-extensions/releases/download/v8.1.1/mta-core-8.1.1.vsix

ENV DEFAULT_EXTENSIONS=/mta-vscode-extension-core.vsix;

USER user
