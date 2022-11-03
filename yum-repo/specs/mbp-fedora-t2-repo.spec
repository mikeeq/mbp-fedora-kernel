Name: mbp-fedora-t2-repo
Version: 1.0.0
Release: 1%{?dist}
Summary: RPM repo for mbp-fedora on Apple T2 Macs.

%undefine _disable_source_fetch

License: GPLv2+
URL: https://github.com/mikeeq/mbp-fedora

%description
RPM repo with packages for mbp-fedora on Apple T2 Macs.

%prep
cp -rf %{_sourcedir}/repo %{_builddir}/

%build

%install
mkdir -p %{buildroot}/etc/pki/rpm-gpg
mv %{_builddir}/repo/fedora-mbp.gpg %{buildroot}/etc/pki/rpm-gpg/RPM-GPG-KEY-fedora-mbp

mkdir -p %{buildroot}/etc/yum.repos.d
mv %{_builddir}/repo/fedora-mbp-external.repo %{buildroot}/etc/yum.repos.d/fedora-mbp.repo


%files
/etc/pki/rpm-gpg/fedora-mbp.gpg
/etc/yum.repos.d/fedora-mbp.repo
