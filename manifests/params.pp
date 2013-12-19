# == Class: tomcat::params
#
# This class manages the tomcat parameters
#
# === Parameters
#
# [*user*] The $user that tomcat runs as
# [*group*] The $group that tomcat runs as
# [*home*] The $home which tomcat will spawn instances from
#
class tomcat::params {
  $uid      = 232
  $user     = 'tomcat7'
  $group    = 'tomcat7'
  $home     = '/home/tomcat7'
}