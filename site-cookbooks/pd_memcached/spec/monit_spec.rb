require 'spec_helper'

describe "pd_memcached::monit" do

  before do
    Chef::Log.stub(:warn)
  end

  def runner 
    memoized_runner "pd_memcached::monit"
  end

  it "should converge at least" do
    expect(runner).to_not be_nil
  end

  it "should include the monit recipe" do
    expect(runner).to include_recipe("monit")
  end

  it "should create memcached specfic monit config" do
    expect(runner).to create_template('/etc/monit/conf.d/pd_memcached_monit.conf').with(
    variables: {},
    cookbook: 'monit'
    )
  end
end
