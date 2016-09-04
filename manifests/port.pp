# Definition: selinux::fcontext
#
# Description
#  This method will manage a local network port context setting, and will
#  persist it across reboots.
#  It will perform a check to ensure the network context is not already set.
#  Anyplace you wish to use this method you must ensure that the selinux class is required
#  first. Otherwise you run the risk of attempting to execute the semanage and that program
#  will not yet be installed.
#
# Class create by Matt Willsher<matt@monki.org.uk>
# Based on selinux::fcontext by Erik M Jacobs<erikmjacobs@gmail.com>
#  Adds to puppet-selinux by jfryman
#   https://github.com/jfryman/puppet-selinux
#  Originally written/sourced from Lance Dillon<>
#   http://riffraff169.wordpress.com/2012/03/09/add-file-contexts-with-puppet/
#
# Parameters:
#   - $context: A particular network port context, like "syslogd_port_t"
#   - $protocol: Either tcp or udp
#   - $port: An network port number or range, like '8514' or '10000-20000'
#
# Actions:
#  Runs "semanage port" with options to persistently set the file context
#
# Requires:
#  - SELinux
#  - policycoreutils-python (for el-based systems)
#
# Sample Usage:
#
#  selinux::port { 'allow-syslog-relp':
#    context  => 'syslogd_port_t',
#    protocol => 'tcp',
#    port     => '8514',
#  }
#
define selinux::port (
  $context,
  $port,
  $protocol,
) {

  include ::selinux

  # Use x trick so that lint etc do not warn about quoted string
  validate_re("x${port}", ['^x\d+$', '^x\d+-\d+$'])
  validate_re($protocol, ['^tcp$', '^udp$'])

  exec { "add_${context}_${port}_${protocol}":
    command => shellquote('semanage', 'port', '-a', '-t', $context, '-p', $protocol, "${port}"), # lint:ignore:only_variable_string port can be number and we need to force it to be string for shellquote
    unless  => sprintf('semanage port -E | grep -Fx %s', shellquote("port -a -t ${context} -p ${protocol} ${port}")),
    path    => '/bin:/sbin:/usr/bin:/usr/sbin',
    require => Class['selinux::package'],
  }
}
