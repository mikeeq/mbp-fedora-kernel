# mbp-fedora-kernel

Fedora kernel with Apple T2 patches built-in (Macbooks produced >= 2018).

Fedora ISO (with mbp-fedora-kernel builtin) - <https://github.com/mikeeq/mbp-fedora>

Drivers:

- Apple T2 (audio, keyboard, touchpad) - <https://github.com/MCMrARM/mbp2018-bridge-drv>
- Apple SMC - <https://github.com/MCMrARM/mbp2018-etc>
- Touchbar - <https://github.com/roadrunner2/macbook12-spi-driver/tree/mbp15>

## How to update kernel-mbp

```bash
### First run or if you want to update your copy of update_kernel_mbp script
sudo -i
curl -L https://raw.githubusercontent.com/mikeeq/mbp-fedora-kernel/v5.13-f34-mbp16/update_kernel_mbp.sh -o /usr/bin/update_kernel_mbp
chmod +x /usr/bin/update_kernel_mbp
update_kernel_mbp

### Next runs
sudo -i
update_kernel_mbp

### Update to specific version of kernel
# mbp 15,1/15,2
sudo -i
KERNEL_VERSION="v5.13.5-f34-mbp15" update_kernel_mbp

### Update to specific version of kernel using specific version of update script
#### Usually not needed, because scripts are shared between branches, but you can use it to update your update_kernel_mbp script
# mbp 16,1/16,2 (differs in wifi patch)
sudo -i
KERNEL_VERSION="v5.13.5-f34-mbp16" UPDATE_SCRIPT_BRANCH="v5.13-f34-mbp16" update_kernel_mbp
```

## CI status

Drone kernel build status:
[![Build Status](https://cloud.drone.io/api/badges/mikeeq/mbp-fedora-kernel/status.svg)](https://cloud.drone.io/mikeeq/mbp-fedora-kernel)

Travis kernel publish status - <http://fedora-mbp-repo.herokuapp.com/> :
[![Publish Status](https://travis-ci.com/mikeeq/mbp-fedora-kernel.svg?branch=master)](https://travis-ci.com/mikeeq/mbp-fedora-kernel)

## TODO

- integrate `roadrunner2/macbook12-spi-driver` and `MCMrARM/mbp2018-bridge-drv` drivers into kernel
- add `kernel-headers` rpm generation

> Tested on: Macbook Pro 15,2 13" 2019 i5 TouchBar Z0WQ000AR MV972ZE/A/R1 && Macbook Pro 16,2 13" 2020 i5

```
Boot ROM Version:	220.270.99.0.0 (iBridge: 16.16.6571.0.0,0)
macOS Mojave: 10.14.6 (18G103)
```

### Known issues

- Dynamic audio input/output change (on connecting/disconnecting headphones jack)
- TouchID - (@MCMrARM is working on it - https://github.com/Dunedan/mbp-2016-linux/issues/71#issuecomment-528545490)
- Thunderbolt (is disabled, because driver was causing kernel panics (not tested with 5.5 kernel))
- Microphone (it's recognised with new apple t2 sound driver, but there is a low mic volume amp)

#### Working with upstream stable kernel 5.1

- Display/Screen
- USB-C
- Battery/AC
- Ethernet/Video USB-C adapters
- Bluetooth

#### Working with mbp-fedora-kernel

- NVMe
- Camera
- keyboard
- touchpad (scroll, right click)
- wifi (see <https://wiki.t2linux.org/guides/wifi/>)

#### Working with external drivers

>> with @MCMrARM mbp2018-bridge-drv

- keyboard
- touchpad
- touchbar
- audio

#### Not tested

- eGPU
- Thunderbolt

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

## Credits

- @MCMrARM - thanks for all RE work
- @ozbenh - thanks for submitting NVME patch
- @roadrunner2 - thanks for SPI (touchbar) driver
- @aunali1 - thanks for ArchLinux Kernel CI
- @ppaulweber - thanks for keyboard and Macbook Air patches
