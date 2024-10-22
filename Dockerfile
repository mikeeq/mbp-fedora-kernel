FROM fedora:40

ARG RPMBUILD_PATH=/root/rpmbuild
ARG FEDORA_KERNEL_VERSION=6.11.3-200.fc40      # https://bodhi.fedoraproject.org/updates/?search=&packages=kernel&releases=f40

RUN dnf install -y fedpkg fedora-packager rpmdevtools ncurses-devel pesign git libkcapi libkcapi-devel libkcapi-static libkcapi-tools zip curl dwarves libbpf rpm-sign \
    && rpmdev-setuptree \
    && cd ${RPMBUILD_PATH}/SOURCES \
    && koji download-build --arch=src kernel-${FEDORA_KERNEL_VERSION} \
    && rpm -Uvh kernel-${FEDORA_KERNEL_VERSION}.src.rpm \
    && cd ${RPMBUILD_PATH}/SPECS \
    && dnf -y builddep kernel.spec
