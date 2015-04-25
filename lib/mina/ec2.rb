require 'aws-sdk-v1'
require 'parallel'

module Mina
  class EC2
    attr_accessor :ec2
    attr_reader :tags, :project_tag

    def initialize(tags, project_tag, settings)
      @tags = tags
      @project_tag = project_tag

      @ec2 = {}
      settings[:regions].each do |region|
        @ec2[region] = ec2_connect(
          region: region,
          access_key_id: settings[:access_key_id],
          secret_access_key: settings[:secret_access_key]
        )
      end
    end

    def ec2_connect(region: nil, access_key_id:, secret_access_key:)
      AWS.start_memoizing
      AWS::EC2.new(
        access_key_id: access_key_id,
        secret_access_key: secret_access_key,
        region: region
      )
    end

    def get_servers
      servers = []
      @ec2.each do |_, ec2|
        instances = ec2.instances
          .filter(tag(project_tag), "*#{project}*")
          .filter('instance-state-name', 'running')
        servers << instances.select do |i|
          verify_instance_tags(i)
        end
      end
      servers.flatten.sort_by {|s| s.tags["Name"] || ''}
    end

    def get_domain(instance)
      instance.public_dns_name || instance.public_ip_address || instance.private_ip_address
    end

    def tag(tag_name)
      "tag:#{tag_name}"
    end

    def project
      tags[project_tag]
    end

    private
    def get_regions(regions=nil)
      unless regions.nil? || regions.empty?
        return regions
      else
        @ec2 = ec2_connect
        @ec2.regions.map(&:name)
      end
    end

    def verify_instance_tags(instance)
      missing = []

      @tags.each do |name, value|
        missing << name unless (instance.tags[name.to_s.capitalize] || '').split(',').map(&:strip).include?(value.to_s)
      end

      missing.empty?
    end
  end
end

namespace :ec2 do
  task :get_domains do
    mec2 = Mina::EC2.new(
      fetch(:ec2_tags),
      fetch(:ec2_project_tag, 'Project'),
      fetch(:ec2_settings)
    )

    set :ec2_domains, mec2.get_servers.inject([]) { |memo, instance| memo << mec2.get_domain(instance) }
  end

  task :setup do
    to :before_hook do
      invoke :'ec2:get_domains'
    end

    isolate do
      Parallel.each(fetch(:ec2_domains)) do |domain|
        set :domain, domain
        invoke :setup
        run!
      end
    end
  end

  task :deploy do
    to :before_hook do
      invoke :'ec2:get_domains'
    end

    isolate do
      Parallel.each(fetch(:ec2_domains)) do |domain|
        set :domain, domain
        invoke :deploy
        run!
      end
    end
  end
end
