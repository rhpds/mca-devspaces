# Use official Dev Spaces base 
FROM quay.io/devfile/universal-developer-image:ubi9-latest

USER root

# Add MTA and Java extensions
RUN mkdir -p /opt/vscode-extensions
# Add MTA and Java extensions
RUN curl -L -o /opt/vscode-extensions/mta-vscode-extension-core.vsix https://github.com/migtools/editor-extensions/releases/download/v8.1.1/mta-core-8.1.1.vsix
RUN curl -L -o /opt/vscode-extensions/mta-vscode-extension-java.vsix https://github.com/migtools/editor-extensions/releases/download/v8.1.1/mta-java-8.1.1.vsix

# Red Hat Java extension
RUN curl -L -o /opt/vscode-extensions/redhat-java-extension-linux-x64.vsix https://github.com/redhat-developer/vscode-java/releases/download/v1.54.0/vscode-java-1.54.0-923.vsix

# Java pack
RUN curl -L -o /opt/vscode-extensions/vscjava.vscode-java-pack-0.30.5.vsix https://open-vsx.org/api/vscjava/vscode-java-pack/0.30.5/file/vscjava.vscode-java-pack-0.30.5.vsix
RUN curl -L -o /opt/vscode-extensions/vscjava.vscode-java-debug-0.59.0.vsix https://open-vsx.org/api/vscjava/vscode-java-debug/0.59.0/file/vscjava.vscode-java-debug-0.59.0.vsix
RUN curl -L -o /opt/vscode-extensions/vscjava.vscode-maven-0.45.3.vsix https://open-vsx.org/api/vscjava/vscode-maven/0.45.3/file/vscjava.vscode-maven-0.45.3.vsix
RUN curl -L -o /opt/vscode-extensions/vscjava.vscode-java-dependency-0.27.2.vsix https://open-vsx.org/api/vscjava/vscode-java-dependency/0.27.2/file/vscjava.vscode-java-dependency-0.27.2.vsix
RUN curl -L -o /opt/vscode-extensions/vscjava.vscode-java-test-0.45.0.vsix https://open-vsx.org/api/vscjava/vscode-java-test/0.45.0/file/vscjava.vscode-java-test-0.45.0.vsix

ENV DEFAULT_EXTENSIONS=/opt/vscode-extensions/redhat-java-extension-linux-x64.vsix;/opt/vscode-extensions/vscjava.vscode-java-pack-0.30.5.vsix;/opt/vscode-extensions/vscjava.vscode-java-debug-0.59.0.vsix;/opt/vscode-extensions/vscjava.vscode-maven-0.45.3.vsix;/opt/vscode-extensions/vscjava.vscode-java-dependency-0.27.2.vsix;/opt/vscode-extensions/vscjava.vscode-java-test-0.45.0.vsix;/opt/vscode-extensions/mta-vscode-extension-core.vsix;/opt/vscode-extensions/mta-vscode-extension-java.vsix

USER user
