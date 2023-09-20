# mbp-fedora-kernel

Fedora kernel with Apple T2 patches built-in (Macbooks produced >= 2018).

Fedora ISO (with mbp-fedora-kernel builtin): <https://github.com/mikeeq/mbp-fedora>

Kernel patches: <https://github.com/t2linux/linux-t2-patches>

> Tested on: Macbook Pro 15,2 13" 2019 i5 TouchBar Z0WQ000AR MV972ZE/A/R1 && Macbook Pro 16,2 13" 2020 i5

```
Boot ROM Version:	220.270.99.0.0 (iBridge: 16.16.6571.0.0,0)
macOS Mojave: 10.14.6 (18G103)
```

## CI status

GitHub Actions kernel build status

[![Build Status](https://github.com/mikeeq/mbp-fedora-kernel/actions/workflows/build-kernel.yml/badge.svg)](https://github.com/mikeeq/mbp-fedora-kernel/actions/workflows/build-kernel.yml)

Github Actions kernel publish status - <https://mikeeq.github.io/mbp-fedora-kernel/>

[![Publish Status](https://github.com/mikeeq/mbp-fedora-kernel/actions/workflows/yum-repo.yml/badge.svg)](https://github.com/mikeeq/mbp-fedora-kernel/actions/workflows/yum-repo.yml)

## How to update mbp-fedora-kernel

Starting from Fedora 37 `mbp-fedora` release - `mbp-fedora-kernel` should be automatically updated using builtin package manager - DNF, so simply run `dnf update --refresh`, and it should automatically fetch all required updates.

If the DNF fail, or you're updating your older `mbp-fedora`, you can still use previously used method with `update_kernel_mbp` described below.

```bash
### First run or if you want to update your copy of update_kernel_mbp script
sudo -i
curl -L https://raw.githubusercontent.com/mikeeq/mbp-fedora-kernel/v6.5-f38/update_kernel_mbp.sh -o /usr/bin/update_kernel_mbp
chmod +x /usr/bin/update_kernel_mbp
update_kernel_mbp

### Next runs
sudo -i
update_kernel_mbp

### Update to specific version of kernel
sudo -i
KERNEL_VERSION="6.5.4-f38" update_kernel_mbp

### Update to specific version of kernel using specific version of update script
#### Usually not needed, because scripts are shared between branches, but you can use it to update your update_kernel_mbp script
##### If the script fails, try to rerun it - it's due to self-upgrading feature of this script
sudo -i
KERNEL_VERSION="6.5.4-f38" UPDATE_SCRIPT_BRANCH="v6.5-f38" update_kernel_mbp

### If kernel update using dnf would file you can execute update_kernel_mbp script with `--github` argument, it will force it to use github to download kernel RPMs
sudo -i
update_kernel_mbp --github
```

## Known issues

- TouchID - (@MCMrARM is working on it - https://github.com/Dunedan/mbp-2016-linux/issues/71#issuecomment-528545490)
- Audio
  - Internal Microphone (it's recognized with new apple t2 sound driver, but there is a low mic volume amp)

### Partially working

- Suspend - really unstable, I recommend disabling it. If you would stuck in sleep mode, try to keep pressing power off button for a while to force poweroff and then turn on the Macbook.
- Touch Bar, if you encounter any issues, I recommend reboot to MacOS/Windows to initialize TouchBar and then back to Linux - it should fix the problem.

### Working with upstream stable kernel 6.0

- Display/Screen
- USB-C
- Battery/AC
- Ethernet/Video USB-C adapters
- Bluetooth
- NVMe
- Camera
- Thunderbolt

### Working with mbp-fedora-kernel

- with builtin BCE driver
  - Audio
  - Keyboard
  - Keyboard Backlight
  - Touchpad (scroll, right click)
- with builtin iBridge driver
  - MacBook Pro Touch Bar
    - If there's an issue with Touch Bar startup on Linux I recommend installing Win10 and boot it once a while to initialize Touch Bar using BootCamp driver, it seems to fix the issue
- WiFi
  - to make it working, you need to grab closed source Broadcom WiFi firmware from MacOS and put it under `/lib/firmware/brcm/` in Linux OS, see <https://wiki.t2linux.org/guides/wifi/>

### Not tested

- eGPU

## How to build mbp-fedora-kernel

1. Make sure that Docker is installed and running correctly on your machine
2. Clone repo
3. Generate GPG key: `gpg --full-generate-key`, choose `RSA and RSA` and `Real name: mbp-fedora`
4. Change version in `build.sh`, <https://bodhi.fedoraproject.org/updates/?search=&packages=kernel>
5. Run `./build_in_docker.sh`

## Docs

- Discord: <https://discord.gg/Uw56rqW>
- T2 Wiki: <https://wiki.t2linux.org/>
- WiFi firmware: <https://github.com/AdityaGarg8/Apple-Firmware>

### Fedora

- <https://fedoraproject.org/wiki/Building_a_custom_kernel>
- <https://fedoramagazine.org/building-fedora-kernel/>
- <https://www.hiroom2.com/2016/06/25/fedora-24-rebuild-kernel-with-src-rpm/>

### Github

- GitHub issue (RE history): <https://github.com/Dunedan/mbp-2016-linux/issues/71>
- @kekerby T2 Audio Config: <https://github.com/kekrby/t2-better-audio>
- Apple BCE repository (Apple T2 HID): <https://github.com/kekrby/apple-bce.git>
- Apple iBridge repository (TouchBar): <https://github.com/Redecorating/apple-ib-drv.git>

- hid-apple-patched module for changing mappings of ctrl, fn, option keys: <https://github.com/free5lot/hid-apple-patched>
- Linux T2 kernel patches: <https://github.com/t2linux/linux-t2-patches>
- Ubuntu
  - Kernel <https://github.com/t2linux/T2-Ubuntu-Kernel>
  - ISO <https://github.com/AdityaGarg8/T2-Ubuntu>
- Arch Linux
  - Kernel <https://github.com/Redecorating/linux-t2-arch>
  - Packages <https://github.com/Redecorating/archlinux-t2-packages>
  - ISO <https://github.com/t2linux/archiso-t2>

### Old

- VHCI+Sound driver (Apple T2): <https://github.com/MCMrARM/mbp2018-bridge-drv/>
- AppleSMC driver (fan control): <https://github.com/MCMrARM/mbp2018-etc/tree/master/applesmc>
- hid-apple keyboard backlight patch: <https://github.com/MCMrARM/mbp2018-etc/tree/master/apple-hid>
- TouchBar driver: <https://github.com/roadrunner2/macbook12-spi-driver/tree/mbp15>

### Other

- blog `Installing Fedora 31 on a 2018 Mac mini`: <https://linuxwit.ch/blog/2020/01/installing-fedora-on-mac-mini/>
- iwd:
  - <https://iwd.wiki.kernel.org/networkconfigurationsettings>
  - <https://wiki.archlinux.org/index.php/Iwd>
  - <https://www.vocal.com/secure-communication/eap-types/>

## Credits

- @MCMrARM - thanks for all RE work
- @ozbenh - thanks for submitting NVME patch
- @roadrunner2 - thanks for SPI (touchbar) driver
- @aunali1 - thanks for Kernel Patches
- @ppaulweber - thanks for keyboard and Macbook Air patches
- @AdityaGarg8 - thanks for support and upkeeping kernel patches
- @kekrby for T2 Audio config
- @Redecorating for Arch support
