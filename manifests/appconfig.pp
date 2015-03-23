# For docs, see
# http://wiki.basho.com/Configuration-Files.html#app.config
#
# == Parameters
#
# cfg:
#   A configuration hash of erlang to be written to
#   File[/etc/riak/app.config]. It's recommended to browse
#   the 'appconfig.pp' file to see sample values.
#
# source:
#   The source of the app.config file, if you wish to define it
#   explicitly rather than rely on the hash. This parameter
#   is mutually exclusive with 'template'.
#
# template:
#   An ERB template file for app.config, if you wish to define it
#   explicitly rather than rely on the hash. This parameter
#   is mutually exclusive with 'source'.
#
# absent:
#   If true, the configuration file is ensured to be absent from
#   the system.
#
class riak::appconfig(
  $cfg = {},
  $source = hiera('source', ''),
  $template = hiera('template', ''),
  $absent = false,
  $riak2 = false
) {

  require riak::params

  # merge the given $cfg parameter with the default,
  # favoring the givens, rather than the defaults
  $appcfg = $riak2 ? {
    true           => merge_hashes({
      anti_entropy => 'active',
      bitcask      => {
        data_root  => '($platform_data_dir)/bitcask',
        io_mode    => erlang
      },
      distributed_cookie         => 'riak',
      dtrace                     => 'off',
      erlang                     => {
        async_threads            => 64,
        distribution_buffer_size => '64MB',
        max_ports                => 65536,
        schedulers               => { 
          compaction_of_load => 'false', 
          force_wakeup_interval => 500 
        }
      },
      leveldb          => {
        maximum_memory => {
          percent => 70 
        }
      },
      listener     => {
        http       => {
          internal => '0.0.0.0:8098'
        },
        protobuf => {
          internal => '0.0.0.0:8087'
        }
      },
      'log.console' => 'file',
      'log.crash'         => 'on',
      log         => {
        console => {
          file  => '$(platform_log_dir)/console.log',
          level => 'info'
        },
        crash                  => {
          file                 => '$(platform_log_dir)/crash.log',
          maximum_message_size => '64KB',
          rotation             => '$D0',
          'rotation.keep'      => 5,
          size                 => '10MB'
        },
        error  => {
          file => '$(platform_log_dir)/error.log'
        },
        syslog => 'off'
      },
      object      => {
        format              => 1,
        siblings            => {
          maximum           => 100,
          warning_threshold => 25
        },
        size      => {
          maximum           => '50MB',
          warning_threshold => '5MB'
        }
      },
      'riak_control.auth.mode' => 'off',
      riak_control             => 'off',
      ring_size                => 256,
      search                   => 'off',
      platform_bin_dir         => $riak::params::bin_dir,
      platform_data_dir        => $riak::data_dir,
      platform_etc_dir         => $riak::etc_dir,
      platform_lib_dir         => $riak::params::lib_dir,
      platform_log_dir         => $riak::log_dir,
      storage_backend          => 'leveldb',
      nodename                 => "riak@${riak::ip}"
      }, $cfg), 
    default                  => merge_hashes({
      kernel                 => {
        inet_dist_listen_min => 6000,
        inet_dist_listen_max => 7999,
      },
      riak_api  => {
        pb_ip   => $riak::ip,
        pb_port => 8087,
      },
      riak_core => {
        ring_state_dir     => "${$riak::data_dir}/ring",
        ring_creation_size => 64,
        http               => {
          "__string_${$riak::ip}" => 8098,
        },
        handoff_port      => 8099,
        dtrace_support    => false,
        platform_bin_dir  => $riak::params::bin_dir,
        platform_data_dir => $riak::data_dir,
        platform_etc_dir  => $riak::etc_dir,
        platform_lib_dir  => $riak::params::lib_dir,
        platform_log_dir  => $riak::log_dir,
      },
      riak_kv => {
        storage_backend       => '__atom_riak_kv_bitcask_backend',
        mapred_name           => 'mapred',
        mapred_system         => 'pipe',
        mapred_2i_pipe        => true,
        map_js_vm_count       => 8,
        reduce_js_vm_count    => 6,
        hook_js_vm_count      => 2,
        js_max_vm_mem         => 8,
        js_thread_stack       => 16,
        http_url_encoding     => '__atom_on',
        vnode_vclocks         => true,
        legacy_keylisting     => false,
        listkeys_backpressure => true,
      },
      riak_search => {
        enabled => false,
      },
      merge_index => {
        data_root            => "${$riak::data_dir}/merge_index",
        buffer_rollover_size => 1048576,
        max_compact_segments => 20,
      },
      bitcask => {
        data_root => "${$riak::data_dir}/bitcask",
      },
      eleveldb => {
        data_root => "${$riak::data_dir}/leveldb",
      },
      lager => {
        handlers => {
          lager_file_backend   => [
            ['__tuple', $riak::params::error_log, '__atom_error', 10485760, '$D0', 5],
            ['__tuple', $riak::params::info_log,  '__atom_info', 10485760, '$D0', 5],
          ]},
        crash_log             => $riak::params::crash_log,
        crash_log_msg_side    => 65536,
        crash_log_size        => 10485760,
        crash_log_date        => '$D0',
        crash_log_count       => 5,
        error_logger_redirect => true,
      },
      riak_sysmon => {
        process_limit   => 20,
        post_limit      => 2,
        gc_ms_limit     => 100,
        heap_word_limit => 40111000,
        busy_port       => true,
        busy_dist_port  => true,
      },
      sasl => {
        sasl_error_logger => false,
        utc_log           => true,
      },
      riak_control => {
        enabled  => false,
        auth     => 'userlist',
        userlist => ['__tuple', 'user', 'pass'],
        admin    => true,
      },
    }, $cfg)
  }

  $manage_file = $absent ? {
    true    => 'absent',
    default => 'present',
  }

  $config_format = $riak2 ? {
    true    => 'config',
    default => 'erlang'
  }
  $manage_template = $template ? {
    ''        => write_erl_config($appcfg, $config_format),
    default   => template($template)
  }

  $manage_source = $source ? {
    ''      => undef,
    default => $source,
  }

  anchor { 'riak::appconfig::start': }


  if ( $riak2 ) {
    file { [
        $appcfg[platform_log_dir],
        $appcfg[platform_lib_dir],
      ]:
      ensure  => directory,
      mode    => '0755',
      owner   => 'riak',
      group   => 'riak',
      require => Anchor['riak::appconfig::start'],
      before  => Anchor['riak::appconfig::end'],
    }
    file { "${$appcfg[platform_etc_dir]}/riak.conf":
      ensure  => $manage_file,
      content => $manage_template,
      source  => $manage_source,
      require => [
        File["${$appcfg[platform_log_dir]}"],
        File["${$appcfg[platform_lib_dir]}"],
        File["${$appcfg[platform_data_dir]}"],
        Anchor['riak::appconfig::start'],
      ],
      before  => Anchor['riak::appconfig::end'],
    }
  } else {
    file { [
        $appcfg[riak_core][platform_log_dir],
        $appcfg[riak_core][platform_lib_dir],
        $appcfg[riak_core][platform_data_dir],
      ]:
      ensure  => directory,
      mode    => '0755',
      owner   => 'riak',
      group   => 'riak',
      require => Anchor['riak::appconfig::start'],
      before  => Anchor['riak::appconfig::end'],
    }
    file { "${$appcfg[riak_core][platform_etc_dir]}/app.config":
      ensure  => $manage_file,
      content => $manage_template,
      source  => $manage_source,
      require => [
        File["${$appcfg[riak_core][platform_log_dir]}"],
        File["${$appcfg[riak_core][platform_lib_dir]}"],
        File["${$appcfg[riak_core][platform_data_dir]}"],
        Anchor['riak::appconfig::start'],
      ],
      before  => Anchor['riak::appconfig::end'],
    }
  }

  anchor { 'riak::appconfig::end': }
}
