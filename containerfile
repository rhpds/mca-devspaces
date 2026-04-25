# Use official Dev Spaces base 
FROM quay.io/devfile/universal-developer-image:ubi9-latest

USER root

# Add MTA and Java extensions
RUN curl -L -o /mta-vscode-extension-core.vsix https://github.com/migtools/editor-extensions/releases/download/v8.1.1/mta-core-8.1.1.vsix
RUN curl -L -o /mta-vscode-extension-java.vsix https://github.com/migtools/editor-extensions/releases/download/v8.1.1/mta-java-8.1.1.vsix
RUN curl -L -o /redhat-java-extension-linux-x64.vsix https://github.com/redhat-developer/vscode-java/releases/download/v1.53.0/java-linux-x64-1.53.0-873.vsix

RUN curl -L -o mta-core.vsix https://github.com/migtools/editor-extensions/releases/download/v8.1.1/mta-core-8.1.1.vsix && \
    curl -L -o mta-java.vsix https://github.com/migtools/editor-extensions/releases/download/v8.1.1/mta-java-8.1.1.vsix && \
    curl -L -o redhat-java.vsix https://github.com/redhat-developer/vscode-java/releases/download/v1.53.0/java-linux-x64-1.53.0-873.vsix

# Ensure the 'user' can read these files
RUN chmod -R 755 /opt/extensions

# Point to the new paths
ENV DEFAULT_EXTENSIONS=/opt/extensions/redhat-java.vsix;/opt/extensions/mta-core.vsix;/opt/extensions/mta-java.vsix

USER 1000
