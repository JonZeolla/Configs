class auditd {
  case $::operatingsystem {
    'Ubuntu': {
      case $::lsbdistcodename {
        'trusty': {
          package { 'libaudit1':
            ensure => present
          }
        }
        'precise': {
          package { 'libaudit0':
            ensure => present
          }
        }
        'lucid': {
          package { 'libaudit0':
            ensure => present
          }

          package { 'acct':
            ensure => present
          }

          service { 'acct':
            enable  => true,
            require => Package['acct'],
          }
        }
        default: {
         err("${::fqdn} doesn't run a managed lsbdistcodename.  The currently managed lsbdistcodenames are trusty, precise, and lucid.  ")
        }
      }
      
      package { 'auditd':
        ensure => present,
      }

      service { 'auditd':
        enable  => true,
        require => Package['auditd'],
      }

      file { '/etc/audit/audit.rules':
        ensure  => 'present',
        source  => [
          "puppet:///modules/auditd/audit.rules.d/audit.rules.${::fqdn}",
          "puppet:///modules/auditd/audit.rules.d/audit.rules.${::lsbdistcodename}",
          'puppet:///modules/auditd/audit.rules',
          ],
        owner   => 'root',
        group   => 'root',
        mode    => '0644',
        require => Package['auditd'],
        notify  => Service['auditd'],
      }

      file { '/etc/audit/auditd.conf':
        ensure  => 'present',
        source  => [
          "puppet:///modules/auditd/auditd.conf.d/auditd.conf.${::fqdn}",
          "puppet:///modules/auditd/auditd.conf.d/auditd.conf.${::lsbdistcodename}",
          'puppet:///modules/auditd/auditd.conf',
          ],
        owner   => 'root',
        group   => 'root',
        mode    => '0640',
        require => Package['auditd'],
        notify  => Service['auditd'],
      }

      # As of 2015-05-02 you cannot modify or add comments to these conf files (inline, separate line, directly after the existing comments, etc.) without it failing to parse with a "audispd: Missing equal sign" error
      # As of 2015-05-04 only Ubuntu 14.x and newer (Trusty) has a version of auditd available which can set the facility to anything other than default (facility 1 (user) severity 6 (info)) - 14.x and newer allows you to set it to LOG_LOCAL{0..7} via args in syslog.conf.  If you plan to syslog the auditd logs, you will need to manage this appropriately (I did it by ${::lsbdistcodename}, hence the multiple sources in this manifest).  
      file { '/etc/audisp/plugins.d/syslog.conf':
        ensure  => 'present',
        source  => [
          "puppet:///modules/auditd/syslog.conf.d/syslog.conf.${::fqdn}",
          "puppet:///modules/auditd/syslog.conf.d/syslog.conf.${::lsbdistcodename}",
          'puppet:///modules/auditd/syslog.conf',
          ],
        source  => 'puppet:///modules/auditd/syslog.conf',
        owner   => 'root',
        group   => 'root',
        mode    => '0640',
        require => Package['auditd'],
        notify  => Service['auditd'],
      }

      # While doing troubleshooting I noticed that audispd by default had 0755 permissions and it was writing a log saying it should be 0750
      file { '/sbin/audispd':
        mode    => '0750',
        owner   => 'root',
        group   => 'root',
        require => Package['auditd'],
        notify  => Service['auditd'],
      }

      file { '/usr/local/bin/auditd_log-rotation.sh':
        ensure  => 'present',
        owner   => 'root',
        group   => 'admin',
        mode    => '755',
        source  => 'puppet:///public/auditd/auditd_log-rotation.sh',
        require => File['/etc/audisp/plugins.d/syslog.conf'],
      }

      cron { 'rotate-audit-logs':
        ensure  => 'present',
        command => '/usr/local/bin/auditd_log-rotation.sh',
        user    => 'root',
        hour    => '00',
        minute  => '00',
        require => File['/usr/local/bin/auditd_log-rotation.sh'],
      }
    }
  default: {
    err("The auditd class is for Ubuntu systems.  ${::fqdn} runs ${::operatingsystem}")
    }
  }

}
