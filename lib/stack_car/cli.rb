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
    method_option :build, default: true, type: :boolean, aliases: '-b'
    desc "up", "starts docker-compose with rebuild and orphan removal, defaults to web"
    def up
      args = ['--remove-orphans']
      args << '--build' if options[:build]

      run("docker-compose up #{args.join(' ')} #{options[:service]}")
    end

    method_option :service, default: '', type: :string, aliases: '-s'
    desc "stop", "starts docker-compose with rebuild and orphan removal, defaults to all"
    def stop
      run("docker-compose stop #{options[:service]}")
      rum("rm -rf tmp/pids/*")
    end

    method_option :service, default: 'web', type: :string, aliases: '-s'
    desc "build", "build the services, defaults to web"
    def build
      @project_name = File.basename(File.expand_path(dir))
      run("docker-compose build #{options[:service]}")
      run("docker cp #{@project_name}_#{options[:service]}_1:/bundle .")
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
      registry = "#{ENV['REGISTRY_HOST']}#{ENV['REGISTRY_URI']}"
      run("docker login #{ENV['REGISTRY_HOST']}")
      run("docker tag #{registry} #{registry}:#{environment}-#{Time.now.strftime("%Y%m%d%I%M%S")}")
      run("docker push #{registry}:#{environment}-#{Time.now.strftime("%Y%m%d%I%M%S")}")
      run("docker tag #{registry} #{registry}:#{environment}-latest")
      run("docker push #{registry}:#{environment}-latest")
    end

    desc "provision ENVIRONMENT", "configure the servers for docker and then deploy an image"
    def provision(environment)
      run("cd ops && ansible-playbook -i hosts -l #{environment} provision.yml")
    end

    desc "deploy ENVIRONMENT", "deploy an image from the registry"
    def deploy(environment)
      run("cd ops && ansible-playbook -i hosts -l #{environment} deploy.yml")
    end

    method_option :elasticsearch, default: false, type: :boolean, aliases: '-e'
    method_option :solr, default: false, type: :boolean, aliases: '-s'
    method_option :postgres, default: false, type: :boolean, aliases: '-p'
    method_option :mysql, default: false, type: :boolean, aliases: '-m'
    method_option :redis, default: false, type: :boolean, aliases: '-r'
    method_option :fcrepo, default: false, type: :boolean, aliases: '-f'
    method_option :deploy, default: false, type: :boolean, aliases: '-d'
    method_option :rancher, default: false, type: :boolean, aliases: '-dr'
    method_option :sidekiq, default: false, type: :boolean, aliases: '-sq' # TODO
    method_option :mongodb, default: false, type: :boolean, aliases: '-mg' # TODO
    desc 'dockerize DIR', 'Will copy the docker tempates in to your project, see options for supported dependencies'
    long_desc <<-DOCKERIZE

    `sc dockerize OPTIONS .` will create a set of docker templates to set up a project with docker

    Pick your dependencies by using the command line arguments
    DOCKERIZE
    def dockerize(dir=nil)
      if dir
        Dir.chdir(dir)
      else
        dir = '.'
      end
     @project_name = File.basename(File.expand_path(dir))
     @db_libs = []
     @db_libs << "libpq-dev postgresql-client" if options[:postgres]
     @db_libs << "mysql-client" if options[:mysql]
     @db_libs << "libc6-dev libreoffice imagemagick unzip" if options[:fcrepo]
     @db_libs = @db_libs.join(' ')


      ['.dockerignore', 'Dockerfile', 'docker-compose.yml', 'docker-compose-prod.yml', '.gitlab-ci.yml', '.env'].each do |template_file|
        template("#{template_file}.erb", template_file)
      end
      directory('bundle')
      if options[:deploy] || options[:rancher]
        directory('ops')
        ['hosts'].each do |template_file|
          template("#{template_file}.erb", "ops/#{template_file}")
        end
        say 'Please update ops/hosts with the correct server addresses'
      end
    end
  end
end
