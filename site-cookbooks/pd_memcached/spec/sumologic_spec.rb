require 'spec_helper'

describe "pd_memcached::sumologic" do

  before do
    Chef::Log.stub(:warn)
  end

  def runner 
    memoized_runner "pd_memcached::sumologic"
  end

  it "should include the sumologic recipe" do
    expect(runner).to include_recipe("sumologic")
  end

  it "should setup sumologic memcache log integration" do
    expect(runner).to create_sumo_source("memcached").with(
      path: '/var/log/memcached.log',
      category: 'memcached'
    )
  end
end
