# mbp-fedora-kernel

Fedora kernel with Apple T2 patches built-in (Macbooks produced >= 2018).

Fedora ISO (with mbp-fedora-kernel builtin): <https://github.com/mikeeq/mbp-fedora>

Kernel patches: <https://github.com/AdityaGarg8/linux-t2-patches>

> Tested on: Macbook Pro 15,2 13" 2019 i5 TouchBar Z0WQ000AR MV972ZE/A/R1 && Macbook Pro 16,2 13" 2020 i5

```
Boot ROM Version:	220.270.99.0.0 (iBridge: 16.16.6571.0.0,0)
macOS Mojave: 10.14.6 (18G103)
```

## How to update kernel-mbp

```bash
### First run or if you want to update your copy of update_kernel_mbp script
sudo -i
curl -L https://raw.githubusercontent.com/mikeeq/mbp-fedora-kernel/v6.0-f36/update_kernel_mbp.sh -o /usr/bin/update_kernel_mbp
chmod +x /usr/bin/update_kernel_mbp
update_kernel_mbp

### Next runs
sudo -i
update_kernel_mbp

### Update to specific version of kernel
sudo -i
KERNEL_VERSION="6.0.5-f36" update_kernel_mbp

### Update to specific version of kernel using specific version of update script
#### Usually not needed, because scripts are shared between branches, but you can use it to update your update_kernel_mbp script
##### If the script fails, try to rerun it - it's due to self-upgrading feature of this script
sudo -i
KERNEL_VERSION="6.0.5-f36" UPDATE_SCRIPT_BRANCH="v6.0-f36" update_kernel_mbp
```

## CI status

GitHub Actions kernel build status:
[![Build Status](https://github.com/mikeeq/mbp-fedora-kernel/actions/workflows/build-kernel.yml/badge.svg)](https://github.com/mikeeq/mbp-fedora-kernel/actions/workflows/build-kernel.yml)

Github Actions kernel publish status - <https://fedora-mbp-repo.herokuapp.com/> :
[![Publish Status](https://github.com/mikeeq/mbp-fedora-kernel/actions/workflows/yum-repo.yml/badge.svg)](https://github.com/mikeeq/mbp-fedora-kernel/actions/workflows/yum-repo.yml)

### Known issues

- TouchID - (@MCMrARM is working on it - https://github.com/Dunedan/mbp-2016-linux/issues/71#issuecomment-528545490)
- Audio
  - Microphone (it's recognized with new apple t2 sound driver, but there is a low mic volume amp)

#### Working with upstream stable kernel 6.0

- Display/Screen
- USB-C
- Battery/AC
- Ethernet/Video USB-C adapters
- Bluetooth
- NVMe
- Camera

#### Working with mbp-fedora-kernel

- with builtin BCE driver
  - Audio
  - Keyboard
  - Touchpad (scroll, right click)
- with builtin iBridge driver
  - MacBook Pro Touch Bar
    - If there's an issue with Touch Bar startup on Linux I recommend to install Win10 and boot it once a while to initialize Touch Bar using BootCamp driver, it seems to fix the issue
- WiFi
  - to make it working, you need to grab closed source Broadcom WiFi firmware from MacOS and put it under `/lib/firmware/brcm/` in Linux OS, see <https://wiki.t2linux.org/guides/wifi/>

#### Not tested

- eGPU
- Thunderbolt

## How to build mbp-fedora-kernel

1. Make sure that Docker is installed and running correctly on your machine
2. Clone repo
3. Generate GPG key: `gpg --full-generate-key`, choose `RSA and RSA` and `Real name: mbp-fedora`
4. Change version in `build.sh`, <https://bodhi.fedoraproject.org/updates/?search=&packages=kernel>
5. Run `./build_in_docker.sh`

## Docs

- Discord: <https://discord.gg/Uw56rqW>
- WiFi firmware: <https://packages.aunali1.com/apple/wifi-fw/18G2022>
- blog `Installing Fedora 31 on a 2018 Mac mini`: <https://linuxwit.ch/blog/2020/01/installing-fedora-on-mac-mini/>
- iwd:
  - <https://iwd.wiki.kernel.org/networkconfigurationsettings>
  - <https://wiki.archlinux.org/index.php/Iwd>
  - <https://www.vocal.com/secure-communication/eap-types/>

### Fedora

- <https://fedoraproject.org/wiki/Building_a_custom_kernel>
- <https://fedoramagazine.org/building-fedora-kernel/>
- <https://www.hiroom2.com/2016/06/25/fedora-24-rebuild-kernel-with-src-rpm/>

### Github

- GitHub issue (RE history): <https://github.com/Dunedan/mbp-2016-linux/issues/71>
- VHCI+Sound driver (Apple T2): <https://github.com/MCMrARM/mbp2018-bridge-drv/>
- AppleSMC driver (fan control): <https://github.com/MCMrARM/mbp2018-etc/tree/master/applesmc>
- hid-apple keyboard backlight patch: <https://github.com/MCMrARM/mbp2018-etc/tree/master/apple-hid>
- TouchBar driver: <https://github.com/roadrunner2/macbook12-spi-driver/tree/mbp15>
- Kernel patches (all are mentioned in github issue above): <https://github.com/aunali1/linux-mbp-arch>
- ArchLinux kernel patches: <https://github.com/ppaulweber/linux-mba>
- hid-apple-patched module for changing mappings of ctrl, fn, option keys: <https://github.com/free5lot/hid-apple-patched>
- AdityaGarg8 kernel patches: <https://github.com/AdityaGarg8/linux-t2-patches>

## Credits

- @MCMrARM - thanks for all RE work
- @ozbenh - thanks for submitting NVME patch
- @roadrunner2 - thanks for SPI (touchbar) driver
- @aunali1 - thanks for ArchLinux Kernel CI
- @ppaulweber - thanks for keyboard and Macbook Air patches
- @AdityaGarg8 - thanks for support and upkeeping kernel patches
