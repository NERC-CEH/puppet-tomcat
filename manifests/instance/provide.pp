# == Define: tomcat::instance::provide
#
# Provide a given tomcat instance with an external jar file or one 
# from nexus
#
# === Parameters
#
# [*tomcat*] The $tomcat instance to add the jar to
# [*jar*] The $jar file to add to tomcat instance, this takes priority over nexus deployments
# [*nexus*] The $nexus instance to obtain the jar file from
# [*repo*] The $repo in the nexus instance to obtain the war
# [*group*] The $group of the war artifact
# [*artifact*] The $artifact name
# [*version*] The $version of the artifact
# [*jarname*] The $jarname which the jar should be provided as
#
# === Authors
#
# - Christopher Johnson cjohn@ceh.ac.uk
#
define tomcat::instance::provide (  
  $tomcat,
  $jar          = undef,
  $nexus        = undef,
  $repo         = undef,
  $group        = undef,
  $artifact     = undef,
  $version      = undef,
  $jarname      = $artifact
) {
  $tomcatLib = "${tomcat::home}/${tomcat}/lib"
  $jarfile = "${tomcatLib}/${jarname}.jar"

  if $jar {
    #Just load the jar file from the specified location
    file { $jarfile:
      source  => $jar
    }
  }
  else {
    #Obtain the jar file from nexus
    nexus::artifact { $jarfile :
      nexus     => $nexus,
      repo      => $repo,
      group     => $group,
      artifact  => $artifact,
      version   => $version,
      extension => 'jar',
    }
  }

  File[$jarfile] ~> Service["tomcat7-${tomcat}"]
}