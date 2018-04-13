class winlogbeat::install {
  if $winlogbeat::use_chocolatey {
    include winlogbeat::install::chocolatey
  }
  else {
    include winlogbeat::install::download
  }
}
