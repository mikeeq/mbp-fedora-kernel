# mbp-fedora-kernel

Fedora kernel with Apple T2 patches built-in (Macbooks produced >= 2018).

Fedora ISO (with mbp-fedora-kernel builtin) - <https://github.com/mikeeq/mbp-fedora>

Drivers:

- Apple T2 (audio, keyboard, touchpad) - <https://github.com/MCMrARM/mbp2018-bridge-drv>
- Apple SMC - <https://github.com/MCMrARM/mbp2018-etc>
- Touchbar - <https://github.com/roadrunner2/macbook12-spi-driver/tree/mbp15>

## How to update kernel-mbp

```
### First run
sudo -i
curl -L https://raw.githubusercontent.com/mikeeq/mbp-fedora-kernel/v5.6-f31/update_kernel_mbp.sh -o /usr/bin/update_kernel_mbp
chmod +x /usr/bin/update_kernel_mbp
update_kernel_mbp

### Next ones
sudo -i
update_kernel_mbp
```

## CI status

Drone kernel build status:
[![Build Status](https://cloud.drone.io/api/badges/mikeeq/mbp-fedora-kernel/status.svg)](https://cloud.drone.io/mikeeq/mbp-fedora-kernel)

Travis kernel publish status - <http://fedora-mbp-repo.herokuapp.com/> :
[![Publish Status](https://travis-ci.com/mikeeq/mbp-fedora-kernel.svg?branch=master)](https://travis-ci.com/mikeeq/mbp-fedora-kernel)

## TODO

- integrate `roadrunner2/macbook12-spi-driver` and `MCMrARM/mbp2018-bridge-drv` drivers into kernel
- add `kernel-headers` rpm generation

> Tested on: Macbook Pro 15,2 13" 2019 i5 TouchBar Z0WQ000AR MV972ZE/A/R1

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
- wifi
  - you need to manually extract firmware from macOS
    - <https://github.com/Dunedan/mbp-2016-linux/issues/71#issuecomment-517444300>
    - <https://github.com/Dunedan/mbp-2016-linux/issues/71#issuecomment-515401480>
  - or download it from <https://packages.aunali1.com/apple/wifi-fw/18G2022>
  - every version of Broadcom MBP >=2018 have different value of rambase_addr, so the one defined in wifi patch doesn't need to match your one, to find out what suits your version of the chip and load it at boot - you need to:

    ```
    ## dynamically reload brcmfmac kernel module with different rambase_addr values and check dmesg if the module is correctly loading FW. The most probable values: 0x160000, 0x180000, 0x198000, 0x200000

    modprobe -r brcmfmac; modprobe brcmfmac rambase_addr=0x160000

    ## To load correct rambase_addr at boot please add kernel arg to grub and reload grub cfg
    # /etc/default/grub
      GRUB_CMDLINE_LINUX=" brcmfmac.rambase_addr=0x160000"
    grub2-mkconfig -o /boot/efi/EFI/fedora/grub.cfg
    ```

> Firmware can be found by running `ioreg -l | grep C-4364` or `ioreg -l | grep RequestedFiles` under macOS

```
Put the firmware in the right place!
The .trx file for your model goes to /lib/firmware/brcm/brcmfmac4364-pcie.bin,
the .clmb goes to /lib/firmware/brcm/brcmfmac4364-pcie.clm_blob
and the .txt to something like /lib/firmware/brcm/brcmfmac4364-pcie.Apple Inc.-MacBookPro15,2.txt
```

```
# ls -l /lib/firmware/brcm | grep 4364
-rw-r--r--. 1 root root   12860 Mar  1 12:44 brcmfmac4364-pcie.Apple Inc.-MacBookPro15,2.txt
-rw-r--r--. 1 root root  922647 Mar  1 12:44 brcmfmac4364-pcie.bin
-rw-r--r--. 1 root root   33226 Mar  1 12:44 brcmfmac4364-pcie.clm_blob
```

```
## How correct brcmfmac FW load should look like in dmesg
# dmesg
brcmfmac 0000:01:00.0: enabling device (0000 -> 0002)
brcmfmac: brcmf_fw_alloc_request: using brcm/brcmfmac4364-pcie for chip BCM4364/3
brcmfmac: brcmf_fw_alloc_request: using brcm/brcmfmac4364-pcie for chip BCM4364/3
brcmfmac: brcmf_c_preinit_dcmds: Firmware: BCM4364/3 wl0: Mar 28 2019 19:17:52 version 9.137.9.0.32.6.34 FWID 01-36f56c94
brcmfmac 0000:01:00.0 wlp1s0: renamed from wlan0
```

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
