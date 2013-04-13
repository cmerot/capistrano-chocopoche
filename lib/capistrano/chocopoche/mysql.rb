# see https://gist.github.com/111597
require 'fileutils'
require 'yaml'

# Converts deeply keys of a hash|array into symbols when they are strings
# @see http://stackoverflow.com/questions/800122/best-way-to-convert-strings-to-symbols-in-hash#answer-15815545
class Object
  def deep_symbolize_keys
    return self.inject({}){|memo,(k,v)| memo[k.to_sym] = v.deep_symbolize_keys; memo} if self.is_a? Hash
    return self.inject([]){|memo,v    | memo           << v.deep_symbolize_keys; memo} if self.is_a? Array
    return self
  end
end

configuration = Capistrano::Configuration.respond_to?(:instance) ?
  Capistrano::Configuration.instance(:must_exist) :
  Capistrano.configuration(:must_exist)

configuration.load do

  _cset :mysql_backup_dir,  "backup/mysql"
  _cset :mysql_config_file, "config/parameters.yml"
  _cset :mysql_yaml_key,    :databases

  namespace :mysql do

    desc "Dump databases to remote backup folder."
    task :dump, :roles => :db, :only => { :primary => true }, :once => true do
      fetch_databases.each do |db,config|
        db_backup_dir = "#{deploy_to}/#{mysql_backup_dir}/#{db}"
        run "mkdir -p #{db_backup_dir}"

        if exists? :stages
          dump_filename = "%s/%s-%s-%d.sql" % [
            db_backup_dir,
            fetch(:stage),
            config[:dbname],
            Time.now.to_i
          ]
        else
          dump_filename = "%s/%s-%d.sql" % [
            db_backup_dir,
            config[:dbname],
            Time.now.to_i
          ]
        end

        # Dumps the schema
        cmd_schema = "mysqldump -h %s --default-character-set=utf8 --no-data -u%s -p %s > %s" % [
          config[:host],
          config[:user],
          config[:dbname],
          dump_filename
        ]
        begin
          run cmd_schema do |ch, stream, out|
            ch.send_data "#{config[:password]}\n" if out =~ /^Enter password:/
          end
        rescue Capistrano::CommandError => e
          abort("Connection error, you may want to check database config.")
        end

        # Tables to ignore (cache, indexes, ...)
        ignore_tables = ""
        if config.has_key?(:capistrano) && config[:capistrano].has_key?(:ignore_tables)
          # Retrieve tables to ignore and generate the mysqldump arguments
          cmd_ignore_tables = "mysql -h %s --default-character-set=utf8 -u%s -p %s" % [
            config[:host],
            config[:user],
            config[:dbname]
          ]
          cmd_ignore_tables += " -BNe 'show tables;'"
          cmd_ignore_tables += " | grep -E '^#{config[:capistrano][:ignore_tables]}$'"
          cmd_ignore_tables += " | xargs -I {} echo --ignore-table #{config[:dbname]}.{} "

          run cmd_ignore_tables do |ch, stream, out|
            if out =~ /^Enter password:/
              ch.send_data "#{config[:password]}\n"
            else
              ignore_tables += " " + out.chop if out.match(/ignore-table/)
            end
          end
        end

        # Dumps the data
        cmd_data = "mysqldump -h %s --default-character-set=utf8 -u%s -p %s %s >> %s" % [
          config[:host],
          config[:user],
          ignore_tables,
          config[:dbname],
          dump_filename
        ]

        # Executes sql
        run cmd_data do |ch, stream, out|
          ch.send_data "#{config[:password]}\n" if out =~ /^Enter password:/
        end

        # Compress dump
        run "bzip2 #{dump_filename}"
      end
    end

    desc "Import last remote dumps to databases."
    task :import, :roles => :db, :only => { :primary => true }, :once => true do
      fetch_databases.each do |db,config|
        remote_db_backup_dir = "#{deploy_to}/#{mysql_backup_dir}/#{db}"
        last_dump = capture("ls -xt #{remote_db_backup_dir}").split.reverse.last

        # cmd = "mysql -u%s -p\"%s\" %s < %s/%s" % [
        #   config[:user],
        #   config[:password],
        #   config[:dbname],
        #   remote_db_backup_dir,
        #   last_dump
        # ]
        # run cmd do |ch, stream, out|
        #   ch.send_data "#{config[:password]}\n" if out =~ /^Enter password:/
        # end

        run "bzcat #{remote_db_backup_dir}/#{last_dump} | mysql -u%s -p\"%s\" %s" % [
          config[:user],
          config[:password],
          config[:dbname]
        ]
      end
    end

    desc "Download last remote dumps of each databases."
    task :download, :roles => :db, :only => { :primary => true }, :once => true do
      fetch_databases.each do |db,config|
        local_db_backup_dir  = "#{mysql_backup_dir}/#{db}"
        remote_db_backup_dir = "#{deploy_to}/#{mysql_backup_dir}/#{db}"

        # Don't know how to avoid the command error if the remote_db_backup_dir
        # does not exist, other than this way
        begin
          dumps = capture("test -d #{remote_db_backup_dir} && ls -xt #{remote_db_backup_dir}").split.reverse
        rescue Capistrano::CommandError
          logger.important "No dump found!"
        end

        if dumps
          FileUtils.mkdir_p(local_db_backup_dir)
          hostname  = capture("hostname -f").chop
          file_name = "#{local_db_backup_dir}/#{hostname}-#{dumps.last}"
          top.get("#{remote_db_backup_dir}/#{dumps.last}", file_name)
        end
      end
    end

    desc "Upload last local dump of each databases."
    task :upload, :roles => :db, :only => { :primary => true }, :once => true do

      databases = fetch_databases

      databases.each do |db,config|

        local_db_backup_dir  = "#{mysql_backup_dir}/#{db}"
        remote_db_backup_dir = "#{deploy_to}/#{mysql_backup_dir}/#{db}"

        if File.directory?(local_db_backup_dir) && last_dump = `ls -xt #{local_db_backup_dir}`.split.reverse.last
          run "mkdir -p #{remote_db_backup_dir}"
          top.upload("#{local_db_backup_dir}/#{last_dump}", "#{remote_db_backup_dir}/#{last_dump}")
          logger.info "#{last_dump} uploaded."
        else
          logger.important 'No dump found!'
        end
      end
    end

    desc "[internal] Parses the config/databases.yml and returns compatible ones."
    task :fetch_databases, :roles => :db, :only => { :primary => true }, :once => true do
      location = "#{latest_release}/#{mysql_config_file}"

      FileUtils.mkdir_p("config/deploy/tmp")
      top.get(location, "config/deploy/tmp/parameters.yml")
      config = YAML.load_file('config/deploy/tmp/parameters.yml').deep_symbolize_keys
      FileUtils.rm("config/deploy/tmp/parameters.yml")

      databases = config[mysql_yaml_key]
      abort("No database found in #{mysql_config_file}") if databases.nil? || databases.length < 1
      databases.delete_if { |key,value| value[:driver] != 'pdo_mysql' }
      abort("No compatible database found in #{mysql_config_file}") if databases.length < 1

      databases
    end
  end

end
