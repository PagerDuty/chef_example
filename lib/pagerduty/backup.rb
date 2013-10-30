module PagerDuty
  module ChefServer
    class BackUp
      
      attr_reader :config, :log

      def initialize(config, log)
        require 'aws-sdk'
        @config = config
        @log = log
      end

      def run
        t_start = Time.now
        log.info("Starting backup")
        take_backup
        log.info("Backup data genarated")
        write_backup 
        log.info("Backup data written in local cache")
        if config[:upload]
          upload_to_s3
          log.info("Uploaded on S3!")
        else
          log.info("Not uploading to s3")
        end
        t_end = Time.now
        unless config[:keep_cache]
          log.info("Deleting the cache")
          File.unlink(config[:cache_file])
        end
        log.info("Backup completed it in #{t_end - t_start} seconds")
      end

      def take_backup
        @backup ||= begin

          nodes = []            
          log.info(" Backing up nodes")
          Chef::Node.list.keys.each do |n| 
            log.info("  Loading node #{n}")
            nodes <<  Chef::Node.load(n).to_json
          end

          log.info(" Backing up clients")
          clients = []
          Chef::ApiClient.list.keys.each do |c| 
            log.info("  Loading client #{c}")
            clients << Chef::ApiClient.load(c)
          end

          log.info(" Backing up databags")
          data_bags = Hash.new{|h,k|h[k]={}}
          Chef::DataBag.list.keys.reject{|n| n == 'users'}.each do |dbag|
            log.info("   Loading data bag #{dbag}")
            Chef::DataBag.load(dbag).keys.each do |item|
              log.info("   Loading data bag item #{item}")
              data_bags[dbag][item] = Chef::DataBagItem.load(dbag, item).to_json
            end
          end
          {:nodes=>nodes, :clients=>clients, :data_bags=>data_bags}
        end
        @backup
      end

      def write_backup
        json_backup = Chef::JSONCompat.to_json(take_backup)
        log.info("JSON conversion done, backup size before compression: #{json_backup.size}")
        compressed_backup = Zlib::Deflate.deflate(json_backup)
        log.info("Zlib compression done, backup size after compression: #{compressed_backup.size}")
        File.open(config[:cache_file],'w') do |f|
          f.write(compressed_backup)
        end
        log.info("Backup cached at: #{config[:cache_file]}")
        true
      end

      def upload_to_s3
        time_stamp = Time.now.strftime('%4Y_%2m_%2d_%2H')
        fname = if config[:file_name] 
                  config[:file_name]
                else
                  'backup_' + time_stamp + '.json.gz'
                end
        key = config[:directory]+'/' + fname
        log.info("Uploading file #{config[:cache_file]} to bucket #{config[:bucket]} with name #{key}")
        obj = s3object(config[:bucket], key)
        obj.write(:file => config[:cache_file])
      end

      def s3object(bucket, key)
        AWS.config(:access_key_id     => Chef::Config[:knife][:aws_access_key_id], 
                   :secret_access_key => Chef::Config[:knife][:aws_secret_access_key])
        s3 = AWS::S3.new
        s3.buckets[bucket].objects[key]
      end
    end
  end
end
