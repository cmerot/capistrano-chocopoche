require 'etc'
require 'capistrano-chocopoche/common'

configuration = Capistrano::Configuration.respond_to?(:instance) ?
  Capistrano::Configuration.instance(:must_exist) :
  Capistrano.configuration(:must_exist)


configuration.load do

  # Remove rails specific tasks
  deploy.tasks.delete(:migrate)
  deploy.tasks.delete(:migrations)
  deploy.tasks.delete(:cold)

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

  # Remove rails specific shared children
  # set :shared_children, []

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
          run "ln -s #{previous_release_relative} #{current_path}.tmp && mv -f #{current_path}.tmp #{current_path}"
        else
          logger.important "no previous release to rollback to, rollback of symlink skipped"
        end
      end
      latest_release_relative = relative_path(deploy_to,latest_release)
      run "ln -s #{latest_release_relative} #{current_path}.tmp && mv -f #{current_path}.tmp #{current_path}"
    end

    desc <<-DESC
      [internal] Touches up the released code. This is called by update_code \
      after the basic deploy finishes. It assumes a Rails project was deployed, \
      so if you are deploying something else, you may want to override this \
      task with your own environment's requirements.

      This task will make the release group-writable (if the :group_writable \
      variable is set to true, which is the default). It will then set up \
      symlinks to the shared directory for the log, system, and tmp/pids \
      directories, and will lastly touch all assets in public/images, \
      public/stylesheets, and public/javascripts so that the times are \
      consistent (so that asset timestamping works).  This touch process \
      is only carried out if the :normalize_asset_timestamps variable is \
      set to true, which is the default The asset directories can be overridden \
      using the :public_children variable.
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
        run "ln -s #{previous_release_relative} #{current_path}.tmp && mv -f #{current_path}.tmp #{current_path}"
      else
        abort "could not rollback the code because there is no prior release"
      end
    end
  end
end
