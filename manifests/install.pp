# == Class riak::install
#
# This class is called from riak for install.
#
class riak::install {
  if $::riak::manage_sudo {
    ensure_packages(['sudo'])
  }
  package { $::riak::package_name:
    ensure => $::riak::version,
    # before => Service[$::riak::service_name],
  }
}
