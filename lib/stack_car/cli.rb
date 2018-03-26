require 'thor'
require 'erb'
require 'dotenv/load'

module StackCar
  class HammerOfTheGods < Thor
    include Thor::Actions

    def self.source_root
      File.join(File.dirname(__FILE__), '..', '..', 'templates')
    end

    method_option :service, default: 'web', type: :string, aliases: '-s'
    method_option :build, default: false, type: :boolean, aliases: '-b'
    method_option :logs, default: true, type: :boolean
    desc "up", "starts docker-compose with rebuild and orphan removal, defaults to web"
    def up
      args = ['--remove-orphans']
      args << '--build' if options[:build]
      if options[:build]
        run("docker-compose pull #{options[:service]}")
      end

      run("docker-compose up #{args.join(' ')} #{options[:service]}")
    end

    method_option :service, default: '', type: :string, aliases: '-s'
    desc "stop", "stops the specified running service, defaults to all"
    def stop
      run("docker-compose stop #{options[:service]}")
      run("rm -rf tmp/pids/*")
    end
    map down: :stop

    method_option :service, default: 'web', type: :string, aliases: '-s'
    desc "build", "builds specified service, defaults to web"
    def build
      run("docker-compose build #{options[:service]}")
    end

    method_option :service, default: 'web', type: :string, aliases: '-s'
    desc "push ARGS", "wraps docker-compose push web unless --service is used to specify"
    def push(*args)
      run("docker-compose push #{options[:service]} #{args.join(' ')}")
    end

    method_option :service, default: 'web', type: :string, aliases: '-s'
    desc "pull ARGS", "wraps docker-compose pull web unless --service is used to specify"
    def pull(*args)
      run("docker-compose pull #{options[:service]} #{args.join(' ')}")
    end

    method_option :service, default: '', type: :string, aliases: '-s'
    desc "ps ARGS", "wraps docker-compose pull web unless --service is used to specify"
    def ps(*args)
      run("docker-compose ps #{options[:service]} #{args.join(' ')}")
    end
    map status: :ps

    method_option :service, default: 'web', type: :string, aliases: '-s'
    desc "bundle ARGS", "wraps docker-compose run web unless --service is used to specify"
    def bundle(*args)
      run("docker-compose exec #{options[:service]} bundle")
    end

    method_option :service, default: 'web', type: :string, aliases: '-s'
    desc "walk ARGS", "wraps docker-compose run web unless --service is used to specify"
    def walk(*args)
      run("docker-compose run #{options[:service]} #{args.join(' ')}")
    end

    method_option :service, default: 'web', type: :string, aliases: '-s'
    desc "exec ARGS", "wraps docker-compose exec web unless --service is used to specify"
    def exec(*args)
      run("docker-compose exec #{options[:service]} #{args.join(' ')}")
    end
    map ex: :exec

    method_option :service, default: 'web', type: :string, aliases: '-s'
    desc "bundle_exec ARGS", "wraps docker-compose exec web bundle exec unless --service is used to specify"
    def bundle_exec(*args)
      run("docker-compose exec #{options[:service]} bundle exec #{args.join(' ')}")
    end
    map be: :bundle_exec

    method_option :service, default: 'web', type: :string, aliases: '-s'
    desc "console ARGS", "shortcut to start rails console"
    def console(*args)
      run("docker-compose exec #{options[:service]} bundle exec rails console #{args.join(' ')}")
    end
    map rc: :console

    desc "release ENVIRONTMENT", "tag and push and image to the registry"
    def release(environment)
      timestamp = Time.now.strftime("%Y%m%d%I%M%S")
      sha = `git rev-parse HEAD`[0-7]
      registry = "#{ENV['REGISTRY_HOST']}#{ENV['REGISTRY_URI']}"
      tag = ENV["TAG"] || 'latest'
      unless File.exists?("#{ENV['HOME']}/.docker/config.json") && File.readlines("#{ENV['HOME']}/.docker/config.json").grep(/#{ENV['REGISTRY_HOST']}/).size > 0
        run("docker login #{ENV['REGISTRY_HOST']}")
      end
      run("docker tag #{registry}:#{tag} #{registry}:#{environment}-#{timestamp}")
      run("docker push #{registry}:#{environment}-#{timestamp}")
      run("docker tag #{registry}:#{tag} #{registry}:#{sha}")
      run("docker push #{registry}:#{sha}")
      run("docker tag #{registry}:#{tag} #{registry}:#{environment}-latest")
      run("docker push #{registry}:#{environment}-latest")
      run("docker tag #{registry}:#{tag} #{registry}:latest")
      run("docker push #{registry}:latest")
    end

    desc "provision ENVIRONMENT", "configure the servers for docker and then deploy an image"
    def provision(environment)
      # TODO make dotenv load a specific environment?
      run("dotenv ansible-playbook -i ops/hosts -l #{environment}:localhost ops/provision.yml")
    end

    desc "ssh ENVIRONMENT", "log in to a running instance - requires PRODUCTION_SSH to be set"
    def ssh(environment)
      target = ENV["#{environment.upcase}_SSH"]
      if target
        run(target)
      else
        say "Please set #{environment.upcase}_SSH"
      end
    end

    desc "deploy ENVIRONMENT", "deploy an image from the registry"
    def deploy(environment)
      run("dotenv ansible-playbook -i ops/hosts -l #{environment}:localhost ops/deploy.yml")
    end

    method_option :elasticsearch, default: false, type: :boolean, aliases: '-e'
    method_option :solr, default: false, type: :boolean, aliases: '-s'
    method_option :postgres, default: false, type: :boolean, aliases: '-p'
    method_option :mysql, default: false, type: :boolean, aliases: '-m'
    method_option :redis, default: false, type: :boolean, aliases: '-r'
    method_option :delayed_job, default: false, type: :boolean, aliases: '-j'
    method_option :fcrepo, default: false, type: :boolean, aliases: '-f'
    method_option :deploy, default: false, type: :boolean, aliases: '-d'
    method_option :heroku, default: false, type: :boolean, aliases: '-h'
    method_option :rancher, default: false, type: :boolean, aliases: '-dr'
    method_option :sidekiq, default: false, type: :boolean, aliases: '-sq' # TODO
    method_option :mongodb, default: false, type: :boolean, aliases: '-mg'
    method_option :memcached, default: false, type: :boolean, aliases: '-mc'
    method_option :yarn, default: false, type: :boolean, aliases: '-y'
    desc 'dockerize DIR', 'Will copy the docker tempates in to your project, see options for supported dependencies'
    long_desc <<-DOCKERIZE

    `sc dockerize OPTIONS .` will create a set of docker templates to set up a project with docker

    Pick your dependencies by using the command line arguments
    DOCKERIZE
    def dockerize(dir=".")
      Dir.chdir(dir)
      @project_name = File.basename(File.expand_path(dir))
      apt_packages << "libpq-dev postgresql-client" if options[:postgres]
      apt_packages << "mysql-client" if options[:mysql]
      pre_apt << "echo 'Downloading Packages'"
      post_apt << "echo 'Packages Downloaded'"

      if options[:yarn]
        apt_packages << 'yarn'
        pre_apt << "curl -sS https://dl.yarnpkg.com/debian/pubkey.gpg | apt-key add -"
        pre_apt << "echo 'deb https://dl.yarnpkg.com/debian/ stable main' | tee /etc/apt/sources.list.d/yarn.list"
        post_apt << "yarn config set no-progress"
        post_apt << "yarn config set silent"
      end

      if options[:fcrepo]
        apt_packages << "libc6-dev libreoffice imagemagick unzip ghostscript ffmpeg"

        post_apt << "mkdir -p /opt/fits"
        post_apt << "curl -fSL -o /opt/fits-1.0.5.zip http://projects.iq.harvard.edu/files/fits/files/fits-1.0.5.zip"
        post_apt << "cd /opt && unzip fits-1.0.5.zip && chmod +X fits-1.0.5/fits.sh"
      end

     ['.dockerignore', 'Dockerfile', 'Dockerfile.base', 'docker-compose.yml', 'docker-compose.ci.yml', 'docker-compose.production.yml', '.gitlab-ci.yml', '.env'].each do |template_file|
       puts template_file
        template("#{template_file}.erb", template_file)
     end
     template("database.yml.erb", "config/database.yml")
     template(".env.development.erb", ".env.development")
     template(".env.erb", ".env.production")

     if File.exists?('README.md')
       prepend_to_file "README.md" do
         File.read("#{self.class.source_root}/README.md")
       end
     else
       create_file "README.md" do
         File.read("#{self.class.source_root}/README.md")
       end
     end
     append_to_file("Gemfile", "gem 'activerecord-nulldb-adapter'")
      if options[:deploy] || options[:rancher]
        directory('ops')
        ['hosts', 'deploy.yml', 'provision.yml'].each do |template_file|
          template("#{template_file}.erb", "ops/#{template_file}")
        end
        say 'Please update ops/hosts with the correct server addresses'
      else
        empty_directory('ops')
      end

      # Do this after we figure out whether to use an empty ops directory or a full one
      ['env.conf', 'webapp.conf', 'worker.sh', 'nginx.sh'].each do |template_file|
        template("#{template_file}.erb", "ops/#{template_file}")
      end

      say 'Please find and replace all CHANGEME lines'
    end

    protected
    def compose_depends(*excludes)
      @compose_depends = []
      services = [:postgres, :mysql, :elasticsearch, :solr, :redis, :mongodb, :memcached] - excludes
      services.each do |service|
        if options[service]
          @compose_depends << "      - #{service}"
        end
      end
      return @compose_depends.join("\n")
    end

    def apt_packages
      @apt_packages ||= []
    end

    def apt_packages_string
      apt_packages.join(" ")
    end

    def pre_apt
      @pre_apt ||= []
    end

    def pre_apt_string
      pre_apt.join(" && \\\n")
    end

    def post_apt
      @post_apt ||= []
    end

    def post_apt_string
      post_apt.join(" && \\\n")
    end

  end
end
