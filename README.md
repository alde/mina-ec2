# Mina EC2
Helper library to deploy to several EC2 instances using Mina

## Installing

Add to gemfile:

    gem 'mina-ec2'

Add to config/deploy.rb

    require 'mina/ec2'

## Configuration
### AWS Credentials
Set AWS credentials to use, and which region(s) to deploy to.

    set :ec2_settings, {
      regions: %w{eu-west-1},
      access_key_id: ENV['AWS_ACCESS_KEY_ID'],
      secret_access_key: ENV['AWS_SECRET_ACCESS_KEY_ID']
    }

### Filtering instance
Set tags to find your instances by:

    set :ec2_tags, {
      'Team' => 'my-team',
      'Project' => 'my-app',
      'Stages' => 'staging'
    }

### Migrations
Split out the `rails:db_migrate` invocation, since we don't want to run it from several servers. If you do want to run it from several servers (for example if each of your app servers has their own sqlite3 database), just leave it as a part of the `deploy {}` block.

    desc "Deploys the current version to the server."
    task :deploy => :environment do
      deploy do
        invoke :'git:clone'
        invoke :'deploy:link_shared_paths'
        invoke :'bundle:install'
        invoke :'rails:assets_precompile'
        invoke :'deploy:cleanup'
    
        to :launch do
          queue "mkdir -p #{deploy_to}/#{current_path}/tmp/"
          queue "touch #{deploy_to}/#{current_path}/tmp/restart.txt"
        end
      end
    
      set :domain, fetch(:ec2_domains).sample
      invoke :'rails:db_migrate'
    end

