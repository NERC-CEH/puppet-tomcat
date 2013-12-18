#
# Definition: tomcat::params
#
# This class manages the tomcat parameters
#
# Parameters:
# - The $user that tomcat runs as
# - The $group that tomcat runs as
# - The $home which tomcat will spawn instances from
#
class tomcat::params {
  $uid      = 232
  $user     = "tomcat7"
  $group    = "tomcat7"
  $home     = "/home/tomcat7"
}