# == Class: riak
#
# Deploy and manage Riak.
#
class riak (
  String[1] $package_name       = $::riak::params::package_name,
  String[1] $service_name       = $::riak::params::service_name,
  Boolean $manage_package       = $::riak::params::manage_package,
  Boolean $manage_repo          = $::riak::params::manage_repo,
  Boolean $manage_sudo          = $::riak::params::manage_sudo,
  String[1] $version            = $::riak::params::version,
  Integer $ulimits_nofile_soft  = $::riak::params::ulimits_nofile_soft,
  Integer $ulimits_nofile_hard  = $::riak::params::ulimits_nofile_hard,
  Hash[String, Variant[String, Boolean, Integer]] $settings = {},
) inherits ::riak::params {
  if $manage_repo and $manage_package {
    include ::riak::repository
  }
  if $manage_package {
    include ::riak::install
    Package[$::riak::package_name] ~> File[$::riak::params::riak_conf]
  }
  class { '::riak::config': } ~>
  class { '::riak::service': } ->
  Class['::riak']
}
