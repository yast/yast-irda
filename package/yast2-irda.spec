#
# spec file for package yast2-irda
#
# Copyright (c) 2013 SUSE LINUX Products GmbH, Nuernberg, Germany.
#
# All modifications and additions to the file contributed by third parties
# remain the property of their copyright owners, unless otherwise agreed
# upon. The license for this file, and modifications and additions to the
# file, is the same license as for the pristine package itself (unless the
# license for the pristine package is not an Open Source License, in which
# case the license is the MIT License). An "Open Source License" is a
# license that conforms to the Open Source Definition (Version 1.9)
# published by the Open Source Initiative.

# Please submit bugfixes or comments via http://bugs.opensuse.org/
#


Name:           yast2-irda
Version:        3.0.1
Release:        0

BuildRoot:      %{_tmppath}/%{name}-%{version}-build
Source0:        %{name}-%{version}.tar.bz2

Group:          System/YaST
License:        GPL-2.0
BuildRequires:	docbook-xsl-stylesheets doxygen libxslt perl-XML-Writer sgml-skel update-desktop-files yast2-testsuite
BuildRequires:  yast2-devtools >= 3.0.6
# Service module switched to systemd
BuildRequires:	yast2 >= 2.23.15
Requires:	yast2 >= 2.21.22

BuildArchitectures:	noarch

Requires:       yast2-ruby-bindings >= 1.0.0

Summary:	YaST2 - Infra-Red (IrDA) Access Configuration

%description
The YaST2 component for configuring the Infra-red Data Access (IrDA)
stack.

%prep
%setup -n %{name}-%{version}

%build
%yast_build

%install
%yast_install


%files
%defattr(-,root,root)
%dir %{yast_yncludedir}/irda
%{yast_yncludedir}/irda/*
%{yast_clientdir}/irda.rb
%{yast_moduledir}/Irda.*
%{yast_desktopdir}/irda.desktop
%{yast_scrconfdir}/*.scr
%doc %{yast_docdir}
%doc COPYING
