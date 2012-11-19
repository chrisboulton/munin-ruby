module Munin
  module Parser  
    # Parse a version request
    #
    def parse_version(line)
      if line =~  /^munins node on/
        line.split.last
      else
        raise Munin::InvalidResponse, "Invalid version response"
      end
    end
    
    # Process response
    #
    def process_data(service, lines)
      data = {service => {}}
      lines.each do |line|
        if line =~ /^multigraph /
          service = line.scan(/multigraph (.+)/).flatten[0]
          data[service] = {}
        else
          line = line.split
          key = line.first.split('.value').first
          data[service][key] = line.last
        end
      end

      # Strip empty items
      data.each do |s, v|
        if v.empty?
          data.delete(s)
        end
      end

      data
    end
    
    # Parse 'config' request
    #
    def parse_config(service, data)
      config = {
        service => {'graph' => {}, 'metrics' => {}},
      }
      data.each do |l|
        if l =~ /^multigraph /
          service = l.scan(/multigraph (.+)/).flatten[0]
          config[service] = { 'graph' => {}, 'metrics' => {}}
        elsif l =~ /^graph_/
          key_name, value = l.scan(/^graph_([\w]+)\s(.*)/).flatten
          config[service]['graph'][key_name] = value
        elsif l =~ /^[a-z]+\./
          matches = l.scan(/^([a-z\d\-\_]+)\.([a-z\d\-\_]+)\s(.*)/).flatten
          config[service]['metrics'][matches[0]] ||= {}
          config[service]['metrics'][matches[0]][matches[1]] = matches[2]
        end
      end
      
      # Now, lets process the args hash
      config.each do |name, service|
        if service['graph'].key?('args')
          config[name]['graph']['args'] = parse_config_args(service['graph']['args'])
        end

        if service['graph'].empty?
          config.delete(name)
        end
      end
      
      config
    end
    
    # Parse 'fetch' request
    #
    def parse_fetch(service, data)
      process_data(service, data)
    end
    
    # Detect error from output
    #
    def parse_error(lines)
      if lines.size == 1
        case lines.first
          when '# Unknown service' then raise UnknownService
          when '# Bad exit'        then raise BadExit
        end
      end
    end
    
    # Parse configuration arguments
    #
    def parse_config_args(args)
      result = {}
      args.scan(/--?([a-z\-\_]+)\s([\d]+)\s?/).each do |arg|
        result[arg.first] = arg.last
      end
      {'raw' => args, 'parsed' => result}
    end
  end
end