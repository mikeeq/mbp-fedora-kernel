Name: mbp-fedora-t2-repo
Version: 1.1.0
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
mv %{_builddir}/repo/mbp-fedora-repo.gpg %{buildroot}/etc/pki/rpm-gpg/RPM-GPG-KEY-mbp-fedora

mkdir -p %{buildroot}/etc/yum.repos.d
mv %{_builddir}/repo/mbp-fedora-external.repo %{buildroot}/etc/yum.repos.d/mbp-fedora.repo

%post
rm -rf /etc/pki/rpm-gpg/RPM-GPG-KEY-fedora-mbp
rm -rf /etc/yum.repos.d/fedora-mbp.repo

%files
/etc/pki/rpm-gpg/RPM-GPG-KEY-mbp-fedora
/etc/yum.repos.d/mbp-fedora.repo
