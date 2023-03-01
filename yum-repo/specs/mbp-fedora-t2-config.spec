Name: mbp-fedora-t2-config
Version: 6.2.0
Release: 1%{?dist}
Summary: System configuration for mbp-fedora on Apple T2 Macs.

%undefine _disable_source_fetch

License: GPLv2+
URL: https://github.com/mikeeq/mbp-fedora

%global KEKRBY_AUDIO_CONFIGS e46839a28963e2f7d364020518b9dac98236bcae

Source0: https://github.com/kekrby/t2-better-audio/archive/%{KEKRBY_AUDIO_CONFIGS}/t2-better-audio-%{KEKRBY_AUDIO_CONFIGS}.tar.gz
# https://codeload.github.com/kekrby/t2-better-audio/tar.gz/%{KEKRBY_AUDIO_CONFIGS}

%description
Configuration files for mbp-fedora on Apple T2 Macs. The mbp-fedora-kernel is necessary for this to work, and this must be installed to boot. Everything works except for TouchID and eGPU.

%prep
tar -xf %{_sourcedir}/t2-better-audio-%{KEKRBY_AUDIO_CONFIGS}.tar.gz

%build
echo -e 'hid-apple\nbcm5974\nsnd-seq\napple_bce' > apple_bce.conf
echo -e 'add_drivers+=" hid_apple snd-seq apple_bce "\nforce_drivers+=" hid_apple snd-seq apple_bce "' > apple_bce_install.conf
echo -e '# Disable Unused Apple Ethernet\nblacklist cdc_ncm\nblacklist cdc_mbim' > apple_internal_eth_blacklist.conf
# https://github.com/t2linux/wiki/pull/343/files
echo -e 'SUBSYSTEM=="leds", ACTION=="add", KERNEL=="*::kbd_backlight", RUN+="/bin/chgrp video /sys/class/leds/%k/brightness", RUN+="/bin/chmod g+w /sys/class/leds/%k/brightness"' > 90-backlight.rules

%install
mkdir -p %{buildroot}/etc/dracut.conf.d/
mv %{_builddir}/apple_bce_install.conf %{buildroot}/etc/dracut.conf.d/apple_bce_install.conf

mkdir -p %{buildroot}/etc/modules-load.d/
mv %{_builddir}/apple_bce.conf %{buildroot}/etc/modules-load.d/apple_bce.conf

mkdir -p %{buildroot}/etc/modprobe.d/
mv %{_builddir}/apple_internal_eth_blacklist.conf %{buildroot}/etc/modprobe.d/apple_internal_eth_blacklist.conf

mkdir -p %{buildroot}/etc/udev/rules.d
mv %{_builddir}/90-backlight.rules %{buildroot}/etc/udev/rules.d/90-backlight.rules

mkdir -p %{buildroot}/usr/lib/udev/rules.d/
cp -r %{_builddir}/t2-better-audio-%{KEKRBY_AUDIO_CONFIGS}/files/91-audio-custom.rules %{buildroot}/usr/lib/udev/rules.d/

for i in %{buildroot}/usr/share/alsa-card-profile/mixer %{buildroot}/usr/share/pulseaudio/alsa-mixer
do
  mkdir -p $i
  cp -r %{_builddir}/t2-better-audio-%{KEKRBY_AUDIO_CONFIGS}/files/profile-sets $i
  cp -r %{_builddir}/t2-better-audio-%{KEKRBY_AUDIO_CONFIGS}/files/paths $i
done

%post
grubby --remove-args="efi=noruntime" --update-kernel=ALL
grubby --args="intel_iommu=on iommu=pt pcie_ports=compat" --update-kernel=ALL
sed -i "/hid_apple/d" /etc/dracut.conf
sed -i '/^GRUB_ENABLE_BLSCFG=false/c\GRUB_ENABLE_BLSCFG=true' /etc/default/grub
sed -i 's/,shim//g' /etc/yum.repos.d/fedora*.repo
grub2-mkconfig -o /boot/grub2/grub.cfg

# Fix suspend
sed -i '/AllowSuspend=/c\AllowSuspend=yes' /etc/systemd/sleep.conf
sed -i '/SuspendState=/c\SuspendState=mem' /etc/systemd/sleep.conf
sed -i '/AllowHybridSleep/c\AllowHybridSleep=no' /etc/systemd/sleep.conf
grep -q "AllowSuspend=" "/etc/systemd/sleep.conf" || echo "AllowSuspend=yes" >> "/etc/systemd/sleep.conf"
grep -q "SuspendState=" "/etc/systemd/sleep.conf" || echo "SuspendState=mem" >> "/etc/systemd/sleep.conf"
grep -q "AllowHybridSleep=" "/etc/systemd/sleep.conf" || echo "AllowHybridSleep=no" >> "/etc/systemd/sleep.conf"

# Remove old audio confgs
rm -f /usr/share/alsa/cards/AppleT2.conf
rm -f /usr/share/alsa-card-profile/mixer/profile-sets/apple-t2.conf
rm -f /usr/lib/udev/rules.d/91-pulseaudio-custom.rules
rm -f /lib/systemd/system-sleep/rmmod_tb.sh

%files
/etc/modules-load.d/apple_bce.conf
/etc/dracut.conf.d/apple_bce_install.conf
/etc/modprobe.d/apple_internal_eth_blacklist.conf
/usr/share/alsa-card-profile/mixer
/usr/share/pulseaudio/alsa-mixer
/usr/lib/udev/rules.d/
/etc/udev/rules.d/
