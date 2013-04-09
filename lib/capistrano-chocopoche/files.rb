# Capistrano recipe to rsync files up and down.
#
# author: Corentin Merot
# real author: Michael Kessler aka netzpirat, see https://gist.github.com/111597

require 'fileutils'
require 'capistrano-chocopoche/common'

configuration = Capistrano::Configuration.respond_to?(:instance) ?
  Capistrano::Configuration.instance(:must_exist) :
  Capistrano.configuration(:must_exist)

configuration.load do

  _cset :user,              Etc.getlogin
  _cset :files_directories, []
  _cset :files_tmp_dir,     'tmp/capistrano-chocopoche/files'

  namespace :files do

    desc <<-DESC
      Sync files from the first web server to the local temp directory. \
      Files on the remote server must be somewhere in the shared directory.
    DESC
    task :download, :roles => :web, :only => { :primary => true }, :once => true do

      host, port = host_and_port

      Array(fetch(:files_directories, [])).each do |file_dir|
        unless File.directory? "#{files_tmp_dir}/#{file_dir}"
          logger.info "create temporary '#{files_tmp_dir}/#{file_dir}' folder"
          FileUtils.mkdir_p "#{files_tmp_dir}/#{file_dir}"
        end

        source = "#{shared_path}/#{file_dir}"
        dest   = File.dirname("#{files_tmp_dir}/#{file_dir}")

        # Sync directory down
        system "rsync --verbose --archive --compress --copy-links --delete --stats --rsh='ssh -p #{port}' #{user}@#{host}:#{source} #{dest}"
        logger.info "sync files from  #{host}:#{source} to #{dest} finished"
      end

    end

    desc <<-DESC
      Sync files from the local temp directory to the first web server. \
      Files on the remote server will be copied in the shared directory.
    DESC
    task :upload, :roles => :web, :only => { :primary => true }, :once => true do

      host, port = host_and_port
      Array(fetch(:files_directories, [])).each do |file_dir|
        source = "#{files_tmp_dir}/#{file_dir}"
        dest   = File.dirname("#{shared_path}/#{file_dir}")

        # Sync directory up
        system "rsync --verbose --archive --compress --keep-dirlinks --delete --stats --rsh='ssh -p #{port}' #{source} #{user}@#{host}:#{dest}"
        logger.info "sync files from #{source} to #{host}:#{dest} finished"
      end
    end

    desc <<-DESC
      Creates :files_symlinks from the shared folder to the current one on the \
      web servers
    DESC
    task :create_symlinks, :roles => [:web] do
      symlinks = fetch(:files_symlinks)
      cmds = symlinks.collect do | l |
        parent = File.dirname("#{current_path}/#{l}")
        "mkdir -p #{parent} && ln -fs #{shared_path}/#{l} #{current_path}/#{l}"
      end
      run cmds.join(' && ')
    end

    #
    # Returns the actual host name to sync and port
    #
    def host_and_port
      return roles[:web].servers.first.host, ssh_options[:port] || roles[:web].servers.first.port || 22
    end

  end
end
