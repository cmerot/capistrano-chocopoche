require 'capistrano/chocopoche/files'

configuration = Capistrano::Configuration.respond_to?(:instance) ?
  Capistrano::Configuration.instance(:must_exist) :
  Capistrano.configuration(:must_exist)


configuration.load do

  set :shared_children, shared_children + %w(vendor)
  set :files_symlinks,  files_symlinks  + %w(vendor)

  _cset :composer_cli_options, '--dev --quiet'

  namespace :composer do

    desc "Runs an arbitrary composer command"
    task :default, :roles => :app do
      prompt_with_default(:composer_task, "update")
      run "cd #{latest_release} && php composer.phar #{composer_cli_options} " + composer_task
    end

    desc "Runs the composer update command"
    task :update, :roles => :app do
      install_composer
      run "cd #{latest_release} && php composer.phar #{composer_cli_options} update"
    end

    desc "[internal] Installs composer"
    task :install_composer, :roles => :app do
      run "curl -s http://getcomposer.org/installer | php -- --install-dir=#{current_release}"
    end
  end

  # before 'deploy:finalize_update', 'composer:update'
end
