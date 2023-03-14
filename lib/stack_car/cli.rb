require 'thor'
require 'erb'
require 'dotenv'
require 'json'
require 'byebug'
module StackCar
  class HammerOfTheGods < Thor
    include Thor::Actions

    def self.source_root
      File.join(File.dirname(__FILE__), '..', '..', 'templates')
    end

    def self.exit_on_failure?
      true
    end

    method_option :service, default: 'web', type: :string, aliases: '-s'
    method_option :build, default: false, type: :boolean, aliases: '-b'
    method_option :logs, default: true, type: :boolean
    desc "up", "starts docker compose with rebuild and orphan removal, defaults to web"
    def up
      setup
      ensure_development_env
      args = ['--remove-orphans']
      args << '--build' if options[:build]
      if options[:build]
        run("#{dotenv} docker compose pull #{options[:service]}")
      end

      run_with_exit("#{dotenv} docker compose up #{args.join(' ')} #{options[:service]}")
    end

    method_option :service, default: '', type: :string, aliases: '-s'
    desc "stop", "stops the specified running service, defaults to all"
    def stop
      setup
      ensure_development_env
      run("#{dotenv} docker compose stop #{options[:service]}")
      run_with_exit("rm -rf tmp/pids/*")
    end

    method_option :volumes, aliases: '-v'
    method_option :rmi
    method_option :'remove-orphans'
    method_option :service, aliases: '-s'
    method_option :timeout, aliases: '-t'
    method_option :all, aliases: '-a'
    method_option :help, aliases: '-h'
    desc 'down', 'stops and removes containers and networks specific to this project by default, run with -h for more options'
    def down
      setup
      ensure_development_env

      if options[:help]
        run('docker compose down --help')
        say 'Additional stack_car options:'
        say '    -a, --all               Removes all containers, networks, volumes, and'
        say '                            images created by `up`.'
        say '    -s, --service           Specify a service defined in the Compose file'
        say '                            whose containers and volumes should be removed.'
        exit(0)
      end

      if options[:service]
        rm_vol = true if options[:volumes]

        remove_container(options[:service], rm_vol)
        exit(0)
      end

      run_conf = 'Running down will stop and remove all of the Docker containers and networks ' \
                 'defined in the docker-compose.yml file. Continue?'
      prompt_run_confirmation(run_conf)

      args = []
      if options[:all]
        prompt_run_confirmation('--all will remove all containers, volumes, networks, local images, and orphaned containers. Continue?')

        args = %w[--volumes --rmi=local --remove-orphans]
      else
        args << '--volumes' if options[:volumes]
        args << '--rmi=local' if options[:rmi]
        args << '--remove-orphans' if options[:'remove-orphans']
        args << '--timeout' if options[:timeout]
      end

      run("#{dotenv} docker compose down #{args.join(' ')}")
      run_with_exit('rm -rf tmp/pids/*')
    end

    method_option :service, default: 'web', type: :string, aliases: '-s'
    desc "build", "builds specified service, defaults to web"
    def build
      setup
      ensure_development_env
      run_with_exit("#{dotenv} docker compose build #{options[:service]}")
    end

    method_option :service, default: 'web', type: :string, aliases: '-s'
    desc "push ARGS", "wraps docker compose push web unless --service is used to specify"
    def push(*args)
      setup
      run_with_exit("#{dotenv} docker compose push #{options[:service]} #{args.join(' ')}")
    end

    method_option :service, default: 'web', type: :string, aliases: '-s'
    desc "pull ARGS", "wraps docker compose pull web unless --service is used to specify"
    def pull(*args)
      setup
      run_with_exit("#{dotenv} docker compose pull #{options[:service]} #{args.join(' ')}")
    end

    method_option :service, default: '', type: :string, aliases: '-s'
    desc "ps ARGS", "wraps docker compose pull web unless --service is used to specify"
    def ps(*args)
      setup
      run_with_exit("#{dotenv} docker compose ps #{options[:service]} #{args.join(' ')}")
    end
    map status: :ps

    method_option :service, default: 'web', type: :string, aliases: '-s'
    desc "bundle ARGS", "wraps docker compose run web unless --service is used to specify"
    def bundle(*args)
      setup
      run_with_exit("#{dotenv} docker compose exec #{options[:service]} bundle")
    end

    method_option :service, default: 'web', type: :string, aliases: '-s'
    desc "walk ARGS", "wraps docker compose run web unless --service is used to specify"
    def walk(*args)
      setup
      run_with_exit("#{dotenv} docker compose run #{options[:service]} #{args.join(' ')}")
    end

    method_option :service, default: 'web', type: :string, aliases: '-s'
    desc "exec ARGS", "wraps docker compose exec web unless --service is used to specify"
    def exec(*args)
      setup
      run_with_exit("#{dotenv} docker compose exec #{options[:service]} #{args.join(' ')}")
    end
    map ex: :exec

    method_option :service, default: 'web', type: :string, aliases: '-s'
    desc 'sh ARGS', "launch a shell using docker compose exec, sets tty properly"
    def sh(*args)
      setup
      run_with_exit("#{dotenv} docker compose exec -e COLUMNS=\"\`tput cols\`\" -e LINES=\"\`tput lines\`\" #{options[:service]} bash #{args.join(' ')}")
    end

    method_option :service, default: 'web', type: :string, aliases: '-s'
    desc "bundle_exec ARGS", "wraps docker compose exec web bundle exec unless --service is used to specify"
    def bundle_exec(*args)
      setup
      run_with_exit("#{dotenv} docker compose exec #{options[:service]} bundle exec #{args.join(' ')}")
    end
    map be: :bundle_exec

    method_option :service, default: 'web', type: :string, aliases: '-s'
    desc "console ARGS", "shortcut to start rails console"
    def console(*args)
      setup
      run_with_exit("#{dotenv} docker compose exec #{options[:service]} bundle exec rails console #{args.join(' ')}")
    end
    map rc: :console

    desc "release ENVIRONTMENT", "tag and push and image to the registry"
    def release(environment)
      Dotenv.load(".env.#{environment}", '.env')
      setup
      timestamp = Time.now.strftime("%Y%m%d%I%M%S")
      sha = `git rev-parse HEAD`[0..8]
      registry = "#{ENV['REGISTRY_HOST']}#{ENV['REGISTRY_URI']}"
      tag = ENV["TAG"] || 'latest'
      unless File.exists?("#{ENV['HOME']}/.docker/config.json") && File.readlines("#{ENV['HOME']}/.docker/config.json").grep(/#{ENV['REGISTRY_HOST']}/).size > 0
        run_with_exit("#{dotenv(environment)} docker login #{ENV['REGISTRY_HOST']}")
      end
      run_with_exit("#{dotenv(environment)} docker tag #{registry}:#{tag} #{registry}:#{environment}-#{timestamp}")
      run_with_exit("#{dotenv(environment)} docker push #{registry}:#{environment}-#{timestamp}")
      run_with_exit("#{dotenv(environment)} docker tag #{registry}:#{tag} #{registry}:#{sha}")
      run_with_exit("#{dotenv(environment)} docker push #{registry}:#{sha}")
      run_with_exit("#{dotenv(environment)} docker tag #{registry}:#{tag} #{registry}:#{environment}-latest")
      run_with_exit("#{dotenv(environment)} docker push #{registry}:#{environment}-latest")
      run_with_exit("#{dotenv(environment)} docker tag #{registry}:#{tag} #{registry}:latest")
      run_with_exit("#{dotenv(environment)} docker push #{registry}:latest")
    end

    desc "provision ENVIRONMENT", "configure the servers for docker and then deploy an image"
    def provision(environment)
      setup
      # TODO make dotenv load a specific environment?
      run_with_exit("DEPLOY_ENV=#{environment} #{dotenv(environment)} ansible-playbook -i ops/hosts -l #{environment}:localhost ops/provision.yml")
    end

    desc "ssh ENVIRONMENT", "log in to a running instance - requires PRODUCTION_SSH to be set"
    def ssh(environment)
      Dotenv.load(".env.#{environment}", '.env')
      setup
      target = ENV["#{environment.upcase}_SSH"]
      if target
        run_with_exit(target)
      else
        say "Please set #{environment.upcase}_SSH"
      end
    end

    desc "deploy ENVIRONMENT", "deploy an image from the registry"
    def deploy(environment)
      setup
      run_with_exit("DEPLOY_HOOK=$DEPLOY_HOOK_#{environment.upcase} #{dotenv(environment)} ansible-playbook -i ops/hosts -l #{environment}:localhost ops/deploy.yml")
    end

    method_option :delayed_job, default: false, type: :boolean, aliases: '-j'
    method_option :deploy, default: false, type: :boolean, aliases: '-d'
    method_option :elasticsearch, default: false, type: :boolean, aliases: '-e'
    method_option :fcrepo, default: false, type: :boolean, aliases: '-f'
    method_option :helm, default: false, type: :boolean, aliases: '-h'
    method_option :git, default: false, type: :boolean, aliases: '-g'
    method_option :heroku, default: false, type: :boolean, aliases: '-h'
    method_option :hyku, default: false, type: :boolean, aliases: "\--hu"
    method_option :imagemagick, default: false, type: :boolean, aliases: '-i'
    method_option :memcached, default: false, type: :boolean, aliases: "\--mc"
    method_option :mongodb, default: false, type: :boolean, aliases: "\--mg"
    method_option :mysql, default: false, type: :boolean, aliases: '-m'
    method_option :postgres, default: false, type: :boolean, aliases: '-p'
    method_option :rancher, default: false, type: :boolean, aliases: "\--dr"
    method_option :redis, default: false, type: :boolean, aliases: '-r'
    method_option :sidekiq, default: false, type: :boolean, aliases: "\--sk"
    method_option :solr, default: false, type: :boolean, aliases: '-s'
    method_option :yarn, default: false, type: :boolean, aliases: '-y'
    desc 'dockerize DIR', 'Will copy the docker tempates in to your project, see options for supported dependencies'
    long_desc <<-DOCKERIZE

    `sc dockerize OPTIONS .` will create a set of docker templates to set up a project with docker

    Pick your dependencies by using the command line arguments
    DOCKERIZE
    def dockerize(dir=".")
      Dir.chdir(dir)
      self.destination_root = dir
      setup
      # Commandline overrides config files
      # options = file_config.merge(options)
      # Sets project name to parent directory name if working with stack_car dir
      @project_name = @sc_dir ? File.basename(File.expand_path('..')) : File.basename(File.expand_path(dir))
      apt_packages << "libpq-dev postgresql-client" if options[:postgres]
      apt_packages << "mysql-client" if options[:mysql]
      apt_packages << "imagemagick" if options[:imagemagick]
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

     ['.dockerignore', 'Dockerfile', 'docker-compose.yml', '.gitlab-ci.yml', '.env'].each do |template_file|
       puts template_file
        template("#{template_file}.erb", template_file)
     end
     directory('.gitlab', '.gitlab')
     template(".env.development.erb", ".env.development")
     template(".env.erb", ".env.production")
     template(".sops.yaml.erb", ".sops.yaml")
     template("decrypt-secrets", "bin/decrypt-secrets")
     template("encrypt-secrets", "bin/encrypt-secrets")
     template("database.yml.erb", "config/database.yml")
     template("development.rb.erb", "config/environments/development.rb")
     template("production.rb.erb", "config/environments/production.rb")

     if options[:solr]
      template("solrcloud-upload-configset.sh", "bin/solrcloud-upload-configset.sh")
      template("solrcloud-assign-configset.sh", "bin/solrcloud-assign-configset.sh")
     end

     if File.exists?('README.md')
       prepend_to_file "README.md" do
         File.read("#{self.class.source_root}/README.md")
       end
     else
       create_file "README.md" do
         File.read("#{self.class.source_root}/README.md")
       end
     end

      if File.exist?('Gemfile')
        append_to_file('Gemfile', "gem 'activerecord-nulldb-adapter'")
      else
        append_to_file('../Gemfile', "gem 'activerecord-nulldb-adapter'", { verbose: false })
        # TODO: remove '../' from message after other status messages are prepended with 'stack_car/'
       append_to_file("../Gemfile", "gem 'pronto', groups: [:development, :test]")
       append_to_file("../Gemfile", "gem 'pronto-rubocop', groups: [:development, :test]")
        say_status(:append, '../Gemfile')
      end

      if options[:deploy] || options[:rancher]
        directory('ops')
        ['hosts', 'deploy.yml', 'provision.yml'].each do |template_file|
          template("#{template_file}.erb", "ops/#{template_file}")
        end

        say 'Please update ops/hosts with the correct server addresses'
      elsif options[:helm]
        directory('chart')
        if options[:fcrepo]
          directory('chart-fcrepo', 'chart/templates')
        end
        if options[:sidekiq]
          directory('chart-sidekiq', 'chart/templates')
        end
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
      services = [:fcrepo, :postgres, :mysql, :elasticsearch, :sidekiq, :solr, :redis, :mongodb, :memcached] - excludes
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

    def run_with_exit(*args)
      result = run(*args)
      if !result
        exit(1)
      end
    end

    def file_config
      path = find_config(Dir.pwd)
      if path
        JSON.parse(File.read(path))
      else
        {}
      end
    end

    def find_config(dir)
      path = File.join(dir, '.stackcar_rc')
      if File.exists?(path)
        return path
      elsif dir == "/"
        return nil
      else
        return find_config(File.dirname(dir))
      end
    end

    def ensure_development_env
      if !File.exists?('.env.development')
        template(".env.development.erb", ".env.development")
      end
    end

    def dotenv(environment='development')
      "dotenv -f .env.#{environment},.env"
    end

    def setup
      if File.exists?('stack_car')
        @sc_dir = true
        Dir.chdir('stack_car')
        self.destination_root += "/stack_car"
      end
      DotRc.new
    end

    def remove_container(service_name, remove_volumes)
      container = find_container_by_service(service_name)

      container.map do |id, name|
        prompt_run_confirmation("Remove #{name} container?")

        if `docker container ls --format "{{.Names}}"`.include?(name)
          say 'Stopping container...'
          `docker stop #{id}`
        end

        say 'Removing container...'
        `docker container rm #{id}`

        # Ensure container was removed
        if `docker ps -aqf id=#{id}`.empty?
          say "  Container #{name} was removed"
        else
          say ">>> There was an issue removing container #{name} (#{id})"
        end
      end

      remove_volumes_mounted_to_container(@container_volume_names) if remove_volumes
    end

    def find_container_by_service(service_name)
      container_id = `docker compose ps -aq #{service_name}`.strip

      if container_id.empty?
        say "Unable to locate a container for the service '#{service_name}'"
        say "Try running `docker compose ps #{service_name}` to make sure the container exists"
        exit(1)
      end

      get_volume_names_for_container(container_id)
      container_name = `docker ps -af id=#{container_id} --format "{{.Names}}"`.strip

      { container_id => container_name }
    end

    def remove_volumes_mounted_to_container(volumes)
      return if volumes.empty?

      prompt_run_confirmation("\n#{volumes.join("\n")}\nRemove these volume(s)?")
      volumes.each do |v|
        say 'Removing volume...'
        `docker volume rm #{v}`

        if `docker volume ls -q`.include?(v)
          say ">>> There was an issue removing volume #{v}"
        else
          say "  Volume #{v} was removed"
        end
      end
    end

    def get_volume_names_for_container(container_id)
      @container_volume_names ||= []
      return @container_volume_names unless @container_volume_names.empty?

      JSON.parse(`docker inspect --format="{{json .Mounts}}" #{container_id}`).map do |mount_info|
        @container_volume_names << mount_info['Name'] if mount_info['Type'] == 'volume'
      end

      @container_volume_names
    end

    def prompt_run_confirmation(question)
      response = ask(question, limited_to: %w[y n])
      exit(1) unless response == 'y'
    end
  end
end
