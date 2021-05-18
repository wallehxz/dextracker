# Load DSL and set up stages
require 'capistrano/setup'

# Include default deployment tasks
require 'capistrano/deploy'

# Include tasks from other gems included in your Gemfile
#
# For documentation on these, see for example:
#
#   https://github.com/capistrano/rvm
#   https://github.com/capistrano/rails
#   https://github.com/capistrano/bundler
#   https://github.com/capistrano/passenger
#

require 'capistrano/rvm'
require 'capistrano/puma'
require 'capistrano/scm/git'
require 'capistrano/bundler'
require 'whenever/capistrano'
require 'capistrano/rails/assets'
require 'capistrano/rails/migrations'

install_plugin Capistrano::Puma
install_plugin Capistrano::SCM::Git
install_plugin Capistrano::Puma::Daemon

# Load custom tasks from `lib/capistrano/tasks` if you have any defined
Dir.glob('lib/capistrano/tasks/*.rake').each { |r| import r }
