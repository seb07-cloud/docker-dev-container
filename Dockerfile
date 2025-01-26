# A Dockerfile based on Debian 10 for dev purposes, installed with the following: 

# CLI:      Azure CLI, PowerShell Core, Azure PowerShell, 
# Tools:    Azure Functions Core Tools, SSH Client, Azure Dev Spaces CLI, Git, Azure CLI Extensions
# IAC:      Azure Bicep, Terraform, Terraform Tools
# DEV:      Golang Tools, Python
# Github:   Github CLI, Github CLI Configuration, Git Configuration, SSH Client Configuration, Azure CLI Configuration

# Create a User Account <vscode>

# Github Username and Personal Access Token (PAT) are passed in as build arguments from Environment Variables
# Create a .env file in the .devcontainer folder with the following content:
# GITHUB_USERNAME=<your github username>
# GITHUB_PAT=<your github personal access token>
# GITHUB_EMAIL=<your github email>

# Build the container with the following command:
# docker build --build-arg GITHUB_USERNAME=<your github username> --build-arg GITHUB_PAT=<your github personal access token> --build-arg GITHUB_EMAIL=<your github email> -t <your container name> .

# Run the container with the following command:
# docker run -it <your container name>

# Run the container with the following command and mount the current directory to the container:
# docker run -it -v ${PWD}:/workspaces/<your workspace name> <your container name>

# docker build -t devcontainer -f .devcontainer/Dockerfile .

FROM debian:bullseye-slim

# [Option] Install zsh
ARG INSTALL_ZSH="true"
# [Option] Upgrade OS packages to their latest versions
ARG UPGRADE_PACKAGES="false"

# Install needed packages and setup non-root user. Use a separate RUN statement to add your own dependencies.
ARG USERNAME=vscode
ARG USER_UID=1000
ARG USER_GID=$USER_UID

# Copy all shell scripts to /tmp/library-scripts
COPY .devcontainer/library-scripts/*.sh /tmp/library-scripts/

# Install dos2unix and prepare shell scripts
RUN apt-get update && apt-get install -y dos2unix && \
    dos2unix /tmp/library-scripts/*.sh && \
    chmod +x /tmp/library-scripts/*.sh && \
    for script in /tmp/library-scripts/*.sh; do \
        echo "Running $script..."; \
        $script; \
    done && \
    rm -rf /var/lib/apt/lists/*


RUN bash /tmp/library-scripts/common-debian.sh "${INSTALL_ZSH}" "${USERNAME}" "${USER_UID}" "${USER_GID}" "${UPGRADE_PACKAGES}" "true" "true" \
    # Install the Azure CLI
    && bash /tmp/library-scripts/azcli-debian.sh \
    # Clean up
    && apt-get clean -y && rm -rf /var/lib/apt/lists/* /tmp/library-scripts
    
# Install Azure CLI
RUN curl -sL https://aka.ms/InstallAzureCLIDeb | bash

# Install Azure Bicep
RUN curl -Lo bicep https://github.com/Azure/bicep/releases/latest/download/bicep-linux-x64
RUN chmod +x ./bicep
RUN mv ./bicep /usr/local/bin/bicep

# Install PowerShell Core
RUN curl -sSL https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor > microsoft.gpg \
    && mv microsoft.gpg /etc/apt/trusted.gpg.d/microsoft.gpg \
    && sh -c 'echo "deb [arch=amd64] https://packages.microsoft.com/repos/microsoft-debian-buster-prod buster main" > /etc/apt/sources.list.d/microsoft.list' \
    && apt-get update \
    && apt-get install -y powershell

# Install Azure PowerShell
RUN pwsh -Command "Install-Module -Name Az -AllowClobber -Scope AllUsers -Force"

## Add the 1Password CLI official GPG key and install the CLI
RUN curl -sS https://downloads.1password.com/linux/keys/1password.asc | \
    sudo gpg --dearmor --output /usr/share/keyrings/1password-archive-keyring.gpg && \
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/1password-archive-keyring.gpg] https://downloads.1password.com/linux/debian/$(dpkg --print-architecture) stable main" | \
    sudo tee /etc/apt/sources.list.d/1password.list && \
    sudo mkdir -p /etc/debsig/policies/AC2D62742012EA22/ && \
    curl -sS https://downloads.1password.com/linux/debian/debsig/1password.pol | \
    sudo tee /etc/debsig/policies/AC2D62742012EA22/1password.pol && \
    sudo mkdir -p /usr/share/debsig/keyrings/AC2D62742012EA22 && \
    curl -sS https://downloads.1password.com/linux/keys/1password.asc | \
    sudo gpg --dearmor --output /usr/share/debsig/keyrings/AC2D62742012EA22/debsig.gpg && \
    sudo apt update && sudo apt install 1password-cli

# Install Terraform
RUN wget -O- https://apt.releases.hashicorp.com/gpg | gpg --dearmor | tee /usr/share/keyrings/hashicorp-archive-keyring.gpg
RUN echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] \
    https://apt.releases.hashicorp.com $(lsb_release -cs) main" | \
    sudo tee /etc/apt/sources.list.d/hashicorp.list
RUN apt-get update && apt-get install terraform

# Install Terraform Tools
RUN curl -sL https://raw.githubusercontent.com/terraform-linters/tflint/master/install_linux.sh | bash

# Install Go and set path to /usr/local/go/bin/go
RUN curl -sL https://golang.org/dl/go1.16.3.linux-amd64.tar.gz | tar -C /usr/local -xz

# Install Terragrunt
RUN curl -fsSL -o /usr/local/bin/terragrunt https://github.com/gruntwork-io/terragrunt/releases/latest/download/terragrunt_linux_amd64 \
    && chmod +x /usr/local/bin/terragrunt

# Install Go Tools
RUN curl -sSfL https://raw.githubusercontent.com/golangci/golangci-lint/master/install.sh | sh -s -- -b $(go env GOPATH)/bin v1.50.1

# Install Git
RUN apt-get update && export DEBIAN_FRONTEND=noninteractive \
    && apt-get -y install --no-install-recommends git

# Install Python
RUN apt-get update && export DEBIAN_FRONTEND=noninteractive \
    && apt-get -y install --no-install-recommends python3 python3-pip

# Install Python Tools
RUN pip3 install --upgrade pip
RUN pip3 install --upgrade setuptools
RUN pip3 install --upgrade wheel
RUN pip3 install --upgrade pylint
RUN pip3 install --upgrade pytest
RUN pip3 install --upgrade pytest-cov

# Install SSH Client
RUN apt-get update && export DEBIAN_FRONTEND=noninteractive \
    && apt-get -y install --no-install-recommends openssh-client

# Install Azure CLI Extensions
RUN az extension add --name azure-devops
RUN az extension add --name azure-firewall

# Install Github CLI
RUN sudo curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg | dd of=/usr/share/keyrings/githubcli-archive-keyring.gpg \
    && chmod go+r /usr/share/keyrings/githubcli-archive-keyring.gpg \
    && echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" | tee /etc/apt/sources.list.d/github-cli.list > /dev/null \
    && apt update \
    && apt install gh -y

# Configure Github CLI
RUN gh config set prompt disabled
RUN gh config set git_protocol ssh
RUN gh config set editor code

# Configure Git with Github Username and Personal Access Token (PAT)
RUN git config --global user.name "$GITHUB_USERNAME"
RUN git config --global user.email "$GITHUB_EMAIL"
RUN git config --global url."https://${GITHUB_USERNAME}:${GH_TOKEN}}@github.com".insteadOf "https://github.com"
RUN git config --global credential.helper store

# Configure SSH Client
RUN mkdir -p /root/.ssh
RUN ssh-keyscan -t rsa github.com >> /root/.ssh/known_hosts

# Clean up
RUN apt-get autoremove -y && apt-get clean -y
RUN apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*
