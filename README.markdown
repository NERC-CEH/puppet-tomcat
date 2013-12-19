# Tomcat

## Overview

This is the tomcat module, it allows you to create instances of tomcat and deploy tomcat applications

## Module Description

With this module you can create instances of tomcat on debian. These instances can either be standalone or fronted by apache using the ajp connector.

You can also deploy applications which are hosted either on the puppet file system or from a nexus instance

## Setup

### What Tomcat affects

* Installs the tomcat package
* Install the tomcat-user package

## Usage

To create an insance of tomcat

    tomcat::instance {'myTomcat':
        http_port   => 80,
    }

And then deploy a maven artifact to that instance from nexus

    tomcat::deployment {'Deploy my web app':
        tomcat      => 'myTomcat',
        group       => 'my.new.project',
        artifact    => 'project-webapp',
    }

or from a war file

    tomcat::deployment {'A different application':
        tomcat      => 'myTomcat',
        war         => 'puppet:///webapps/dummy.war',
        application => 'secondApp'
    }

You can also provide a tomcat base with additional jar files 

    tomcat::instance::provide { 'Provide myTomcat with jar from nexus' :
        tomcat   => 'myTomcat',
        group    => 'my.custom.jar',
        artifact => 'provided-to-tomcat',
    }

## Limitations

This module has been tested on ubuntu 12.04 lts

## Contributors

Christopher Johnson - cjohn@ceh.ac.uk