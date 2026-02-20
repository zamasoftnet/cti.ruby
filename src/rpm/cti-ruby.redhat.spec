%define rubylib %{_prefix}/lib/ruby/site_ruby

Name:			cti-ruby
Version:		@version.number@
Release:		0
Epoch:			@build.number@
Group:			Publishing
Summary:		Copper PDF Ruby driver
Source0:		cti-ruby-@aversion.number@.tar.gz
Requires:		ruby >= 1.8.7
BuildRoot:		%{_tmppath}/%{name}-%{version}-%{release}-buildroot
Vendor:			Zamasoft
License:		Commercial
URL:			http://copper-pdf.com/
Packager:		MIYABE Tatsuhiko
ExclusiveOS:	linux

%description
cti-ruby-@version.number@

%prep
rm -rf $RPM_BUILD_ROOT/*
mkdir -p $RPM_BUILD_ROOT%{rubylib}

%setup

%build

%install
cp -pr code/* $RPM_BUILD_ROOT%{rubylib}/

%pre

%post

%preun

%clean
rm -rf $RPM_BUILD_ROOT

%files
%defattr(-, root, root, -)
%{rubylib}
