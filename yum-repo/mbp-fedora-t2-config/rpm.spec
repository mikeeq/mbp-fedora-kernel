Name: mbp-fedora-t2-config
Version: 5.18
Release: 2
Summary: System configuration for mbp-fedora on Apple T2 Macs.

License: GPLv2+
URL: https://github.com/mikeeq/mbp-fedora
Source0: https://github.com/mikeeq/mbp-fedora-kernel

%description
Configuration files for mbp-fedora on Apple T2 Macs. The mbp-fedora-kernel is necessary for this to work, and this must be installed to boot. Everything works except for TouchId, eGPU, and audio switching.

%prep
cp -rf %{_sourcedir}/suspend %{_builddir}/
cp -rf %{_sourcedir}/audio %{_builddir}/
cp -rf %{_sourcedir}/grub %{_builddir}/

%build
echo -e 'hid-apple\nbcm5974\nsnd-seq\napple_bce' > apple_bce.conf
echo -e 'add_drivers+=" hid_apple snd-seq apple_bce "\nforce_drivers+=" hid_apple snd-seq apple_bce "' > apple_bce_install.conf

%install
mkdir -p %{buildroot}/etc/dracut.conf.d/
mv %{_builddir}/apple_bce_install.conf %{buildroot}/etc/dracut.conf.d/apple_bce_install.conf

mkdir -p %{buildroot}/etc/modules-load.d/
mv %{_builddir}/apple_bce.conf %{buildroot}/etc/modules-load.d/apple_bce.conf

mkdir -p %{buildroot}/lib/systemd/system-sleep
mv %{_builddir}/suspend/rmmod_tb.sh %{buildroot}/lib/systemd/system-sleep/rmmod_tb.sh
chmod +x %{buildroot}/lib/systemd/system-sleep/rmmod_tb.sh

mkdir -p %{buildroot}/usr/share/alsa/cards/
mv %{_builddir}/audio/AppleT2.conf %{buildroot}/usr/share/alsa/cards/AppleT2.conf

mkdir -p %{buildroot}/usr/share/alsa-card-profile/mixer/profile-sets/
mv %{_builddir}/audio/apple-t2.conf %{buildroot}/usr/share/alsa-card-profile/mixer/profile-sets/apple-t2.conf

mkdir -p %{buildroot}/usr/lib/udev/rules.d/
mv %{_builddir}/audio/91-pulseaudio-custom.rules %{buildroot}/usr/lib/udev/rules.d/91-pulseaudio-custom.rules

%post
GRUB_CMDLINE_VALUE=$(grep -v '#' /etc/default/grub | grep -w GRUB_CMDLINE_LINUX | cut -d'"' -f2)

for i in efi=noruntime pcie_ports=compat; do
  if ! echo "$GRUB_CMDLINE_VALUE" | grep -w $i; then
   GRUB_CMDLINE_VALUE="$GRUB_CMDLINE_VALUE $i"
  fi
done

sed -i "s:^GRUB_CMDLINE_LINUX=.*:GRUB_CMDLINE_LINUX=\"${GRUB_CMDLINE_VALUE}\":g" /etc/default/grub
sed -i '/^GRUB_ENABLE_BLSCFG=false/c\GRUB_ENABLE_BLSCFG=true' /etc/default/grub
grubby --remove-args="efi=noruntime pcie_ports=compat" --update-kernel=ALL
grubby --args="efi=noruntime pcie_ports=compat" --update-kernel=ALL
grub2-mkconfig -o /boot/grub2/grub.cfg

%files
/etc/modules-load.d/apple_bce.conf
/lib/systemd/system-sleep/rmmod_tb.sh
/etc/dracut.conf.d/apple_bce_install.conf
/usr/share/alsa/cards/AppleT2.conf
/usr/share/alsa-card-profile/mixer/profile-sets/apple-t2.conf
/usr/lib/udev/rules.d/91-pulseaudio-custom.rules
