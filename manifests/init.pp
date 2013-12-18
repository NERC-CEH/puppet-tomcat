#
# Definition: tomcat
#
# A class to obtain the packages requires for deploying tomcat instances
#
# Authors:
#   Christopher Johnson - cjohn@ceh.ac.uk
#
class tomcat (
) inherits tomcat::params {

    # Require these base packages are installed
    package { 'tomcat7':
        ensure => installed,
    }

    # NOTE: tomcat-user package is Ubuntu specific!!
    # It lets us quickly install Tomcat to any directory (see instance.pp)
    package { 'tomcat7-user':
        ensure  => installed,
        require => Package['tomcat7'],
    }

    # Ensure the tomcat7 user is present and has a home
    user { $user :
        ensure      => present,
        uid         => 232,
        gid         => $group,
        home        => $home,
        managehome  => true,
    }

    # install the package, but disable the default Tomcat service
    service { 'tomcat7':
        enable    => false,
        require   => Package['tomcat7'],
        ensure    => stopped
    }
}
