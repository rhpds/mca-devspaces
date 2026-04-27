# Use official Dev Spaces base 
FROM quay.io/devfile/universal-developer-image:ubi9-latest

USER root

# Add MTA and Java extensions

# Add MTA and Java extensions
RUN curl -L -o /mta-vscode-extension-core.vsix https://github.com/migtools/editor-extensions/releases/download/v8.1.1/mta-core-8.1.1.vsix
RUN curl -L -o /mta-vscode-extension-java.vsix https://github.com/migtools/editor-extensions/releases/download/v8.1.1/mta-java-8.1.1.vsix
RUN curl -L -o /redhat-java-extension-linux-x64.vsix https://github.com/redhat-developer/vscode-java/releases/download/v1.54.0/vscode-java-1.54.0-923.vsix

ENV DEFAULT_EXTENSIONS=/redhat-java-extension-linux-x64.vsix;/mta-vscode-extension-core.vsix;/mta-vscode-extension-java.vsix

USER user
