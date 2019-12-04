#!/bin/sh

### Apple T2 drivers commit hashes
BCE_DRIVER_BRANCH_NAME=master
BCE_DRIVER_COMMIT_HASH=7330e638b9a32b4ae9ea97857f33838b5613cad3
APPLE_IB_DRIVER_BRANCH_NAME=mbp15
APPLE_IB_DRIVER_COMMIT_HASH=90cea3e8e32db60147df8d39836bd1d2a5161871
APPLE_SMC_DRIVER_BRANCH_NAME=master
APPLE_SMC_DRIVER_COMMIT_HASH=cf42289ad637d3073e2fd348af71ad43dd31b8b4

REPO_PWD=$(pwd)
echo -e "From: fedora kernel <fedora@kernel.org>\nSubject: patch custom drivers\n" > ../patches/custom-drivers.patch

mkdir -p /root/temp
cd /root/temp

git clone --single-branch --branch ${APPLE_SMC_DRIVER_BRANCH_NAME} https://github.com/MCMrARM/mbp2018-etc
cp -rfv mbp2018-etc/applesmc/patches/* ${REPO_PWD}/../patches/

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
sed -i 's/obj-m/obj-$(CONFIG_BCE)/g' bce/Makefile

### apple-ib
git clone --single-branch --branch ${APPLE_IB_DRIVER_BRANCH_NAME} https://github.com/roadrunner2/macbook12-spi-driver.git touchbar
cd touchbar
git checkout ${APPLE_IB_DRIVER_COMMIT_HASH}
rm -rf .git
cd ..
cp -rfv ${REPO_PWD}/../templates/Kconfig touchbar/Kconfig
sed -i "s/TEST_DRIVER/TOUCHBAR_DRIVER/g" touchbar/Kconfig
sed -i 's/obj-m/obj-$(CONFIG_TOUCHBAR)/g' touchbar/Makefile

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
  echo 'CONFIG_BCE_DRIVER=m' >> $config_file
  echo 'CONFIG_TOUCHBAR_DRIVER=m' >> $config_file
done

echo 'CONFIG_BCE_DRIVER=m' > configs/fedora/generic/CONFIG_BCE_DRIVER
echo 'CONFIG_TOUCHBAR_DRIVER=m' >> configs/fedora/generic/CONFIG_TOUCHBAR_DRIVER

echo -e "bce.ko\napple-ib-als.ko\napple-ib-tb.ko\napple-ibridge.ko" >> mod-extra.list

echo 'inputdrvs="gameport tablet touchscreen bce touchbar"' >> filter-x86_64.sh
