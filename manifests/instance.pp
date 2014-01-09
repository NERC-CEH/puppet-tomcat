# == Define: tomcat::instance
#
# A class to create instances of tomcat to run under the tomcat7 user. 
#
# === Parameters
#
# [*http_port*] The $http_port to bind this tomcat instance to
# [*ajp_port*] The $ajp_port to bind this tomcat instance to
# [*shutdown_port*] The $shutdown_port for this tomcat instance to listen to
# [*service_enable*] Whether or not tomcat should have its $service_enable(d)
# [*service_ensure*] The $service_ensure state
# [*system_properties*] Defines a hash of system properties (-D) to be sent to java
# [*non_standard_opts*] Defines the -X parameters to pass to java
#
# === Requires
# - The tomcat class
# - authbind if binding to ports lower than 1024
#
# === Authors
#
# Christopher Johnson - cjohn@ceh.ac.uk
#
define tomcat::instance(
  $http_port         = undef,
  $ajp_port          = undef,
  $shutdown_port     = "8005",
  $service_enable    = true,
  $service_ensure    = 'running',
  $system_properties = {},
  $non_standard_opts = ['mx1024M', 
                        'ms256M', 
                        'X:MaxPermSize=128M', 
                        'X:PermSize=64M']
) {
  require tomcat

  $dir            = "${tomcat::home}/${name}"
  $service_name   = "tomcat7-${name}"

  # On debian, ports below and including 1024 are privileged
  # To use these, we must authbind
  if $http_port and $http_port <= 1024 {
    $authbind = true
    authbind::byport { $http_port: 
      uid     => $tomcat::uid,
      before  => Service[$service_name]
    }
  }

  # Make sure Tomcat instance was created
  # This uses the tomcat-user package scripts to create the instance
  exec { "create instance at $dir":
    command => "tomcat7-instance-create $dir",
    user    => $tomcat::user,
    group   => $tomcat::group,
    creates => $dir,
    path    => "/usr/bin:/usr/sbin:/bin",
    notify  => Service[$service_name],
  }

  # Override the default server.xml file
  # and use a template to specify the ports & appBase
  file {"${dir}/conf/server.xml":
    ensure  => file,
    owner   => $tomcat::user,
    group   => $tomcat::group,
    mode    => 0644,
    content => template("tomcat/server.xml.erb"),
    require => Exec["create instance at $dir"],
    notify  => Service[$service_name],
  }

  # Ensure that there is a place for external libs to be provided to
  file {"${dir}/lib":
    ensure  => directory,
    owner   => $tomcat::user,
    group   => $tomcat::group,
    require => Exec["create instance at $dir"],
    notify  => Service[$service_name],
  }

  # set up defaults file for this instance
  file { "/etc/default/${service_name}" :
    ensure  => file,
    owner   => root,
    group   => root,
    content => template("tomcat/default-tomcat7-instance.erb"),
    require => Exec["create instance at $dir"],
    notify  => Service[$service_name],
  }  

  # set up an init script for this instance
  file { "/etc/init.d/${service_name}" :
    ensure  => file,
    owner   => root,
    group   => root,
    mode    => 755,
    content => template("tomcat/init-tomcat7-instance.erb"),
    require => Exec["create instance at $dir"],
    notify  => Service[$service_name],
  }

  file { "${dir}/conf/policy.d" :
    ensure  => link,
    target  => '/etc/tomcat7/policy.d',
    require => Exec["create instance at $dir"],
    notify  => Service[$service_name],
  }

  service { $service_name :
    ensure => $service_ensure,
    enable => $service_enable,  
  }
}