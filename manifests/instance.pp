# == Define: tomcat::instance
#
# A class to create instances of tomcat to run under the tomcat user.
#
# === Parameters
#
# [*http_port*] The $http_port to bind this tomcat instance to
# [*ajp_port*] The $ajp_port to bind this tomcat instance to
# [*proxy_port*] The $proxy_port for this tomcats connection. (Returned in java request.getServerPort() )
# [*secure*] the value which java returns when request.isSecure() is called
# [*scheme*] the value which java returns when request.getScheme() is called
# [*packet_size*] the maximum ajp packetSize value. This should be the same as the Apache ProxyIOBufferSize
# [*enableUserDatabaseRealm*] Boolean to enable default file based userdatabase
# [*enableJaasRealm*] Boolean to enable a jaas realm
# [*jaasAppName*] jaas Realm application name
# [*jaasUserClassName*] jaas Realm class representing user principals
# [*jaasRoleClassName*] jaas Realm class representing role principals
# [*jaasLoginModule] Class name of the custom jaas login module to use
# [*jaasConfigMap] Hash of key/value pairs for params to pass to login module
# [*jolokia_port*] The $jolokia_port which this tomcat instance can be monitored on
# [*jolokia_nexus*] The nexus server to obtain jolokia from, defaults to tomcat::jolokia_nexus
# [*jolokia_repo*] The nexus repository to obtain jolokia from, defaults to tomcat::jolokia_repo
# [*jolokia_version*] The version of jolokia to deploy, defaults to tomcat::jolokia_version
# [*shutdown_port*] The $shutdown_port for this tomcat instance to listen to, -1 is don't listen
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
# Mike Wilson - mw@ceh.ac.uk
#
define tomcat::instance(
  $http_port               = undef,
  $ajp_port                = undef,
  $proxy_port              = undef,
  $secure                  = undef,
  $scheme                  = undef,
  $packet_size             = undef,
  $enableUserDatabaseRealm = true,
  $enableJaasRealm         = false,
  $jaasAppName             = undef,
  $jaasUserClassName       = undef,
  $jaasRoleClassName       = undef,
  $jaasLoginModule         = undef,
  $jaasConfigMap           = undef,
  $java_home               = undef,
  $jolokia_port            = undef,
  $jolokia_nexus           = $tomcat::jolokia_nexus,
  $jolokia_repo            = $tomcat::jolokia_repo,
  $jolokia_version         = $tomcat::jolokia_version,
  $shutdown_port           = '-1',
  $service_enable          = true,
  $service_ensure          = 'running',
  $system_properties       = {'java.awt.headless' => true},
  $non_standard_opts       = ['mx1024M',
                              'ms256M',
                              'X:MaxPermSize=128M',
                              'X:PermSize=64M']
) {
  if ! defined(Class['tomcat']) {
    fail('You must include the tomcat base class before using any tomcat defined resources')
  }

  validate_bool($enableJaasRealm)
  validate_bool($enableUserDatabaseRealm)

  # If jaasRealm is enabled, check all params as correct type
  if $enableJaasRealm {
    validate_string($jaasAppName)
    validate_string($jaasUserClassName)
    validate_string($jaasRoleClassName)
    validate_string($jaasLoginModule)
    validate_hash($jaasConfigMap)
  }

  $dir            = "${tomcat::home}/${name}"
  $service_name   = "${tomcat::package}-${name}"

  # On debian, ports below and including 1024 are privileged
  # To use these, we must authbind
  if $http_port and $http_port <= 1024 {
    $authbind = true
    authbind::byport { $http_port:
      uid     => $tomcat::uid,
      before  => Service[$service_name]
    }
  }

  # Set up jolokia monitoring on the given port
  if $jolokia_port {
    tomcat::instance::app_base { "jmx4perl for ${name}" :
      tomcat => $name,
      base   => 'jmx4perl',
    }

    tomcat::deployment { "jolokia_for_${name}" :
      tomcat   => $name,
      app_base => 'jmx4perl',
      group    => 'org.jolokia',
      artifact => 'jolokia-war',
      version  => $jolokia_version,
      nexus    => $jolokia_nexus,
      repo     => $jolokia_repo,
    }
  }

  # Make sure Tomcat instance was created
  # This uses the tomcat-user package scripts to create the instance
  exec { "create instance at $dir":
    command => "${tomcat::package}-instance-create $dir",
    user    => $tomcat::user,
    group   => $tomcat::group,
    creates => $dir,
    path    => "/usr/bin:/usr/sbin:/bin",
    notify  => Service[$service_name],
    require => Class['tomcat'],
  }

  # Override the default server.xml file
  # and use a template to specify the ports & appBase
  file {"${dir}/conf/server.xml":
    ensure  => file,
    owner   => $tomcat::user,
    group   => $tomcat::group,
    mode    => '0644',
    content => template("tomcat/server.xml.erb"),
    require => Exec["create instance at $dir"],
    notify  => Service[$service_name],
  }

  if $enableJaasRealm {
    file {"${dir}/conf/jaas.config":
      ensure  => file,
      owner   => $tomcat::user,
      group   => $tomcat::group,
      mode    => '0644',
      content => template("tomcat/jaas.config.erb"),
      require => Exec["create instance at $dir"],
      notify  => Service[$service_name],
    }
  }

  # Define the webapps (default app base) to deploy applications to
  tomcat::instance::app_base { "webapps for ${name}" :
    tomcat => $name,
    base   => 'webapps',
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
    content => template("tomcat/default-tomcat-instance.erb"),
    require => Exec["create instance at $dir"],
    notify  => Service[$service_name],
  }

  # set up an init script for this instance
  file { "/etc/init.d/${service_name}" :
    ensure  => file,
    owner   => root,
    group   => root,
    mode    => '0755',
    content => template("tomcat/init-tomcat-instance.erb"),
    require => Exec["create instance at $dir"],
    notify  => Service[$service_name],
  }

  file { "${dir}/conf/policy.d" :
    ensure  => link,
    target  => "/etc/${tomcat::package}/policy.d",
    require => Exec["create instance at $dir"],
    notify  => Service[$service_name],
  }

  service { $service_name :
    ensure => $service_ensure,
    enable => $service_enable,
  }
}

