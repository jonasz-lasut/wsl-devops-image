FROM fedora:41

ARG user=judasz

# Install required linux packages and create user
RUN dnf update -y && \
    dnf install -y bash-completion dnf-plugins-core systemctl util-linux && \ 
    useradd -m $user

# Add all required permissions for the user
RUN usermod -a -G wheel $user && \
    echo "$user ALL=(ALL:ALL) NOPASSWD: ALL" > /etc/sudoers.d/$user

# Add WSL configuration
RUN <<EOF cat > /etc/wsl.conf
[boot]
systemd=true
EOF

# Install docker
RUN dnf-3 config-manager --add-repo https://download.docker.com/linux/fedora/docker-ce.repo && \
    dnf install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

###
# USER configuration
###
USER $user
WORKDIR /home/$user

# Install Rust toolchain
RUN curl https://sh.rustup.rs -sSf | bash -s -- -y
ENV PATH="/root/.cargo/bin:${PATH}"
RUN echo 'source $HOME/.cargo/env' >> $HOME/.bashrc

# Install single-user nix and devbox
RUN sh <(curl -L https://nixos.org/nix/install) --no-daemon --yes && \
    . $HOME/.nix-profile/etc/profile.d/nix.sh

ENV PATH="/home/$user/.nix-profile/bin:${PATH}"
ENV NIX_SSL_CERT_FILE="/etc/ssl/certs/ca-bundle.crt"

RUN bash <(curl -fsSL https://get.jetify.com/devbox) -f && \
    echo "eval \"\$(devbox global shellenv)\"" >> $HOME/.bashrc

# Install global devbox packages
RUN devbox global add \
	atuin \
	bat \
        crossplane-cli \
	exa \
	go \
	jq \
	kcl-cli \
	kind \
	kubectl \
	kubernetes-helm \
	kyverno-chainsaw \
        tenv \
	tig \
	upbound \
	vim \
	yq-go

# Refresh global env
RUN eval "$(devbox global shellenv --preserve-path-stack -r)" && hash -r

# Generate bash completions and aliases
RUN echo "source /etc/profile.d/bash_completion.sh" >> $HOME/.bashrc && \
    echo "source <(kubectl completion bash)" >> $HOME/.bashrc \
    echo "alias k='kubectl'" >> $HOME/.bashrc \
    echo "complete -F __start_kubectl k" >> $HOME/.bashrc \
    echo "source <(chainsaw completion bash)" >> $HOME/.bashrc \
    echo "source <(helm completion bash)" >> $HOME/.bashrc \
    echo "source <(tenv completion bash)" >> $HOME/.bashrc \
    echo "source <(kind completion bash)" >> $HOME/.bashrc \
    echo "source <(atuin completion bash)" >> $HOME/.bashrc \
    echo "alias l='exa --git -l --octal-permissions -F'" >> $HOME/.bashrc
