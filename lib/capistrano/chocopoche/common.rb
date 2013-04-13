configuration = Capistrano::Configuration.respond_to?(:instance) ?
  Capistrano::Configuration.instance(:must_exist) :
  Capistrano.configuration(:must_exist)


configuration.load do

  _cset :user, Etc.getlogin

  # Used to create relative symlinks in deploy.create_symlink
  def relative_path(from_str, to_str)
    require 'pathname'
    Pathname.new(to_str).relative_path_from(Pathname.new(from_str)).to_s
  end

  # https://github.com/everzet/capifony/blob/c32d2ae118584d37e9051b6eeda0674ea420f824/lib/capifony.rb
  def prompt_with_default(var, default, &block)
    set(var) do
      Capistrano::CLI.ui.ask("#{var} [#{default}] : ", &block)
    end
    set var, default if eval("#{var.to_s}.empty?")
  end

  desc <<-DESC
    Connects via SSH to the first app server, and executes a `bash --login` \
    to stay connected
  DESC
  task :connect, :roles => :app, :primary => true do
    set :host, roles[:app].servers.first.host
    set :port, ssh_options[:port] || roles[:web].servers.first.port || 22
    set :user, Etc.getlogin unless exists?(:user)

    cmd = "ssh -A #{user}@#{host} -p #{port} -t \"cd #{current_path};bash --login\""
    exec(cmd)
  end
end
