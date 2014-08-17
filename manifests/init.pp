# Public: installs java jre-7u51 and JCE unlimited key size policy files
#
# Examples
#
#    include java
class java (
  $update_version = '65',
  $base_download_url = 'https://s3.amazonaws.com/boxen-downloads/java'
) {
  include boxen::config
  
  if $osfamily=='Darwin' {
	  $jre_url = "${base_download_url}/jre-7u${update_version}-macosx-x64.dmg"
	  $jdk_url = "${base_download_url}/jdk-7u${update_version}-macosx-x64.dmg"
	  $wrapper = "${boxen::config::bindir}/java"
	  $jdk_dir = "/Library/Java/JavaVirtualMachines/jdk1.7.0_${update_version}.jdk"
	  $sec_dir = "${jdk_dir}/Contents/Home/jre/lib/security"
    $group = 'wheel'
    
	  package {
	    "jre-7u${update_version}.dmg":
	      ensure   => present,
	      alias    => 'java-jre',
	      provider => pkgdmg,
	      source   => $jre_url ;
	    "jdk-7u${update_version}.dmg":
	      ensure   => present,
	      alias    => 'java',
	      provider => pkgdmg,
	      source   => $jdk_url ;
	  }
	  
	  file { $wrapper:
	    source  => 'puppet:///modules/java/java.sh',
	    mode    => '0755',
	    require => Package['java']
	  }
	  
	  # Allow 'large' keys locally.
    # http://www.ngs.ac.uk/tools/jcepolicyfiles
    
    file { $sec_dir:
      ensure  => 'directory',
      owner   => 'root',
      group   => 'wheel',
      mode    => '0775',
      require => Package['java']
    }
  
    file { "${sec_dir}/local_policy.jar":
      source  => 'puppet:///modules/java/local_policy.jar',
      owner   => 'root',
      group   => 'wheel',
      mode    => '0664',
      require => File[$sec_dir]
    }
  
    file { "${sec_dir}/US_export_policy.jar":
      source  => 'puppet:///modules/java/US_export_policy.jar',
      owner   => 'root',
      group   => 'wheel',
      mode    => '0664',
      require => File[$sec_dir]
    }
	}
  elsif $osfamily=='Debian' {
    include apt

    # expletive-deleted Puppet. The default Exec{} and Package{} settings in boxen/manifests/site.pp screw up the exec{} and package{} declarations in the Puppetlabs-apt module
    # the following resource collectors are a workaround. Resource Collectors: the cause of, and solution to, all of my problems
    Exec <| title == "apt_update" |> { 
      user => 'root',
    }
    Package <| title == "software-properties-common" |> { 
      provider => apt,
    }

    file { '/tmp/oracle-java7-installer.seeds':
      source => 'puppet:///modules/java/oracle-java7-installer.seeds',
      mode   => '0600',
      backup => false,
    }

    apt::ppa { 'ppa:webupd8team/java': }

    apt::hold { 
      'oracle-java7-installer':
		    version => "7u${update_version}*",
		}

    package { 
      "oracle-java7-installer":
			  alias        => 'java',
			  ensure       => latest,
			  provider     => apt,
			  require      => [ Apt::Ppa['ppa:webupd8team/java'],
                          File['/tmp/oracle-java7-installer.seeds']
                        ],
			  responsefile => '/tmp/oracle-java7-installer.seeds'
    }
  }
  else {
    fail("the java module only has support for OSX and Debian variants right now")
  }
}
