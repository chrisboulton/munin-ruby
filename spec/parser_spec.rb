require 'spec_helper'

class ParseTester
  include Munin::Parser
end

describe Munin::Parser do
  before :each do
    @parser = ParseTester.new
  end
  
  it 'parses version request' do
    @parser.parse_version(fixture('version.txt')).should == '1.4.4'
    
    proc { @parser.parse_version("some other response") }.
      should raise_error Munin::InvalidResponse, "Invalid version response"
  end
  
  it 'parses config request' do
    c = @parser.parse_config('memory', fixture('config.txt').strip.split("\n"))
    c.should be_a Hash
    c['memory'].should be_a Hash
    c['memory']['graph'].should be_a Hash
    c['memory']['graph']['args']['raw'].should == '--base 1024 -l 0 --upper-limit 16175665152'
    c['memory']['graph']['args']['parsed'].should == {
      'base'        => '1024',
      'l'           => '0',
      'upper-limit' => '16175665152',
    }
    c['memory']['metrics'].should be_a Hash
  end

  it 'parses multigraph config request' do
    c = @parser.parse_config('diskstats', fixture('config_multigraph.txt').strip.split("\n"))
    c.should be_a Hash
    c.keys.should include('diskstats_latency', 'diskstats_iops', 'diskstats_latency.sdj', 'diskstats_throughput', 'diskstats_utilization')
    c.keys.should have(5).entries
  end

  it 'parses fetch request' do
    c = @parser.parse_fetch('memory', fixture('fetch.txt').strip.split("\n"))
    c.should be_a Hash
    c['memory'].should be_a Hash
    expected = {
      "active" => "5164363776",
      "swap_cache" => "823296",
      "mapped" => "1625862144",
      "inactive" => "10039930880",
      "cached" => "11967377408",
      "apps" => "1219354624",
      "page_tables" => "27803648",
      "vmalloc_used" => "9228288",
      "free" => "204206080",
      "slab" => "710025216",
      "committed" => "2358927360",
      "buffers" => "2046074880",
      "swap" => "2961408",
    }
    c['memory'].should == expected
  end

  it 'parses multigraph fetch request' do
    c = @parser.parse_fetch('memory', fixture('fetch_multigraph.txt').strip.split("\n"))
    c.should be_a Hash
    expected = {
      "diskstats_throughput.sdj" => {
        "wrbytes" => "610.914914914915",
        "rdbytes" => "979.923923923924",
      },
      "diskstats_utilization.sdj" => {
        "util" => "0.238838838838839",
      },
      "diskstats_iops.sdj" => {
        "wrio" => "0.182182182182182",
        "avgwrrqsz" => "3.27472527472527",
        "avgrdrqsz" => "15.1746031746032",
        "rdio"=>"0.0630630630630631",
      },
    }
    c.should == expected
  end
end
