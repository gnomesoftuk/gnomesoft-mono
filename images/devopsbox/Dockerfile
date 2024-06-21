# Architecture component of TARGETPLATFORM. Eg. amd64, arm64
# https://docs.docker.com/engine/reference/builder/#automatic-platform-args-in-the-global-scope
ARG TARGETARCH

# See supported Ubuntu version of HashiCorp:
# https://www.hashicorp.com/official-packaging-guide?product_intent=terraform
# The ubuntu:noble tag points to the 24.04 release
# https://releases.ubuntu.com/noble/
FROM docker.io/library/ubuntu:oracular AS base

# https://github.com/terraform-docs/terraform-docs/releases
ENV TFDOC_VERSION="0.18.0"
# https://github.com/aquasecurity/tfsec/releases
ENV TFSEC_VERSION="1.28.6"
# https://github.com/terraform-linters/tflint/releases
ENV TFLINT_VERSION="0.51.1"
# Default to UTF-8 file.encoding
ENV LANG="C.UTF-8"
# Set debconf frontend to noninteractive
ENV DEBIAN_FRONTEND="noninteractive"

FROM base AS amd64
# Download URLs for AMD64 (X86/64)
ENV AWS_CLI_URL="https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip"
ENV OPA_URL="https://github.com/open-policy-agent/opa/releases/latest/download/opa_linux_amd64_static"
ENV TFDOC_URL="https://github.com/terraform-docs/terraform-docs/releases/download/v${TFDOC_VERSION}/terraform-docs-v${TFDOC_VERSION}-linux-amd64.tar.gz"
ENV TFLINT_URL="https://github.com/terraform-linters/tflint/releases/download/v${TFLINT_VERSION}/tflint_linux_amd64.zip"
ENV TFSEC_URL="https://github.com/aquasecurity/tfsec/releases/download/v${TFSEC_VERSION}/tfsec_${TFSEC_VERSION}_linux_amd64.tar.gz"
ENV KUSTOMIZE_URL="https://raw.githubusercontent.com/kubernetes-sigs/kustomize/master/hack/install_kustomize.sh""

FROM base AS arm64
# Download URLs for ARM64
ENV AWS_CLI_URL="https://awscli.amazonaws.com/awscli-exe-linux-aarch64.zip"
ENV OPA_URL="https://github.com/open-policy-agent/opa/releases/latest/download/opa_linux_arm64_static"
ENV TFDOC_URL="https://github.com/terraform-docs/terraform-docs/releases/download/v${TFDOC_VERSION}/terraform-docs-v${TFDOC_VERSION}-linux-arm64.tar.gz"
ENV TFLINT_URL="https://github.com/terraform-linters/tflint/releases/download/v${TFLINT_VERSION}/tflint_linux_arm64.zip"
ENV TFSEC_URL="https://github.com/aquasecurity/tfsec/releases/download/v${TFSEC_VERSION}/tfsec_${TFSEC_VERSION}_linux_arm64.tar.gz"
ENV KUSTOMIZE_URL="https://raw.githubusercontent.com/kubernetes-sigs/kustomize/master/hack/install_kustomize.sh""

FROM ${TARGETARCH} AS tools
# Install tools
RUN uname -m && \
	    apt-get update -yq && \
	    apt-get install -yqq \
		apt-transport-https \
		apt-utils \
		build-essential \
		ca-certificates \
		cpanminus \
		curl \
		dnsutils \
		figlet \
		git \
		golang-go \
		gpg \
		jq \
		lsb-release \
		mutt \
		python3-pip \
		shellcheck \
		skopeo \
		software-properties-common \
		tar \
		unzip \
		zip && \
# Add Hashicorp repository
	curl -fsSL "https://apt.releases.hashicorp.com/gpg" | gpg --dearmor -o "/usr/share/keyrings/releases-hashicorp.gpg" && \
	echo "deb [signed-by=/usr/share/keyrings/releases-hashicorp.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" | tee -a "/etc/apt/sources.list.d/releases-hashicorp.list" && \
# Add Ansible PPA repository
	add-apt-repository "ppa:ansible/ansible" && \
# Add Helm repository
	curl -fsSL "https://baltocdn.com/helm/signing.asc" | gpg --dearmor -o "/usr/share/keyrings/baltocdn-helm.gpg" && \
	echo "deb [signed-by=/usr/share/keyrings/baltocdn-helm.gpg] https://baltocdn.com/helm/stable/debian/ all main" | tee -a "/etc/apt/sources.list.d/helm-stable-debian.list" && \
# Install tools
	apt-get update -yq && \
	apt-get install -yqq \
		terraform \
		packer \
		vault \
		sentinel \
		ansible \
		kubectl \
		helm && \
# Fix "vault: Operation not permitted" error
# https://github.com/hashicorp/vault/issues/10924
	setcap -r "/usr/bin/vault" && \
# AWS CLI (https://github.com/aws/aws-cli)
	echo "AWS CLI URL: '$AWS_CLI_URL'"                        && \
	curl -L "$AWS_CLI_URL" -o "awscliv2.zip"                  && \
	unzip -qq "awscliv2.zip"                                  && \
	./aws/install -b "/usr/local/bin" -i "/usr/local/aws-cli" && \
	rm -rf aws*                                               && \
# terraform-docs (https://github.com/terraform-docs/terraform-docs)
	curl -L "$TFDOC_URL" -o "terraform-docs.tar.gz"   && \
	tar -xf "terraform-docs.tar.gz" "terraform-docs"  && \
	mv "terraform-docs" "/usr/bin/terraform-docs"     && \
	rm "terraform-docs.tar.gz"                        && \
# tfsec (https://github.com/aquasecurity/tfsec)
	curl -L "$TFSEC_URL" -o "tfsec.tar.gz" && \
	tar -xf "tfsec.tar.gz" "tfsec"         && \
	mv "tfsec" "/usr/bin/tfsec"            && \
	rm "tfsec.tar.gz"                      && \
# tflint (https://github.com/terraform-linters/tflint)
	curl -L "$TFLINT_URL" -o "tflint.zip" && \
	unzip -qq "tflint.zip"                && \
	chmod +x "tflint"                     && \
	mv "tflint" "/usr/bin/tflint"         && \
	rm "tflint.zip"                       && \
# kustomize (https://github.com/kubernetes-sigs/kustomize)
    curl -L "$KUSTOMIZE_URL" -o "kustomize.zip" && \
    chmod +x kustomize.sh                       && \
    ./kustomize.sh                              && \
    rm "kustomize.sh"                           && \
# Open Policy Agent (https://www.openpolicyagent.org/)
	curl -L "$OPA_URL" -o "opa" && \
	chmod +x "opa"              && \
	mv "opa" "/usr/bin/opa"     && \               && \
# Delete caches
	apt-get clean               && \
	rm -rf /var/lib/apt/lists/* && \
	pip3 cache purge            && \
	go clean -cache             && \
	go clean -modcache          && \
	go clean -testcache         && \
	go clean -fuzzcache         && \
# Disable Python virtual environments warning
	rm "/usr/lib/python3.12/EXTERNALLY-MANAGED" && \
# Basic smoke test
	ansible --version          && \
	ansible-playbook --version && \
	aws --version              && \
	bash --version             && \
	cpanm --version            && \
	curl --version             && \
	dig -v                     && \
	figlet -v                  && \
	git --version              && \
	go version                 && \
	helm version               && \
	kubectl help               && \
    kubectl version --short --client && \
	lsb_release -a             && \
	mutt -v                    && \
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
	unzip -v                   && \
	vault --version            && \
	zip -v

# If you're reading this and have any feedback on how this image could be
# improved, please open an issue or a pull request so we can discuss it!
#
#   https://github.com/Cyclenerd/cloud-tools-container