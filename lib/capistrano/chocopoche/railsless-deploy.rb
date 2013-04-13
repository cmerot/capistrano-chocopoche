require 'capistrano/chocopoche/common'

configuration = Capistrano::Configuration.respond_to?(:instance) ?
  Capistrano::Configuration.instance(:must_exist) :
  Capistrano.configuration(:must_exist)


configuration.load do

  # Remove rails specific tasks
  deploy.tasks.delete(:cold)
  deploy.tasks.delete(:migrate)
  deploy.tasks.delete(:migrations)

  # Remove rails specific vars
  unset :rails_env

  # Empty shared children
  set :shared_children, []

  # Override `deploy to` to a more common path
  if exists?(:stages)
    set(:deploy_to) { "/home/#{user}/apps/#{application}.#{stage}" }
  else
    set(:deploy_to) { "/home/#{user}/apps/#{application}" }
  end

  namespace :deploy do

    desc <<-DESC
      Updates the symlink to the most recently deployed version. Capistrano works \
      by putting each new release of your application in its own directory. When \
      you deploy a new version, this task's job is to update the `current' symlink \
      to point at the new version. You will rarely need to call this task \
      directly; instead, use the `deploy' task (which performs a complete \
      deploy, including `restart') or the 'update' task (which does everything \
      except `restart').
    DESC
    task :create_symlink, :except => { :no_release => true } do
      on_rollback do
        if previous_release
          previous_release_relative = relative_path(deploy_to, previous_release)
          run "ln -nfs #{previous_release_relative} #{current_path}"
        else
          logger.important "no previous release to rollback to, rollback of symlink skipped"
        end
      end
      latest_release_relative = relative_path(deploy_to,latest_release)
      run "ln -nfs #{latest_release_relative} #{current_path}"
    end

    desc <<-DESC
      [internal] This is called by update_code after the basic deploy \
      finishes.
    DESC
    task :finalize_update, :except => { :no_release => true } do
    end
  end

  namespace :rollback do
    desc <<-DESC
      [internal] Points the current symlink at the previous revision.
      This is called by the rollback sequence, and should rarely (if
      ever) need to be called directly.
    DESC
    task :revision, :except => { :no_release => true } do
      if previous_release
        previous_release_relative = relative_path(deploy_to, previous_release)
        run "ln -nfs #{previous_release_relative} #{current_path}"
      else
        abort "could not rollback the code because there is no prior release"
      end
    end
  end
end
