
include_recipe "memcached"

if node.pd_memcached.monitor?
  include_recipe "pd_memcached::datadog"
end

if node.pd_memcached.ship_log?
  include_recipe "pd_memcached::sumologic"
end

if node.pd_memcached.supervise?
  include_recipe "pd_memcached::monit"
end
