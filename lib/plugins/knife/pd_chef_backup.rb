module PagerDuty
  class PdChefBackup < Chef::Knife

    banner "knife pd chef backup"

    option :cache_file,
      :short =>  '-C CACHE_FILE',
      :long => '--cache-file CACHE_FILE',
      :default => 'backup.json.gz',
      :description => 'Local copy of the file'

    option :keep_cache,
      :short =>  '-K',
      :long => '--keep-cache',
      :default => false,
      :description => 'Keep the local cache file after successfull upload (delete by default)',
      :boolean => true

    option :upload,
      :long => '--upload',
      :description => 'Delete the local cache file after successfull upload',
      :boolean => true

    option :bucket,
      :short =>  '-b S3_BUCKET',
      :long => '--s3-bucket S3_BUCKET',
      :default => 'pd-ops-backup',
      :description => 'S3 Bucket where the file will be stored'

    option :directory,
      :short =>  '-d DIRECTORY',
      :long => '--directory DIRECTORY',
      :default => 'chef01',
      :description => 'Directory inside the bucket'

    option :file_name,
      :short =>  '-d DIRECTORY',
      :long => '--directory DIRECTORY',
      :default => nil,
      :description => 'backup file name'



    deps do
      require 'json'
      require "zlib"
      require 'aws-sdk'
      require 'lib/pagerduty/chef_backup'
    end

    def run
      PagerDuty::ChefServer::BackUp.new(config, ui).run
    end
  end
end
