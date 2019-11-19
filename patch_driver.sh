#!/bin/sh

### Apple T2 drivers commit hashes
BCE_DRIVER_BRANCH_NAME=master
BCE_DRIVER_COMMIT_HASH=488a4fe0c467bc0aaf5d74102df2f0e1c31dfad6
APPLE_IB_DRIVER_BRANCH_NAME=mbp15
APPLE_IB_DRIVER_COMMIT_HASH=90cea3e8e32db60147df8d39836bd1d2a5161871

REPO_PWD=$(pwd)
echo -e "From: fedora kernel <fedora@kernel.org>\nSubject: patch custom drivers\n" > ../patches/custom-drivers.patch

mkdir -p /root/temp
cd /root/temp
git clone --depth 1 --single-branch --branch v${FEDORA_KERNEL_VERSION} git://git.kernel.org/pub/scm/linux/kernel/git/stable/linux-stable.git
cd ./linux-stable/drivers

### bce
git clone --depth 1 --single-branch --branch ${BCE_DRIVER_BRANCH_NAME} https://github.com/MCMrARM/mbp2018-bridge-drv.git ./bce
cd bce
git checkout ${BCE_DRIVER_COMMIT_HASH}
rm -rf .git
cd ..
cp -rfv ${REPO_PWD}/../templates/Kconfig bce/Kconfig
sed -i "s/TEST_DRIVER/BCE_DRIVER/g" bce/Kconfig

### apple-ib
git clone --single-branch --branch ${APPLE_IB_DRIVER_BRANCH_NAME} https://github.com/roadrunner2/macbook12-spi-driver.git touchbar
cd touchbar
git checkout ${APPLE_IB_DRIVER_COMMIT_HASH}
rm -rf .git
cd ..
cp -rfv ${REPO_PWD}/../templates/Kconfig touchbar/Kconfig
sed -i "s/TEST_DRIVER/TOUCHBAR_DRIVER/g" touchbar/Kconfig

echo 'obj-$(CONFIG_BCE)           += bce/' >> ./Makefile
echo 'obj-$(CONFIG_TOUCHBAR)           += touchbar/' >> ./Makefile
sed -i "\$i source \"drivers/bce/Kconfig\"\n" Kconfig
sed -i "\$i source \"drivers/touchbar/Kconfig\"\n" Kconfig

git add .
git diff HEAD >> ${REPO_PWD}/../patches/custom-drivers.patch

### back to fedora kernel repo
cd $REPO_PWD
for config_file in $(ls | grep kernel | grep '.config')
do
  echo 'CONFIG_BCE_DRIVER=y' >> $config_file
  echo 'CONFIG_TOUCHBAR_DRIVER=y' >> $config_file
done
