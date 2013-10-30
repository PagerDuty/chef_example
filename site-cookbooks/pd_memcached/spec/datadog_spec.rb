require 'spec_helper'

describe "pd_memcached::datadog" do

  before do
    stub_command("apt-cache search datadog-agent | grep datadog-agent").and_return(true)
    Chef::Log.stub(:warn)
  end

  def runner 
    memoized_runner "pd_memcached::datadog" do |node|
      node.set[:datadog][:api_key] = 'foobar'
    end
  end

  it "should include the datadog agent recipe" do
    expect(runner).to include_recipe("datadog::dd-agent")
  end

  it "should install the memcache python package" do
    expect(runner).to install_package('python-memcache')
  end

  it "should create memcached specfic dd plugin config" do
    expect(runner).to create_template('/etc/dd-agent/conf.d/mcache.yaml').with(
      owner: 'dd-agent',
      group: 'root',
      mode: 0644
    )
  end

  it "should restart the datadog agent if the config file is updated" do
    expect(runner.template('/etc/dd-agent/conf.d/mcache.yaml')).to notify('service[datadog-agent]').to(:restart)
  end
end
