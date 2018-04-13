class winlogbeat::install::chocolatey {
  package {$::winlogbeat::package_name:
    ensure   => $::winlogbeat::package_ensure,
    source   => $::winlogbeat::package_source,
    provider => 'chocolatey',
  }
}
