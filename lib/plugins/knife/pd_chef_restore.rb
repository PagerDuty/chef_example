module PD
  class PdChefRestore < Chef::Knife

    banner "knife pd chef restore -f BACKUP_FILE"

    option :backup_file,
      long: '--backup-file BACKUP_FILE',
      short: '-f BACKUP_FILE',
      description: 'Path of the backup file',
      required: true

    option :black_list,
      long: '--black-list CLIENT1,CLIENT2',
      short: '-b CLIENT1,CLIENT2',
      description: 'Path of the backup file',
      default: ['admin', 'chef-validator', 'chef-webui'],
      proc:  Proc.new{|l| l.split(/\s*,\s*/)}

    deps do
      require 'zlib'
      require 'chef'
      require 'json'
      require 'chef/rest'
      require 'chef/config'
      require 'chef/chef_fs/raw_request'
      require 'lib/pagerduty/chef_restore'
    end

    def run
      raise "Please provide backup file " unless config[:backup_file]
      tool = PagerDuty::ChefServer::Restore.new(config, ui)
      tool.run
    end
  end
end
