#
# Definition: tomcat::deployment
#
# This class is capable of deploying nexus artifacts and war files
# to an instance of tomcat
#
# Authors:
#   Christopher Johnson - cjohn@ceh.ac.uk
#
# Parameters:
# - The $application to deploy
# - The $tomcat instance to deploy the application to
# - The $war file to deploy, this takes priority over nexus deployments
# - The $nexus instance to obtain the war file from
# - The $repo in the nexus instance to obtain the war
# - The $group of the war artifact
# - The $artifact name
# - The $version of the artifact
#
# Requires:
# - The nexus module, if doing nexus deployments
#
define tomcat::deployment(
  $application = 'ROOT',
  $tomcat,
  $war = undef,
  $nexus = $nexus::params::nexus,
  $repo = $nexus::params::repo,
  $group,
  $artifact,
  $version = $nexus::params::version
) {
  $webapp = "${tomcat::params::home}/${tomcat}/webapps/${application}"
  $warfile = "${webapp}.war"

  if $war {
    #Just load the war file from the specified location
    file { $warfile:
      source  => $war
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
}