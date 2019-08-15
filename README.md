# mbp-fedora-kernel

[![Build Status](https://cloud.drone.io/api/badges/mikeeq/mbp-fedora-kernel/status.svg)](https://cloud.drone.io/mikeeq/mbp-fedora-kernel)

Fedora 30 kernel for Macs produced after 2018 (with Apple T2 chip).

## Known issues

- 5.2 kernel - random kernel panics - <https://github.com/Dunedan/mbp-2016-linux/issues/71#issuecomment-510652894>

> Tested on: Macbook Pro 13" 2019 i5 TouchBar Z0WQ000AR

#### Working out-of-the-box

- Display/Screen
- Thunderbolt 3/USB-C
- Battery/AC
- Ethernet/Video USB-C adapters
- Bluetooth

#### Working with this kernel

- NVMe
- Camera
- wifi - you need to manually extract firmware from MacOS - <https://github.com/Dunedan/mbp-2016-linux/issues/71#issuecomment-517444300>

> The firmware files to use can be found by running `ioreg -l | grep C-4364`.

<https://github.com/Dunedan/mbp-2016-linux/issues/71#issuecomment-515401480>

```
Put the firmware in the right place!
The .trx file for your model goes to /lib/firmware/brcm/brcmfmac4364-pcie.bin,
the .clmb goes to /lib/firmware/brcm/brcmfmac4364-pcie.clm_blob
and the .txt to something like /lib/firmware/brcm/brcmfmac4364-pcie.Apple Inc.-MacBookPro15,2.txt
```

#### Working with external drivers

>> with @MCMrARM mbp2018-bridge-drv

- keyboard

#### Partially working

- touchpad (only LMB is working, no RMB)
- audio (you need to manually switch between audio outputs) - <https://github.com/Dunedan/mbp-2016-linux/issues/71#issuecomment-517208901>
- touchbar (fn mode is broken and keyboard brightness isn't working) - <https://github.com/Dunedan/mbp-2016-linux/issues/110#issuecomment-521044302>

#### Not working

- microphone

#### Not tested

- suspend/resume (sleep mode)
- hibernation
- eGPU

## Docs

### Fedora

- <https://fedoraproject.org/wiki/Building_a_custom_kernel>
- <https://fedoramagazine.org/building-fedora-kernel/>
- <https://www.hiroom2.com/2016/06/25/fedora-24-rebuild-kernel-with-src-rpm/>

### Github

- GitHub issue (RE history): <https://github.com/Dunedan/mbp-2016-linux/issues/71>
- VHCI+Sound driver (Apple T2) <https://github.com/MCMrARM/mbp2018-bridge-drv/>
- TouchBar driver: <https://github.com/roadrunner2/macbook12-spi-driver/tree/mbp15>
- Kernel patches (all are mentioned in github issue above): <https://github.com/aunali1/linux-mbp-arch>

## Credits

- @MCMrARM - thanks for all RE work
- @ozbenh - thanks for submitting NVME patch
- @roadrunner2 - thanks for SPI (touchbar) driver
- @aunali1 - thanks for ArchLinux Kernel CI
