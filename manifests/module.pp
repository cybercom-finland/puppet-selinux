# Definition: selinux::module
#
# Description
#  This class will either install or uninstall a SELinux module from a running system.
#  This module allows an admin to keep .te files in text form in a repository, while
#  allowing the system to compile and manage SELinux modules.
#
#  Concepts incorporated from:
#  http://stuckinadoloop.wordpress.com/2011/06/15/puppet-managed-deployment-of-selinux-modules/
#
# Parameters:
#   - $ensure: (present|absent) - sets the state for a module
#   - $sx_mod_dir (absolute_path) - sets the operating state for SELinux.
#   - $source: the source directory (either a puppet URI or local
#              directory) where .te and .fc file resides
#   - $makefile: the makefile file path
#
# Actions:
#  Compiles a module using make and installs it
#
# Requires:
#  - SELinux developement tools
#
# Sample Usage:
#  selinux::module{ 'apache':
#    ensure => 'present',
#    source => 'puppet:///modules/selinux/apache/',
#  }
#
define selinux::module(
  $source       = undef,
  $ensure       = 'present',
  $makefile     = '/usr/share/selinux/devel/Makefile',
  $sx_mod_dir   = '/usr/share/selinux',
  $syncversion  = true,
) {

  include ::selinux

  validate_re($ensure, [ '^present$', '^absent$' ], '$ensure must be "present" or "absent"')
  if $source != undef {
    validate_string($source)
  }
  validate_absolute_path($sx_mod_dir)
  validate_absolute_path($makefile)
  validate_bool($syncversion)

  $selinux_policy = $::selinux_config_policy ? {
    /targeted|strict/ => $::selinux_config_policy,
    default           => $::selinux_custom_policy,
  }

  # .te and .fc files will be placed on a $name directory
  $this_module_dir = "${sx_mod_dir}/${name}"

  if $source {
    $sourcedir = $source
  } else {
    $sourcedir = "puppet:///modules/selinux/${name}"
  }

  # sourcedir validation
  # we only accept puppet:///modules/<something>/<something>, file:///anything
  # we reject .te
  case $sourcedir {
    /^puppet:\/\/\/modules\/.*\.te$/: {
      fail('Invalid source parameter, expecting a directory')
    }
    /^puppet:\/\/\/modules\/[^\/]+\/[^\/]+\/?$/: { }
    /^file:\/\/\/.*$/: { }
    default: {
      fail('Invalid source parameter')
    }
  }

  # Set Resource Defaults
  File {
    owner => 'root',
    group => 'root',
    mode  => '0640',
  }

  # Only allow refresh in the event that the initial source files are updated.
  Exec {
    path => '/sbin:/usr/sbin:/bin:/usr/bin',
    cwd  => $this_module_dir,
  }

  $active_modules = '/etc/selinux/targeted/modules/active/modules'
  $active_pp = "${active_modules}/${name}.pp"
  $compiled_pp = "${this_module_dir}/${name}.pp"
  case $ensure {
    'present': {
      file { $this_module_dir:
        ensure  => directory,
        source  => $sourcedir,
        recurse => remote,
      }
      ->
      file { "${this_module_dir}/${name}.te":
        ensure => file,
        source => "${sourcedir}/${name}.te",
      }
      ~>
      exec { $compiled_pp:
        command     => shellquote('make', '-f', $makefile),
        refreshonly => true,
      }
      ~>
      selmodule { $name:
        ensure        => present,
        selmodulepath => $compiled_pp,
        syncversion   => true,
      }
    }
    'absent': {
      selmodule { $name:
        ensure => $ensure,
      }
      file { $this_module_dir:
        ensure => absent,
        purge  => true,
        force  => true,
      }
    }
    default: {
      fail("Selinux::Module: Invalid status: ${ensure}")
    }
  }
}
