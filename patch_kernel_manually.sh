#!/bin/sh

### Apple T2 drivers commit hashes
KERNEL_VERSION=5.4.8-200.mbp.fc31.x86_64
KERNEL_PATCH_PATH=/tmp/kernel_patch


BCE_DRIVER_GIT_URL=https://github.com/MCMrARM/mbp2018-bridge-drv.git
BCE_DRIVER_BRANCH_NAME=master
BCE_DRIVER_COMMIT_HASH=7330e638b9a32b4ae9ea97857f33838b5613cad3
APPLE_IB_DRIVER_GIT_URL=https://github.com/roadrunner2/macbook12-spi-driver.git
APPLE_IB_DRIVER_BRANCH_NAME=mbp15
APPLE_IB_DRIVER_COMMIT_HASH=90cea3e8e32db60147df8d39836bd1d2a5161871
APPLE_SMC_DRIVER_GIT_URL=https://github.com/MCMrARM/mbp2018-etc
APPLE_SMC_DRIVER_BRANCH_NAME=master
APPLE_SMC_DRIVER_COMMIT_HASH=cf42289ad637d3073e2fd348af71ad43dd31b8b4

rpm -i ./*.rpm

mkdir -p ${KERNEL_PATCH_PATH}
cd ${KERNEL_PATCH_PATH}

### bce
git clone --depth 1 --single-branch --branch ${BCE_DRIVER_BRANCH_NAME} ${BCE_DRIVER_GIT_URL} ./bce
cd bce
git checkout ${BCE_DRIVER_COMMIT_HASH}

make -C /lib/modules/${KERNEL_VERSION}/build/ M=$(pwd) modules
cp -rfv ./bce.ko /lib/modules/${KERNEL_VERSION}/extra
cd ..

git clone --single-branch --branch ${APPLE_IB_DRIVER_BRANCH_NAME} ${APPLE_IB_DRIVER_GIT_URL} ./touchbar
cd touchbar
git checkout ${APPLE_IB_DRIVER_COMMIT_HASH}

make -C /lib/modules/${KERNEL_VERSION}/build/ M=$(pwd) modules
cp -rfv ./*.ko /lib/modules/${KERNEL_VERSION}/extra

depmod -a ${KERNEL_VERSION}
dracut -f /boot/initramfs-$KERNEL_VERSION.img $KERNEL_VERSION

rm -rf ${KERNEL_PATCH_PATH}
