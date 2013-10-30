module PagerDuty
  module ChefServer
    class Restore
      
      attr_reader :config, :log

      def initialize(config, log)
        @config = config
        @log = log
      end

      def read_backup(file=config[:backup_file])
        raise "Please provide backup file " unless file
        content = Zlib::Inflate.inflate( File.read(file))
        JSON.parse(content)
      end

      def run
        t_start = Time.now
        log.info("Starting restore")
        log.info("Parsing backup file")
        backup = read_backup
        log.info("Restoring nodes")
        backup['nodes'].each do |node_json|
         save_node(node_json)
        end
        log.info("Restoring clients")
        backup["clients"].each do |client_hash|
          save_client(client_hash)
        end
        log.info("Restoring databags")
        backup["data_bags"].each do |dbag_name, dbag_hash|
          save_data_bag(dbag_name, dbag_hash)
        end
      end
      
      def save_node(node_json)
        node = Chef::JSONCompat.from_json(node_json)
        node.save
        log.info("Restored #{node.name}")
      end

      def save_client(client_hash)
        client = Chef::ApiClient.json_create(client_hash)
        if config[:black_list].include?(client.name)
          log.warn("Skipping black listed client #{client.name}")
        else
          if existing_clients.include?(client.name)
            log.warn("ApiClient for #{client.name} is already present, will be destroyed")
            Chef::ApiClient.load(client.name).destroy
          end 
          url = rest.create_url('/clients')
          Chef::ChefFS::RawRequest.api_request(rest, :post, url, {}, client_hash.to_json)
          log.info("ApiClient #{client.name} restored on #{Chef::Config[:chef_server_url]}")
        end
      end

      def existing_clients
        @existing_clients ||= Chef::ApiClient.list.keys
      end

      def save_data_bag(dbag_name, dbag_hash)
        begin
          rest.post_rest("data", { "name" => dbag_name })
          log.info("Created data_bag[#{dbag_name}]")
        rescue Net::HTTPServerException => e
          raise unless e.to_s =~ /^409/
          log.info("Data bag #{@data_bag_name} already exists")
        end
        dbag_hash.each do |dbag_item_name, dbag_item_json|
          item = Chef::JSONCompat.from_json(dbag_item_json)
          item.save
          log.info("Restored data bag item #{item.id}")
        end
      end

      def rest
        @rest ||= begin
          require 'chef/rest'
          Chef::REST.new(Chef::Config[:chef_server_url])
        end
      end
    end
  end
end
