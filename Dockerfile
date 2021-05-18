FROM fedora:34

ARG FEDORA_KERNEL_GIT_URL=https://src.fedoraproject.org/rpms/kernel.git
ARG FEDORA_KERNEL_VERSION=5.11.21
ARG FEDORA_KERNEL_BRANCH_NAME=f34
ARG FEDORA_KERNEL_COMMIT_HASH=8b43a43382cabcf6d64266565ccc052c6e5d58a6      # https://src.fedoraproject.org/rpms/kernel/commits/f34

RUN dnf install -y fedpkg fedora-packager rpmdevtools ncurses-devel pesign git libkcapi libkcapi-devel libkcapi-static libkcapi-tools zip curl

RUN git clone --single-branch --branch $FEDORA_KERNEL_BRANCH_NAME ${FEDORA_KERNEL_GIT_URL} \
    && cd kernel \
    && git checkout $FEDORA_KERNEL_COMMIT_HASH \
    && git reset --hard $FEDORA_KERNEL_COMMIT_HASH \
    && git checkout -b fedora_patch_src \
    && dnf -y builddep kernel.spec
