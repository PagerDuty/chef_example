require 'functional_helper'
require 'net/telnet'

name = "memcached-test"

describe "Executing functional test for: #{name}" do

  before(:all) do
    create_container(name)
  end

  after(:all) do
    perform_teardown(name)
    destroy_container(name)
  end

  it "should bootstrap with #{name}  as run list successfully" do
    c = knife_command("bootstrap #{vm(name).ipv4} -r 'recipe[memcached]' -x ubuntu -P ubuntu --sudo")
    c.live_stream=$stdout
    c.input = "ubuntu\n"
    c.timeout = 1/0.0
    c.run_command
    expect(c.exitstatus).to eq(0)
  end

  it "should show the node's run list" do
    c = knife_command("node show #{name}")
    c.live_stream=$stdout
    c.run_command
    expect(c.exitstatus).to eq(0)
  end

  it "check is port 11411 is responding to version" do
    conn = Net::Telnet::new('Host'=>vm(name).ipv4,  'Port' => 11211,
                       'Telnetmode' => false)
    conn.puts('version')
    version = ""
    conn.waitfor(/./){|data| version << data}
    expect(version).to match /version/i
  end
end
