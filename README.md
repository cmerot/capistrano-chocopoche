# Capistrano chopoche's recipes

My capistrano poche contains:

- another railsless-deploy recipe
- a files utility to rsync directories

## Installation

    $ gem install capistrano-chocopoche

## Example of a Capfile

```ruby
# Capistrao defaults
load 'deploy'

# Multistage - to be loaded before the railsless-deploy
require 'capistrano/ext/multistage'

# Rails inhibition
require 'capistrano-chocopoche/railsless-deploy'

# Rsync tasks
require 'capistrano-chocopoche/files'

# Base configuration
set :application,   "my-project"
set :repository,    "git@localhost:#{application}.git"
set :use_sudo,      false
ssh_options[:forward_agent] = true

# Rsync + symlinks configuration
set :files_directories,         [ 'public/upload' ]
set :files_symlinks,            [ 'public/upload' ]

# Server config, won't be here in case of multistage
server 'localhost', :app, :web, :db, :primary => true

# # default settings
# set :files_tmp_dir,           'tmp/capistrano-chocopoche/files'
```

## Railsless-deploy

This script requires the default capistrano tasks to be loaded, then it will:

- delete rails tasks: `migrate`, `migrations`, `cold`
- empty rails tasks (but keep it for hooks): `finalize_update`
- delete rails vars: `rails_env`
- empty rails vars: `shared_children`
- override the `deploy_to` var to:

    - `/home/#{user}/apps/#{application}.#{stage}`
    - or `/home/#{user}/apps/#{application}` if the multistage ext is not
      loaded.

  Therefore the multistage ext must be required before the railsless-deploy.

- override symlinks related tasks to use relative paths: create_symlink,
  rollback:revision

The last one implements the atomic symlink as suggested in the
[issue #346](https://github.com/capistrano/capistrano/issues/346).

## Files

The **files:download** task will rsync files from the first web server in
`shared/your/directory` to a local temporary directory `tmp/capistrano-chocopoche/files/your/directory`.

The **files:upload** task will do the opposite of the **files:download** task.

The **files:create_symlinks** creates symlinks from the shared to the current.
The equivalent for the Capfile example:

    $ mkdir -p #{current_path}/public
    $ ln -fs #{shared_path}/public/upload #{current_path}/public

## License

MIT, see the license file.
