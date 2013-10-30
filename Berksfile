# -*- ft:ruby -*-
site :opscode
cookbook 'memcached'
cookbook 'datadog'
cookbook 'sumologic', github: 'PagerDuty/chef-sumologic'

site_cookbooks_path = File.expand_path('../site-cookbooks', __FILE__)

Dir["#{site_cookbooks_path}/**"].each do |cookbook_path|
  cookbook File.basename(cookbook_path), path: cookbook_path
end
