# Capistrano chopoche's recipes

My capistrano poche contains:

- a php composer recipe
- a files utility to rsync directories up and down
- a mysql utility to dump/import, download/upload databases
- a bin to help synchronizing multiple stage together: `csync`
- and a railsless-deploy recipe (which uses the default rails recipes -
  it may not be a good idea to reimplement...)

## Installation

    $ gem install capistrano-chocopoche

## Tasks

```shell
cap composer                          # Runs an arbitrary composer command
cap composer:update                   # Runs the composer update command
cap connect                           # Connects via SSH to the first app server, and executes a `bash --login` to stay connected
cap deploy                            # Deploys your project.
cap deploy:check                      # Test deployment dependencies.
cap deploy:cleanup                    # Clean up old releases.
cap deploy:create_symlink             # Updates the symlink to the most recently deployed version.
cap deploy:pending                    # Displays the commits since your last deploy.
cap deploy:pending:diff               # Displays the `diff' since your last deploy.
cap deploy:restart                    # Blank task exists as a hook into which to install your own environment specific behaviour.
cap deploy:rollback                   # Rolls back to a previous version and restarts.
cap deploy:rollback:code              # Rolls back to the previously deployed version.
cap deploy:setup                      # Prepares one or more servers for deployment.
cap deploy:start                      # Blank task exists as a hook into which to install your own environment specific behaviour.
cap deploy:stop                       # Blank task exists as a hook into which to install your own environment specific behaviour.
cap deploy:symlink                    # Deprecated API.
cap deploy:update                     # Copies your project and updates the symlink.
cap deploy:update_code                # Copies your project to the remote servers.
cap deploy:upload                     # Copy files to the currently deployed version.
cap files:create_symlinks             # Creates :files_symlinks from the shared folder to the current one on the app servers.
cap files:download                    # Sync files from the first web server to the local temp directory.
cap files:upload                      # Sync files from the local temp directory to the first web server.
cap files:upload_files_from_templates # Creates files from templates and upload them to the app server.
cap invoke                            # Invoke a single command on the remote servers.
cap mysql:download                    # Download last remote dumps of each databases.
cap mysql:dump                        # Dump databases to remote backup folder.
cap mysql:import                      # Import last remote dumps to databases.
cap mysql:upload                      # Upload last local dump of each databases.
cap shell                             # Begin an interactive Capistrano session.
```

## Capfile example with multistage

The [short_url](https://github.com/chocopoche/short_url) project uses that
library, it's a good working example. See the `Capfile` and stages config under
`config/deploy`.

The Capfile:

```ruby
# Capistrao defaults
load 'deploy'

require 'capistrano/ext/multistage'
require 'capistrano/chocopoche'

# Base configuration
set :application,   "my-project"
set :repository,    "git@example.com:my-project.git"
set :use_sudo,      false
ssh_options[:forward_agent] = true

# Folders to rsync with files:download
set :files_rsync,    files_rsync    + %w(web/qr)

# Symlinks to create after deploy:update_code
set :files_symlinks, files_symlinks + %w(web/qr)

# # Won't work with the cli command `csync` because the default stage task
# # will be invoked, but it should not
# set :default_stage,  'vm'

# Files to be generated on setup
set :files_tpl, [
  {
    :template => "config/deploy/templates/nginx.conf.erb",
    :dest     => "config/nginx.conf"
  },
  {
    :template => "config/deploy/templates/parameters.yml.erb",
    :dest     => "config/parameters.yml"
  }
]
```

A stage file in `config/deploy/[stage].rb:
```
server 'example.com', :app, :web, :db, :primary => true

def set_files_tpl_params
  set :files_tpl_params, {
    :server   => {
      :hostname => "#{stage}.example.com"
    },
    :database => {
      :driver   => "pdo_mysql",
      :dbname   => "dbname",
      :user     => "user",
      :password => "password",
      :host     => "localhost"
    },
  }
end
```

## Capfile example without multistage

```ruby
# Capistrao defaults
load 'deploy'

require 'capistrano/chocopoche'

# Base configuration
set :application,   "my-project"
set :repository,    "git@example.com:my-project.git"
set :use_sudo,      false
ssh_options[:forward_agent] = true

# Folders to rsync with files:download
set :files_rsync,    files_rsync    + %w(web/qr)

# Symlinks to create after deploy:update_code
set :files_symlinks, files_symlinks + %w(web/qr)

# Files to be generated on setup
set :files_tpl, [
  {
    :template => "config/deploy/templates/nginx.conf.erb",
    :dest     => "config/nginx.conf"
  },
  {
    :template => "config/deploy/templates/parameters.yml.erb",
    :dest     => "config/parameters.yml"
  }
]

server 'localhost', :app, :web, :db, :primary => true

def set_files_tpl_params
  set :files_tpl_params, {
    :server   => {
      :hostname => "#{stage}.example.com"
    },
    :database => {
      :driver   => "pdo_mysql",
      :dbname   => "dbname",
      :user     => "user",
      :password => "password",
      :host     => "localhost"
    },
  }
end
```

## csync

The csync will chain capistrano commands in order to synchronise two stages.
Example:

    $ csync mysql prod dev

will dump and download databases from *prod*, then upload and import them to
*dev*.

    $ csync files prod dev

will rsync files from *prod* to *dev*.

## License

MIT, see the license file.
