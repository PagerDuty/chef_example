
require 'lxc'
require 'jugaad'
require 'chef_zero/server'
require 'ohai'

# append repo home in load path
#$:.unshift(File.expand_path("../..",  __FILE__))
#$:.unshift(File.expand_path("../../site-cookbooks",  __FILE__))


module PagerDuty
  module FunctionalHelper

    LXC.use_sudo = true

    def local_ipv4
      @ip||= begin
               o = Ohai::System.new
               o.all_plugins
               o.ipaddress
             end
    end

    def start_chef_zero
      @@server ||= begin
                    s=ChefZero::Server.new(port: 4000, host: local_ipv4)
                    s.start_background
                    s
                  end
    end

    def stop_chef_zero
      @@server.stop
    end

    def populate_chef_zero
      command = 'bundle exec ./restore_chef.sh -c' + pd_repo_root + '/tmp/.chef/knife.rb'
      c = Mixlib::ShellOut.new(command)
      c.cwd = pd_repo_root
      c.live_stream = $stdout
      c.run_command
      raise c.stderr unless c.exitstatus == 0
    end

    def knife_command(command)
      c = Mixlib::ShellOut.new("bundle exec knife #{command} -c #{pd_repo_root + '/tmp/.chef/knife.rb'}")
      c.cwd = pd_repo_root
      c
    end

    def create_knife_config
      FileUtils.mkdir_p(pd_repo_root + '/tmp/.chef/cache')
      knife_config = <<-EOF
      current_dir = File.expand_path('../', __FILE__)
      log_level                :info
      log_location             STDOUT
      node_name                'admin'
      client_key               "#{pd_repo_root + '/spec/client.pem'}"
      validation_key           "#{pd_repo_root + '/spec/validation.pem'}"
      validation_client_name   'chef-validator'

      chef_server_url          'http://#{local_ipv4}:4000/'
      cache_type               'BasicFile'
      cache_options( :path => File.join(current_dir, 'cache'))
      EOF
      File.open(pd_repo_root + '/tmp/.chef/knife.rb','w') do |f|
        f.write(knife_config)
      end
    end

    def delete_knife_config
      FileUtils.rm_rf(pd_repo_root + '/tmp/.chef')
    end

    def create_container(name)
      c = LXC::Container.new(name)
      c.ssh_user = 'ubuntu'
      c.ssh_password = 'ubuntu'
      c.create(:template=>'ubuntu', :template_options=>['-r', 'lucid'])
      c.start
      sleep 15 # wait for ip allocation by dnsmasq
      c.ssh!(:command => 'sudo apt-get install -y curl')
      c
    end
    
    def destroy_container(name)
      c = LXC::Container.new(name)
      c.stop
      c.destroy
    end

    def pd_cookbook_paths
      cookbook_paths = []
      %w{vendor site-cookbooks cookbooks }.each do |path|
        cookbook_paths <<  File.expand_path("../../" + path,  __FILE__)
      end
      cookbook_paths
    end

    def pd_data_bag_paths
      Array(File.expand_path("../../data_bags" ,  __FILE__))
    end

    def pd_role_paths
      Array(File.expand_path("../../roles" ,  __FILE__))
    end

    def pd_repo_root
      File.expand_path("../../" ,  __FILE__)
    end
  end
end
RSpec.configure do |config|
  config.treat_symbols_as_metadata_keys_with_true_values = true
  config.run_all_when_everything_filtered = true
  config.fail_fast = true
  config.filter_run :focus
  config.include PagerDuty::FunctionalHelper
end
