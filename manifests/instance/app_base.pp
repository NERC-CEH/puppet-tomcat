# == Define: tomcat::instance::app_base
#
# Create an app base, a directory in which war files can be deployed to.
#
# === Parameters
# [*tomcat*] The $tomcat instance to deploy the application to
# [*base*] The $base to create
#
# === Authors
#
# Christopher Johnson - cjohn@ceh.ac.uk
#
define tomcat::instance::app_base(
  $tomcat,
  $base = $name
) {
  $tomcatBase = "${tomcat::home}/${tomcat}"

  file { "${tomcatBase}/${base}" :
    ensure => directory,
    owner   => $tomcat::user,
    group   => $tomcat::group,
    require => Exec["create instance at ${tomcatBase}"],
  }
}