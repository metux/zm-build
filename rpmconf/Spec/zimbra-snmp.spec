#
# spec file for zimbra.rpm
#
Summary: Zimbra SNMP
Name: zimbra-snmp
Version: @@VERSION@@
Release: 1%{?dist}
License: Various
Group: Applications/Messaging
URL: http://www.zimbra.com
Vendor: Zimbra, Inc.
Packager: Zimbra, Inc.
BuildRoot: /opt/zimbra
AutoReqProv: no
requires: zimbra-core, zimbra-snmp-components

%description
Best email money can buy

%define __spec_install_pre /bin/true

%define __spec_install_post /usr/lib/rpm/brp-compress /usr/lib/rpm/brp-strip-comment-note %{nil}

%prep

%build

%install

%pre

%post

%preun

%postun

%files
