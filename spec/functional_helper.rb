require 'jugaad'
require 'mixlib/shellout'
require 'chef_zero/server'
require 'ohai'
require 'zlib'
require 'json'
require 'chef/rest'
require 'chef/config'


require 'spec_helper'

# append library dir in load path
$: << File.expand_path("../../lib" ,  __FILE__)

require 'pagerduty/restore'


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
      $server ||= begin
                    puts "Starting chef zero"
                    s=ChefZero::Server.new(port: 4000, host: local_ipv4)
                    s.start_background
                    s
                  end
    end

    def stop_chef_zero
      if $server
        puts "Stopping chef zero"
        $server.stop
        $server = nil
      end
    end

    def populate_chef_zero
      upload_git_artifacts
      #upload_chef_server_backup
    end

    def upload_git_artifacts
      puts ("Uploading git artifacts to ")
      command = 'bundle exec ./restore_chef.sh -c tmp/.chef/knife.rb'
      c = Mixlib::ShellOut.new(command)
      c.cwd = repo_root
      c.live_stream = $stdout
      c.run_command
      raise c.stderr unless c.exitstatus == 0
    end

    def upload_chef_server_backup
      c = knife_command("pd chef restore -f #{backup_file}")
      c.live_stream = $stdout
      c.run_command
      raise c.stderr unless c.exitstatus == 0
    end

    def knife_command(command)
      puts ("Building knife command: #{command}")
      c = Mixlib::ShellOut.new("bundle exec knife #{command} -c tmp/.chef/knife.rb")
      c.cwd = repo_root
      c
    end

    def backup_file
      ENV['BACKUP_FILE'] || File.join(repo_root, '.chef/backup.json.tgz')
    end

    def restore_backup
      config = { backup_file: backup_file,
                 black_list: ['admin', 'chef-validator', 'chef-webui'],
                 chef_server_url: chef_zero_url }
      tool = PagerDuty::ChefServer::Restore.new(config, Chef::Log)
      tool.run
    end

    def chef_zero_url
      "http://#{local_ipv4}:4000/"
    end

    def chef_secret_file
      ENV['BACKUP_FILE'] || File.join(repo_root, '/tmp/.chef/secret')
    end


    def create_knife_config
      puts "Creating temporary knife config file"
      FileUtils.mkdir_p(repo_root + '/tmp/.chef/cache')
      knife_config = <<-EOF
        current_dir = File.expand_path('../', __FILE__)
        log_level                :info
        log_location             STDOUT
        node_name                'admin'
        client_key               "#{repo_root + '/spec/client.pem'}"
        validation_key           "#{repo_root + '/spec/validation.pem'}"
        validation_client_name   'chef-validator'
        encrypted_data_bag_secret '#{chef_secret_file}'
        chef_server_url           '#{chef_zero_url}'
        cache_type               'BasicFile'
        cache_options( :path => File.join(current_dir, 'cache'))
      EOF
      File.open(repo_root + '/tmp/.chef/knife.rb','w') do |f|
        f.write(knife_config)
      end
    end

    def delete_knife_config
      puts "Deleting temporary knife config file"
      FileUtils.rm_rf(repo_root + '/tmp/.chef')
    end

    def create_container(name)
      puts "Creating container named: #{name}"
      c = LXC::Container.new(name)
      c.ssh_user = 'ubuntu'
      c.ssh_password = 'ubuntu'
      c.create(template: 'ubuntu', template_dir: '/usr/share/lxc/templates')
      c.start
      sleep 15 # wait for ip allocation by dnsmasq
      c.ssh!(:command => 'sudo apt-get install -y curl') # bootstrap requires curl
      c
    end
    
    def destroy_container(name)
      c = LXC::Container.new(name)
      if c.running?
        puts "Destroying container named: #{name}"
        c.stop
        c.destroy
      else
        puts "Skipped destroying container named: #{name}"
      end
    end

    def perform_teardown(name)
     #c =  knife_command("pd teardown #{name} -y ")
     #c.live_stream=$stdout
     #c.run_command
    end

    def cookbook_paths
      cookbook_paths = []
      %w{vendor site-cookbooks cookbooks }.each do |path|
        cookbook_paths <<  File.expand_path("../../" + path,  __FILE__)
      end
      cookbook_paths
    end

    def data_bag_paths
      Array(File.expand_path("../../data_bags" ,  __FILE__))
    end

    def role_paths
      Array(File.expand_path("../../roles" ,  __FILE__))
    end

    def repo_root
      File.expand_path("../../" ,  __FILE__)
    end

    def vm(name)
      c = LXC::Container.new(name)
      c.ssh_user = 'ubuntu'
      c.ssh_password = 'ubuntu'
      c
    end
  end
end

RSpec.configure do |config|
  config.treat_symbols_as_metadata_keys_with_true_values = true
  config.run_all_when_everything_filtered = true
  config.fail_fast = true
  config.filter_run :focus
  config.include PagerDuty::FunctionalHelper

  config.before(:all) do
    start_chef_zero
    create_knife_config
    populate_chef_zero
  end

  config.after(:all) do
    stop_chef_zero
    delete_knife_config
  end
end
