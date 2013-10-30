include_recipe 'datadog::dd-agent'

package 'python-memcache'

template '/etc/dd-agent/conf.d/mcache.yaml' do
  owner 'dd-agent'
  group 'root'
  mode  0644
  notifies :restart, 'service[datadog-agent]'
end
