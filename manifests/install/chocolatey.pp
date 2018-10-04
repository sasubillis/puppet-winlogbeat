class winlogbeat::install::chocolatey {
  if $::winlogbeat::package_ensure == 'held' {
    $install_opts = ['--version', $::winlogbeat::package_version]
  }
  else {
    $install_opts = undef
  }
  package {$::winlogbeat::package_name:
    ensure          => $::winlogbeat::package_ensure,
    source          => $::winlogbeat::package_source,
    install_options => $install_opts,
    provider        => 'chocolatey',
  }
}
