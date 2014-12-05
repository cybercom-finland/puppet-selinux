# == Class: selinux::install
class selinux::install {
  package { [
    'policycoreutils',
    'checkpolicy',
    $selinux::params::selinux_policy_devel,
  ]:
    ensure => present,
  }
  if $selinux::installmake {
    ensure_packages(['make'])
  }
}

