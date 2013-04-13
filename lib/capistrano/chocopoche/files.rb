# see https://gist.github.com/111597
require 'etc'
require 'fileutils'
require 'capistrano/chocopoche/common'

configuration = Capistrano::Configuration.respond_to?(:instance) ?
  Capistrano::Configuration.instance(:must_exist) :
  Capistrano.configuration(:must_exist)

configuration.load do

  _cset :user,             Etc.getlogin
  _cset :files_rsync,      []
  _cset :files_symlinks,   []
  _cset :files_tmp_dir,    'tmp/capistrano-chocopoche/files'
  _cset :files_tpl,        []
  _cset :files_tpl_params, {}

  namespace :files do

    task :set_tpl_symlinks do
      files_tpl.each do |t|
        set :files_symlinks, files_symlinks + [t[:dest]]
      end
    end

    desc "Creates files from templates and upload them to the app server."
    task :upload_files_from_templates, :roles => :app do

      server 'localhost', :app, :web, :db, :primary => true

      set_files_tpl_params

      files_tpl.each do |t|
        params = fetch(:files_tpl_params)
        template  = File.read(t[:template])
        buffer    = ERB.new(template).result(binding)
        parent = File.dirname("#{shared_path}/#{t[:dest]}")
        run "mkdir -p #{parent}"
        put buffer, "#{shared_path}/#{t[:dest]}", :mode => 0664
      end
    end

    desc <<-DESC
      Sync files from the first web server to the local temp directory. \
      Files on the remote server must be somewhere in the shared directory.
    DESC
    task :download, :roles => :web, :only => { :primary => true }, :once => true do

      host, port = host_and_port

      # Sync each directory
      files_rsync.each do |file_dir|
        source = "#{user}@#{host}:#{shared_path}/#{file_dir}"
        dest   = File.dirname("#{files_tmp_dir}/#{file_dir}")
        FileUtils.mkdir_p(dest)
        system "rsync --archive --compress --copy-links    --delete --stats --rsh='ssh -p #{port}' #{source} #{dest}"
        logger.info "sync files from  #{host}:#{source} to #{dest} finished"
      end

    end

    desc <<-DESC
      Sync files from the local temp directory to the first web server. \
      Files on the remote server will be copied in the shared directory.
    DESC
    task :upload, :roles => :web, :only => { :primary => true }, :once => true do
      host, port = host_and_port
      files_rsync.each do |file_dir|
        source = "#{files_tmp_dir}/#{file_dir}"
        dest   = "#{user}@#{host}:" + File.dirname("#{shared_path}/#{file_dir}")
        system "rsync --archive --compress --keep-dirlinks --delete --stats --rsh='ssh -p #{port}' #{source} #{dest}"
        logger.info "sync files from #{source} to #{host}:#{dest} finished"
      end
    end

    desc <<-DESC
      Creates :files_symlinks from the shared folder to the current one on the \
      app servers. If a file or directory exists as the linkname, it will be \
      removed.
    DESC
    task :create_symlinks, :roles => :app do
      cmds = files_symlinks.collect do | l |
        parent = File.dirname("#{latest_release}/#{l}")
        "mkdir -p #{parent} && rm -rf #{latest_release}/#{l} && ln -nfs #{shared_path}/#{l} #{latest_release}/#{l}"
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

  before 'deploy:finalize_update', 'files:create_symlinks'
  before 'files:create_symlinks',  'files:set_tpl_symlinks'
  after  'deploy:setup',           'files:upload_files_from_templates'
end
