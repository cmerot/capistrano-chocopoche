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

end
