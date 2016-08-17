Name:           taskopen
Version:        1.1.2
Release:        1%{?dist}
BuildArch:      noarch
Summary:        taskopen allows you to link files or notes to a taskwarrior task

License:        GPL
URL:            https://github.com/ValiValpas/taskopen
Source0:        https://github.com/ValiValpas/%{name}/archive/v%{version}.tar.gz#/%{name}-%{version}.tar.gz

Requires:       perl-JSON


%description
taskopen allows you to link almost any file, webpage or command to a taskwarrior
task by adding a filepath, web-link or uri as an annotation. Text notes, images,
PDF files, web addresses, spreadsheets and many other types of links can then be
filtered, listed and opened by using taskopen. Some actions are sane defaults,
others can be custom-configured, and everything else will use your systems
mime-types to open the link.


%prep
%autosetup


%build
make PREFIX=%{_prefix}

%install
rm -rf $RPM_BUILD_ROOT
%make_install PREFIX=%{_prefix}


%files
%doc AUTHORS NEWS README.markdown
%{_prefix}/bin/taskopen
%{_prefix}/share/taskopen
%{_prefix}/share/man/man*/taskopen*.gz


%changelog
* Tue Aug 16 2016 Mike Gerber <mike@sprachgewalt.de>
- First package
