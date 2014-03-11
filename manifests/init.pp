# == Class: tomcat
#
# A class to obtain the packages requires for deploying tomcat instances
#
# === Parameters
#
# [*uid*] The the uid of the tomcat user to run applications as
# [*jolokia_nexus*] The nexus server which to obtain jolokia from by default
# [*jolokia_repo*] The nexus repo which to obtain jolokia from by default
# [*jolokia_version*] The jolokia_version to deploy by default
# [*user*] The user to run tomcat as
# [*group*] The group which the tomcat user should be a member of
# [*home*] The home directory for tomcat to create bases in
#
# === Authors
#
# Christopher Johnson - cjohn@ceh.ac.uk
#
class tomcat (
  $uid              = undef,
  $jolokia_nexus    = undef,
  $jolokia_repo     = undef,
  $jolokia_version  = '1.1.5',
  $package          = 'tomcat7',
  $user             = 'tomcat7',
  $group            = 'tomcat7',
  $home             = '/home/tomcat7',
  $version          = installed
) {
  # Require these base packages are installed
  package { $package :
    ensure => $version,
  }

  # NOTE: tomcat-user package is Ubuntu specific!!
  # It lets us quickly install Tomcat to any directory (see instance.pp)
  package { "${package}-user":
    ensure  => $version,
    require => Package[$package],
  }

  # Ensure the tomcat user is present and has a home
  user { $user :
    ensure      => present,
    uid         => $uid,
    gid         => $group,
    home        => $home,
    managehome  => true,
  }

  # Ensure tomcat owns its home, without this puppet seems to create the
  # tomcat home owned by root
  file { $home :
    ensure  => directory,
    owner   => $user,
    group   => $group,
  }

  # install the package, but disable the default Tomcat service
  service { $package :
    enable    => false,
    require   => Package[$package],
    ensure    => stopped
  }
}
