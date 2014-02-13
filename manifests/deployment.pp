# == Define: tomcat::deployment
#
# This class is capable of deploying nexus artifacts and war files
# to an instance of tomcat.
#
# === Parameters
#
# [*tomcat*] The $tomcat instance to deploy the application to
# [*application*] The $application to deploy
# [*war*] The $war file to deploy, this takes priority over nexus deployments
# [*nexus*] The $nexus instance to obtain the war file from
# [*repo*] The $repo in the nexus instance to obtain the war
# [*group*] The $group of the war artifact
# [*artifact*] The $artifact name
# [*version*] The $version of the artifact
# [*app_base*] The $app_base which this deployment should reside in
#
# === Requires
# - The nexus module if doing nexus deployments
#
# === Authors
#
# Christopher Johnson - cjohn@ceh.ac.uk
#
define tomcat::deployment(
  $tomcat,
  $application  = 'ROOT',
  $war          = undef,
  $nexus        = undef,
  $repo         = undef,
  $group        = undef,
  $artifact     = undef,
  $version      = undef,
  $app_base     = 'webapps'
) {
  if ! defined(Tomcat::Instance[$tomcat]) {
    fail('You must define a tomcat instance which we can deploy an application to')
  }

  $tomcatBase = "${tomcat::home}/${tomcat}"
  $webapp = "${tomcatBase}/${app_base}/${application}"
  $warfile = "${webapp}.war"

  if $war {
    #Just load the war file from the specified location
    file { $warfile:
      source  => $war,
    }
  }
  else {
    #Obtain the war file from nexus
    nexus::artifact { $warfile :
      nexus    => $nexus,
      repo     => $repo,
      group    => $group,
      artifact => $artifact,
      version  => $version,
    }
  }
  
  exec { "rm -Rf $webapp":
    subscribe   => File[$warfile],
    notify      => Service["tomcat7-${tomcat}"],
    refreshonly => true,
    path        => "/usr/bin:/usr/sbin:/bin",
  }

  Exec["create instance at $tomcatBase"] -> File[$warfile]
}
