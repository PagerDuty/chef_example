
include_recipe 'sumologic'

sumo_source "memcached" do
  path  "/var/log/memcached.log"
  category 'memcached'
end
