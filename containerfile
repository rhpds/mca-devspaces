# Use official Dev Spaces base 
FROM quay.io/devfile/universal-developer-image:ubi9-latest

USER root

# Avoid flaky mirrors, timeouts, or zchunk checksum mismatches
RUN echo "fastestmirror=True" >> /etc/dnf/dnf.conf && \
    echo "skip_if_unavailable=True" >> /etc/dnf/dnf.conf && \
    echo "zchunk=False" >> /etc/dnf/dnf.conf

# Install dependencies required by Developer Ligthspeed for MTA + typical tools
RUN dnf clean all && \
    dnf install -y --nobest --allowerasing \
        python3.11 python3.11-devel \
        java-17-openjdk-devel \
        nodejs maven \
        unzip git curl zsh \
        gcc make glibc-devel libffi-devel openssl-devel \
    && dnf clean all

# Add MTA and Java extensions
RUN curl -L -o /mta-vscode-extension-core.vsix https://github.com/migtools/editor-extensions/releases/download/v8.1.1/mta-core-8.1.1.vsix
RUN curl -L -o /mta-vscode-extension-java.vsix https://github.com/migtools/editor-extensions/releases/download/v8.1.1/mta-java-8.1.1.vsix
RUN curl -L -o /redhat-java-extension-linux-x64.vsix https://github.com/redhat-developer/vscode-java/releases/download/v1.53.0/java-linux-x64-1.53.0-873.vsix

ENV DEFAULT_EXTENSIONS=/redhat-java-extension-linux-x64.vsix;/mta-vscode-extension-core.vsix;/mta-vscode-extension-java.vsix

USER user
