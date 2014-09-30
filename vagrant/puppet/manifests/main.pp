class apt_update {
    exec { "aptGetUpdate":
        command => "sudo apt-get update",
        path => ["/bin", "/usr/bin"]
    }
}

class othertools {
    package { "git":
        ensure => latest,
        require => Exec["aptGetUpdate"]
    }

    package { "vim-common":
        ensure => latest,
        require => Exec["aptGetUpdate"]
    }

    package { "curl":
        ensure => present,
        require => Exec["aptGetUpdate"]
    }

    package { "htop":
        ensure => present,
        require => Exec["aptGetUpdate"]
    }

    package { "g++":
        ensure => present,
        require => Exec["aptGetUpdate"]
    }
}

class nodejs {
  exec { "git_clone_n":
    command => "git clone https://github.com/visionmedia/n.git /home/vagrant/n",
    path => ["/bin", "/usr/bin"],
    require => [Exec["aptGetUpdate"], Package["git"], Package["curl"], Package["g++"]]
  }

  exec { "install_n":
    command => "make install",
    path => ["/bin", "/usr/bin"],
    cwd => "/home/vagrant/n",
    require => Exec["git_clone_n"]
  }

  exec { "install_node":
    command => "n stable",
    path => ["/bin", "/usr/bin", "/usr/local/bin"],  
    require => [Exec["git_clone_n"], Exec["install_n"]]
  }
}

class mongodb {
  exec { "mongodbKeys":
    command => "sudo apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv 7F0CEB10",
    path => ["/bin", "/usr/bin"],
    notify => Exec["aptGetUpdate"],
    unless => "apt-key list | grep mongodb"
  }

  file { "mongodb.list":
    path => "/etc/apt/sources.list.d/mongodb.list",
    ensure => file,
    content => "deb http://downloads-distro.mongodb.org/repo/ubuntu-upstart dist 10gen",
    notify => Exec["mongodbKeys"]
  }

  package { "mongodb-org":
    ensure => present,
    require => [Exec["aptGetUpdate"],File["mongodb.list"]]
  }
}

class redis-cl {
  class { 'redis': }
}

class rabbitmq-server {
  class { '::rabbitmq':
    service_manage    => false,
    port              => '5672',
    delete_guest_user => true,
    admin_enable      => true,
    management_port   => 15672,
  }

  rabbitmq_user { 'dev':
    admin    => true,
    password => 'rabbit',
  }

  rabbitmq_plugin {'rabbitmq_management':
    ensure => present,
    require => Class["::rabbitmq"] 
  }

  include 'erlang'
  package { 'erlang-base':
    ensure => 'latest',
  }

  exec { "restart-rabbitmq":
    command => "service rabbitmq-server restart",
    path    => ["/bin", "/usr/bin"],
    require => Class["::rabbitmq"]
  }
}

include apt_update
include othertools
include nodejs
include mongodb
include redis-cl
include rabbitmq-server
