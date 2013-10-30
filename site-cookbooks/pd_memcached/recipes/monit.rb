include_recipe 'monit'

monitrc 'pd_memcached_monit' do
  action :enable
end
