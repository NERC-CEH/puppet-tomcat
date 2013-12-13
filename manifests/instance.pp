################################################################################
# Definition: tomcat::instance
#
################################################################################
define tomcat::instance(
    $ensure        = "present",
    $http_port     = undef,
    $ajp_port      = undef,
    $shutdown_port = "8005",
    $service_enable = true,
    $service_ensure = 'running',
) {
    $dir        = "${tomcat::params::home}/${title}"
    $service_name   = "tomcat7-${title}"


    # Make sure Tomcat instance was created
    # This uses the tomcat-user package scripts to create the instance
    exec { "create instance at $dir":
        command => "tomcat7-instance-create $dir",
        user    => $tomcat::params::user,
        group   => $tomcat::params::group,
        creates => $dir,
        require => Package['tomcat7-user'],
        path    => "/usr/bin:/usr/sbin:/bin",
    }

    # Override the default server.xml file
    # and use a template to specify the ports & appBase
    file {"${dir}/conf/server.xml":
        ensure  => file,
        owner   => $tomcat::params::user,
        group   => $tomcat::params::group,
        mode    => 0644,
        content => template("tomcat/server.xml.erb"),
        require => Exec["create instance at $dir"],
    }

    # set up defaults file for this instance
    file { "/etc/default/${service_name}" :
        ensure  => file,
        owner   => root,
        group   => root,
        content => template("tomcat/default-tomcat7-instance.erb"),
        require => Exec["create instance at $dir"],
    }  

    # set up an init script for this instance
    file { "/etc/init.d/${service_name}" :
        ensure  => file,
        owner   => root,
        group   => root,
        mode    => 755,
        content => template("tomcat/init-tomcat7-instance.erb"),
        require => Exec["create instance at $dir"],
    }

    file { "${dir}/conf/policy.d" :
        ensure => link,
        target => '/etc/tomcat7/policy.d',
        require => Exec["create instance at $dir"],
    }

    service { $service_name :
        ensure => $service_ensure,
        enable => $service_enable,  
    }

}
