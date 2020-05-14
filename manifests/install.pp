class winlogbeat::install {
  # I'd like to use chocolatey to do this install, but the package for chocolatey is
  # failing for updates and seems rather unpredictable at the moment. We may revisit
  # that in the future as it would greatly simplify this code and basically reduce it to
  # one package resource with type => chocolatey....

  $filename = regsubst($winlogbeat::real_download_url, '^https.*\/([^\/]+)\.[^.].*', '\1')
  $foldername = 'Winlogbeat'
  $zip_file = join([$winlogbeat::tmp_dir, "${filename}.zip"], '/')
  $install_folder = join([$winlogbeat::install_dir, $foldername], '/')
  $version_file = join([$install_folder, $filename], '/')

  Exec {
    provider => powershell,
  }

  if ! defined(File[$winlogbeat::install_dir]) {
    file { $winlogbeat::install_dir:
      ensure => directory,
    }
  }

  # Note: We can use archive for unzip and cleanup, thus removing the following two resources.
  # However, this requires 7zip, which archive can install via chocolatey:
  # https://github.com/voxpupuli/puppet-archive/blob/master/manifests/init.pp#L31
  # I'm not choosing to impose those dependencies on anyone at this time...
  #
  # Chris L - no need to worry about 7zip, puppet forge says that as long as the archive
  # is a zip file, it will use powershell via .net methods for extraction (for windows server 2012 +). 
  #   Ref :https://forge.puppet.com/puppet/archive#setup 
  archive { $zip_file:
    source       => $winlogbeat::real_download_url,
    cleanup      => true,
    creates      => $version_file,
    proxy_server => $winlogbeat::proxy_address,
    require      => File[$winlogbeat::install_dir],
    extract      => true,
    extract_path => $winlogbeat::install_dir,
  }

  # You can't remove the old dir while the service has files locked...
  exec { "stop service ${filename}":
    command => 'Set-Service -Name winlogbeat -Status Stopped',
    creates => $version_file,
    onlyif  => 'if(Get-WmiObject -Class Win32_Service -Filter "Name=\'winlogbeat\'") {exit 0} else {exit 1}',
    require => Archive[$zip_file],
  }

  exec { "rename ${filename}":
    command => "Remove-Item '${install_folder}' -Recurse -Force -ErrorAction SilentlyContinue; Rename-Item '${winlogbeat::install_dir}/${filename}' '${install_folder}'",
    creates => $version_file,
    require => Exec["stop service ${filename}"],
  }

  exec { "mark ${filename}":
    command => "New-Item '${version_file}' -ItemType file",
    creates => $version_file,
    require => Exec["rename ${filename}"],
  }

  exec { "install ${filename}":
    cwd         => $install_folder,
    command     => './install-service-winlogbeat.ps1',
    refreshonly => true,
    subscribe   => Exec["mark ${filename}"],
  }
}
