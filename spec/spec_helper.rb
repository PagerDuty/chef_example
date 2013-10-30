
require 'chefspec'
require 'fauxhai'

# append repo home in load path
$:.unshift(File.expand_path("../..",  __FILE__))
$:.unshift(File.expand_path("../../site-cookbooks",  __FILE__))

module PagerDuty
  module SpecHelper

    def pd_cookbook_paths
      cookbook_paths = []
      %w{vendor site-cookbooks cookbooks }.each do |path|
        cookbook_paths <<  File.expand_path("../../" + path,  __FILE__)
      end
      cookbook_paths
    end

    def pd_chef_repo
      File.expand_path("../../",  __FILE__)
    end

    def pd_data_bag_paths
      Array(File.expand_path("../../data_bags" ,  __FILE__))
    end

    def pd_role_paths
      Array(File.expand_path("../../roles" ,  __FILE__))
    end

    def mock_node(name, options = {})
      n = Chef::Node.new
      n.name(name)
      n.set[:tags] = Array(options.delete(:tags))
      n.automatic_attrs = options
      n
    end

    def  memoized_runner(recipe, options={})
      @runner ||= begin
                    runner = ChefSpec::Runner.new(options)
                    yield runner.node if block_given?
                    runner.converge(recipe)
                    runner
                  end
    end
  end
end

Chef::Config[:http_retry_count] = 0
RSpec.configure do |config|
  config.version = '12.04'
  config.platform = 'ubuntu'
  config.cookbook_path =  %w{vendor site-cookbooks}.map{|p| File.expand_path("../../" + p,  __FILE__)}
  config.role_path = Array(File.expand_path("../../roles" ,  __FILE__))
  config.treat_symbols_as_metadata_keys_with_true_values = true
  config.run_all_when_everything_filtered = true
  config.filter_run :focus
  config.include PagerDuty::SpecHelper
end
