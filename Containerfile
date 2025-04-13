# Allow build scripts to be referenced without being copied into the final image
FROM scratch AS ctx
COPY build_files /

ARG FEDORA_MAJOR_VERSION="${FEDORA_MAJOR_VERSION:-41}"

# Base Image
FROM ghcr.io/ublue-os/aurora-dx:stable

## Other possible base images include:
# FROM ghcr.io/ublue-os/bazzite:latest
# FROM ghcr.io/ublue-os/bluefin-nvidia:stable
# 
# ... and so on, here are more base images
# Universal Blue Images: https://github.com/orgs/ublue-os/packages
# Fedora base image: quay.io/fedora/fedora-bootc:41
# CentOS base images: quay.io/centos-bootc/centos-bootc:stream10

### MODIFICATIONS
## make modifications desired in your image and install packages by modifying the build.sh script
## the following RUN directive does all the things required to run "build.sh" as recommended.

RUN --mount=type=bind,from=ctx,source=/,target=/ctx \
    --mount=type=cache,dst=/var/cache \
    --mount=type=cache,dst=/var/log \
    --mount=type=tmpfs,dst=/tmp \
    /ctx/build.sh && \
    ostree container commit


# Cosmic
RUN if [[ "${FEDORA_MAJOR_VERSION}" == "rawhide" ]]; then \
        curl -Lo /etc/yum.repos.d/_copr_ryanabx-cosmic.repo \
            https://copr.fedorainfracloud.org/coprs/ryanabx/cosmic-epoch/repo/fedora-rawhide/ryanabx-cosmic-epoch-fedora-rawhide.repo \
    ; else curl -Lo /etc/yum.repos.d/_copr_ryanabx-cosmic.repo \
            https://copr.fedorainfracloud.org/coprs/ryanabx/cosmic-epoch/repo/fedora-$(rpm -E %fedora)/ryanabx-cosmic-epoch-fedora-$(rpm -E %fedora).repo \
    ; fi && \
    rpm-ostree install \
        cosmic-desktop && \
    rpm-ostree install \
        gnome-keyring-pam NetworkManager-tui \
        NetworkManager-openvpn xdg-user-dirs && \
    systemctl disable gdm || true && \
    systemctl disable sddm || true && \
    systemctl enable cosmic-greeter && \
    ostree container commit && \
    mkdir -p /var/tmp && chmod -R 1777 /var/tmp
    
### LINTING
## Verify final image and contents are correct.
RUN bootc container lint
