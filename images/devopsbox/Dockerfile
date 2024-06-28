# Source and credit for the initial Dockerfile
# https://dev.to/cloudskills/using-containers-for-ansible-development-2n9n


# Architecture ARCH. Eg. amd64, arm64
# https://docs.docker.com/engine/reference/builder/#automatic-platform-args-in-the-global-scope
ARG ARCH=amd64

# See supported Ubuntu version of HashiCorp:
# https://www.hashicorp.com/official-packaging-guide?product_intent=terraform

# https://releases.ubuntu.com/noble/
FROM docker.io/library/ubuntu:noble AS base

# https://github.com/terraform-docs/terraform-docs/releases
ENV TFDOC_VERSION="0.18.0"
# https://github.com/aquasecurity/tfsec/releases
ENV TFSEC_VERSION="1.28.6"
# https://github.com/terraform-linters/tflint/releases
ENV TFLINT_VERSION="0.51.1"
# https://github.com/kubernetes/kubectl
ENV KUBECTL_VERSION="1.30"
# https://github.com/kubernetes-sigs/kustomize
ENV KUSTOMIZE_VERSION="5.4.2"
# https://go.dev/dl/
ENV GOLANG_VERSION="1.22.4"

# Default to UTF-8 file.encoding
ENV LANG="C.UTF-8"
# Set debconf frontend to noninteractive
ENV DEBIAN_FRONTEND="noninteractive"
# OS Paths
ENV KEYRINGS_PATH="/etc/apt/keyrings"
ENV APT_SOURCES_PATH="/etc/apt/sources.list.d"
# Curl config
ENV CURL_RETRIES="--retry 5"

# Because some of the package installs require reloading the shell to fetch the new PATH
# we reference the path here - so that our tests at the bottom can find our packages
ENV PATH="$PATH:/usr/local/go/bin:/home/devops/.local/bin"

FROM base AS amd64
# Download URLs for AMD64 (X86/64)
ENV AWS_CLI_URL="https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip"
ENV GOLANG_URL="https://go.dev/dl/go${GOLANG_VERSION}.linux-amd64.tar.gz"
ENV OPA_URL="https://github.com/open-policy-agent/opa/releases/latest/download/opa_linux_amd64_static"
ENV TFDOC_URL="https://github.com/terraform-docs/terraform-docs/releases/download/v${TFDOC_VERSION}/terraform-docs-v${TFDOC_VERSION}-linux-amd64.tar.gz"
ENV TFLINT_URL="https://github.com/terraform-linters/tflint/releases/download/v${TFLINT_VERSION}/tflint_linux_amd64.zip"
ENV TFSEC_URL="https://github.com/aquasecurity/tfsec/releases/download/v${TFSEC_VERSION}/tfsec_${TFSEC_VERSION}_linux_amd64.tar.gz"
ENV KUSTOMIZE_URL="https://github.com/kubernetes-sigs/kustomize/releases/download/kustomize%2Fv${KUSTOMIZE_VERSION}/kustomize_v${KUSTOMIZE_VERSION}_linux_amd64.tar.gz"

FROM base AS arm64
# Download URLs for ARM64
ENV AWS_CLI_URL="https://awscli.amazonaws.com/awscli-exe-linux-aarch64.zip"
ENV GOLANG_URL="https://go.dev/dl/go${GOLANG_VERSION}.darwin-arm64.tar.gz"
ENV OPA_URL="https://github.com/open-policy-agent/opa/releases/latest/download/opa_linux_arm64_static"
ENV TFDOC_URL="https://github.com/terraform-docs/terraform-docs/releases/download/v${TFDOC_VERSION}/terraform-docs-v${TFDOC_VERSION}-linux-arm64.tar.gz"
ENV TFLINT_URL="https://github.com/terraform-linters/tflint/releases/download/v${TFLINT_VERSION}/tflint_linux_arm64.zip"
ENV TFSEC_URL="https://github.com/aquasecurity/tfsec/releases/download/v${TFSEC_VERSION}/tfsec_${TFSEC_VERSION}_linux_arm64.tar.gz"
ENV KUSTOMIZE_URL="https://github.com/kubernetes-sigs/kustomize/releases/download/kustomize%2Fv${KUSTOMIZE_VERSION}/kustomize_v${KUSTOMIZE_VERSION}_linux_arm64.tar.gz"

FROM ${ARCH} AS tools

# These args need to be defined in the stage that uses them
ARG USERNAME=devops
ARG USER_UID=1001
ARG USER_GID=1001

# Install tools
RUN uname -m && \
	apt-get update -yq && \
	apt-get install -yqq \
	apt-transport-https \
	iproute2 \
	apt-utils \
	build-essential \
	ca-certificates \
	curl \
	dnsutils \
	figlet \
	git \
	gh \
	gnupg \
	gpg \
	jq \
	lsb-release \
	python3-pip \
	pipx \
	shellcheck \
	skopeo \
	sudo \
	software-properties-common \
	tar \
	unzip \
	vim \
	zip && \
# Configure pipx (for isolated python tool environments)
	pipx ensurepath	&& \
# Add Hashicorp repository
	curl -fsSL "https://apt.releases.hashicorp.com/gpg" | gpg --dearmor -o "${KEYRINGS_PATH}/releases-hashicorp.gpg" && \
	echo "deb [signed-by=${KEYRINGS_PATH}/releases-hashicorp.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" | tee -a "${APT_SOURCES_PATH}/releases-hashicorp.list" && \
# Add Helm repository
	curl -fsSL "https://baltocdn.com/helm/signing.asc" | gpg --dearmor -o "${KEYRINGS_PATH}/baltocdn-helm.gpg" && \
	echo "deb [signed-by=${KEYRINGS_PATH}/baltocdn-helm.gpg] https://baltocdn.com/helm/stable/debian/ all main" | tee -a "${APT_SOURCES_PATH}/helm-stable-debian.list" && \
# Add kubernetes repository
    curl -fsSL "https://pkgs.k8s.io/core:/stable:/v${KUBECTL_VERSION}/deb/Release.key" | gpg --dearmor -o "${KEYRINGS_PATH}/kubernetes-apt-keyring.gpg" && \
    echo "deb [signed-by=${KEYRINGS_PATH}/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v${KUBECTL_VERSION}/deb/ /" |  tee ${APT_SOURCES_PATH}/kubernetes.list && \
# Install tools
	apt-get update -yq && \
	apt-get install -yqq \
		terraform \
		packer \
		vault \
		sentinel \
		kubectl \
		helm && \
# Fix "vault: Operation not permitted" error
# https://github.com/hashicorp/vault/issues/10924
	setcap -r "/usr/bin/vault" && \
# AWS CLI (https://github.com/aws/aws-cli)
	echo "AWS CLI URL: '$AWS_CLI_URL'"                        	&& \
	curl -fsSL ${CURL_RETRIES} "$AWS_CLI_URL" -o "awscliv2.zip" && \
	unzip -qq "awscliv2.zip"                                  	&& \
	./aws/install -b "/usr/local/bin" -i "/usr/local/aws-cli" 	&& \
	rm -rf aws*                                               	&& \
    echo "AWS CLI installed"                                  	&& \
	# Go Lang
	echo "GO URL: '$GOLANG_URL'"              					&& \
	curl -fsSL ${CURL_RETRIES} "$GOLANG_URL" -o "golang.tar.gz" && \
	tar -xf "golang.tar.gz" "go"              				&& \
	mv "go" "/usr/local/go"                 				&& \
	echo 'export PATH=\$PATH:/usr/local/go/bin' > /etc/profile.d/02-go-path.sh && \
	export PATH=$PATH:/usr/local/go/bin							&& \
	rm "golang.tar.gz"                                  		&& \
	echo "GoLang installed"                          			&& \
# terraform-docs (https://github.com/terraform-docs/terraform-docs)
	curl -fsSL ${CURL_RETRIES} "$TFDOC_URL" -o "terraform-docs.tar.gz"  && \
	tar -xf "terraform-docs.tar.gz" "terraform-docs"    && \
	mv "terraform-docs" "/usr/bin/terraform-docs"       && \
	rm "terraform-docs.tar.gz"                          && \
    echo "Terraform Docs installed"                     && \
# tfsec (https://github.com/aquasecurity/tfsec)
	curl -fsSL ${CURL_RETRIES} "$TFSEC_URL" -o "tfsec.tar.gz"   && \
	tar -xf "tfsec.tar.gz" "tfsec"              && \
	mv "tfsec" "/usr/bin/tfsec"                 && \
	rm "tfsec.tar.gz"                           && \
    echo "Terraform Sec installed"              && \
# tflint (https://github.com/terraform-linters/tflint)
	curl -fsSL ${CURL_RETRIES} "$TFLINT_URL" -o "tflint.zip" && \
	unzip -qq "tflint.zip"                   && \
	chmod +x "tflint"                        && \
	mv "tflint" "/usr/bin/tflint"            && \
	rm "tflint.zip"                          && \
    echo "Terraform Lint installed"           && \
# kustomize (https://github.com/kubernetes-sigs/kustomize)
    echo "KUSTOMIZE URL: '$KUSTOMIZE_URL'"              && \
    curl -fsSL ${CURL_RETRIES} "$KUSTOMIZE_URL" -o "kustomize.tar.gz"  && \
    tar -xf "kustomize.tar.gz" "kustomize"              && \
    chmod +x "kustomize"                                && \
    mv "kustomize" "/usr/bin/kustomize"                 && \
    rm "kustomize.tar.gz"                                  && \
    echo "Kustomize installed"                          && \
# Open Policy Agent (https://www.openpolicyagent.org/)
	curl -fsSL ${CURL_RETRIES} "$OPA_URL" -o "opa"      && \
	chmod +x "opa"                      && \
	mv "opa" "/usr/bin/opa"             && \
    echo "Open Policy Agent installed"  && \
# Disable Python virtual environments warning
	rm "/usr/lib/python3.12/EXTERNALLY-MANAGED" && \
# Delete caches
	apt-get clean               && \
	rm -rf /var/lib/apt/lists/* && \
	go clean -cache             && \
	go clean -modcache          && \
	go clean -testcache         && \
	go clean -fuzzcache         && \
# Basic smoke test
	aws --version              && \
	bash --version             && \
	curl --version             && \
	dig -v                     && \
	figlet -v                  && \
	git --version              && \
	go version                 && \
	helm version               && \
	kubectl version --client   && \
	kustomize version          && \
	lsb_release -a             && \
	opa version                && \
	openssl version            && \
	packer --version           && \
	perl --version             && \
	pip3 --version             && \
	python3 --version          && \
	sentinel --version         && \
	shellcheck --version       && \
	skopeo -v                  && \
	ssh -V                     && \
	tar --version              && \
	terraform --version        && \
	terraform-docs --version   && \
	tflint --version           && \
	tfsec --version            && \
	sudo -V					   && \
	unzip -v                   && \
	vault --version            && \
	zip -v					   && \
	# Create user for access
	groupadd --gid "${USER_GID}" "${USERNAME}" && \
    useradd --uid "${USER_UID}" --gid "${USER_GID}" --shell "/bin/bash" -m "${USERNAME}" && \
    echo "${USERNAME}" ALL=\(root\) NOPASSWD:ALL > "/etc/sudoers.d/${USERNAME}" && \
    chmod 0440 "/etc/sudoers.d/${USERNAME}"

# https://code.visualstudio.com/remote/advancedcontainers/add-nonroot-user
USER $USERNAME

# Install pip packages
RUN pipx install ansible-dev-tools \
	ansible-core \
	ansible-lint && \
	pip3 cache purge            && \
	# smoke test pip installed tools
	ansible --version          && \
	ansible-playbook --version && \
	ansible-lint --version