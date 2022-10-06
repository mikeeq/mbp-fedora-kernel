Name: mbp-fedora-t2-config
Version: 6.0
Release: 1%{?dist}
Summary: System configuration for mbp-fedora on Apple T2 Macs.

License: GPLv2+
URL: https://github.com/mikeeq/mbp-fedora
Source0: https://github.com/mikeeq/mbp-fedora-kernel

%description
Configuration files for mbp-fedora on Apple T2 Macs. The mbp-fedora-kernel is necessary for this to work, and this must be installed to boot. Everything works except for TouchId, eGPU, and audio switching.

%prep
cp %{_sourcedir}/rmmod_tb.sh %{_builddir}/

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

%post
grubby --remove-args="efi=noruntime pcie_ports=compat" --update-kernel=ALL
grubby --args="efi=noruntime pcie_ports=compat" --update-kernel=ALL
sed -i '/^GRUB_ENABLE_BLSCFG=true/c\GRUB_ENABLE_BLSCFG=false' /etc/default/grub
grub2-mkconfig -o /boot/grub2/grub.cfg

%files
/etc/modules-load.d/apple_bce.conf
/lib/systemd/system-sleep/rmmod_tb.sh
/etc/dracut.conf.d/apple_bce_install.conf
