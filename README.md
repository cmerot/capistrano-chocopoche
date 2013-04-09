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
# set :deploy_to,               '/home/#{user}/apps/#{application}[.#{stage}]'
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

The `download` and `upload` tasks use a temporary directory as pivot, so you are
able to sync stages together.

The following scenario assumes that all commands are launch from the dev stage,
and that you have 3 environements:

- dev: may only contains the cap recipe
- staging: a stage without files and symlinks
- prod: a stage with files and symlinks. Prod looks like:

        my-project.prod/
        ├── current/
        │   └── public/
        │       └── upload/         => symlink to my-project/shared/public/upload/
        └── shared/
            └── public/
                └── upload/         => git ignores that folder
                    ├── file1.png
                    ├── file2.png
                    ...

`cap prod files:download` would download `prod:my-project/shared/public/upload`
to `dev:my-project/tmp/capistrano-chocopoche/files/public/upload`:

    my-project.dev/
    ├── current/
    ├── shared/
    └── tmp/
        └── capistrano-chocopoche/
            └── files/
                └── public/
                    └── upload/
                        ├── file1.png
                        ├── file2.png
                        ...

2. `cap dev files:upload` would produce

And finally, a `cap dev files:create_symlinks` woud produce

    my-project.dev/
    ├── current/
    │   └── public/
    │       └── upload/         => symlink to my-project/shared/public/upload/
    ├── shared/
    │   └── public/
    │       └── upload/         => git ignores that folder
    │           ├── file1.png
    │           ├── file2.png
    │           ...
    └── tmp/
        └── capistrano-chocopoche/
            └── files/
                └── public/
                    └── upload/
                        ├── file1.png
                        ├── file2.png
                        ...


## License

MIT, see the license file.
