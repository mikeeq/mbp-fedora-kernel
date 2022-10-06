Name: mbp-fedora-t2-config
Version: 5.19.14
Release: 1%{?dist}
Summary: System configuration for mbp-fedora on Apple T2 Macs.

License: GPLv2+
URL: https://github.com/mikeeq/mbp-fedora

%global KEKRBY_AUDIO_CONFIGS 2d835c6e3d4fb0406d2933638d380c8b7fb92700

Source0: https://wiki.t2linux.org/tools/rmmod_tb.sh
Source1: https://github.com/kekrby/t2-better-audio/archive/%{KEKRBY_AUDIO_CONFIGS}/t2-better-audio-%{KEKRBY_AUDIO_CONFIGS}.tar.gz
# https://codeload.github.com/kekrby/t2-better-audio/tar.gz/%{KEKRBY_AUDIO_CONFIGS}

%description
Configuration files for mbp-fedora on Apple T2 Macs. The mbp-fedora-kernel is necessary for this to work, and this must be installed to boot. Everything works except for TouchID and eGPU.

%prep
cp %{_sourcedir}/rmmod_tb.sh %{_builddir}/
tar -xf %{_sourcedir}/t2-better-audio-%{KEKRBY_AUDIO_CONFIGS}.tar.gz

%build
echo -e 'hid-apple\nbcm5974\nsnd-seq\napple_bce' > apple_bce.conf
echo -e 'add_drivers+=" hid_apple snd-seq apple_bce "\nforce_drivers+=" hid_apple snd-seq apple_bce "' > apple_bce_install.conf

%install
mkdir -p %{buildroot}/etc/dracut.conf.d/
mv %{_builddir}/apple_bce_install.conf %{buildroot}/etc/dracut.conf.d/apple_bce_install.conf

mkdir -p %{buildroot}/etc/modules-load.d/
mv %{_builddir}/apple_bce.conf %{buildroot}/etc/modules-load.d/apple_bce.conf

mkdir -p %{buildroot}/lib/systemd/system-sleep
mv %{_builddir}/rmmod_tb.sh %{buildroot}/lib/systemd/system-sleep/rmmod_tb.sh
chmod +x %{buildroot}/lib/systemd/system-sleep/rmmod_tb.sh

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
grub2-mkconfig -o /boot/grub2/grub.cfg

# Remove old audio confgs
rm -f /usr/share/alsa/cards/AppleT2.conf
rm -f /usr/share/alsa-card-profile/mixer/profile-sets/apple-t2.conf
rm -f /usr/lib/udev/rules.d/91-pulseaudio-custom.rules

%files
/etc/modules-load.d/apple_bce.conf
/lib/systemd/system-sleep/rmmod_tb.sh
/etc/dracut.conf.d/apple_bce_install.conf
/usr/share/alsa-card-profile/mixer
/usr/share/pulseaudio/alsa-mixer
/usr/lib/udev/rules.d/
