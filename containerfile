FROM quay.io/devfile/universal-developer-image:ubi9-latest

USER root

RUN mkdir -p /opt/extensions

RUN curl -L https://github.com/migtools/editor-extensions/releases/download/v8.1.1/mta-core-8.1.1.vsix -o /opt/extensions/mta-core.vsix && \
    curl -L https://github.com/migtools/editor-extensions/releases/download/v8.1.1/mta-java-8.1.1.vsix -o /opt/extensions/mta-java.vsix && \
    curl -L https://github.com/redhat-developer/vscode-java/releases/download/v1.53.0/java-linux-x64-1.53.0-873.vsix -o /opt/extensions/redhat-java.vsix

RUN chmod -R 755 /opt/extensions

ENV VSCODE_EXTENSIONS=/opt/extensions/redhat-java.vsix:/opt/extensions/mta-core.vsix:/opt/extensions/mta-java.vsix

USER 1000
