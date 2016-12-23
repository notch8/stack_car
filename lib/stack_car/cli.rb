require 'thor'
require 'erb'
module StackCar
  class HammerOfTheGods < Thor
    include Thor::Actions

    method_option :service, default: 'web', type: :string, aliases: '-s'
    desc "up", "starts docker-compose with rebuild and orphan removal, defaults to web"
    def up
      run("docker-compose up #{options[:service]} --build --remove-orphans")
    end

    method_option :service, default: '', type: :string, aliases: '-s'
    desc "stop", "starts docker-compose with rebuild and orphan removal, defaults to all"
    def stop
      run("docker-compose stop #{options[:service]}")
    end

    method_option :service, default: 'web', type: :string, aliases: '-s'
    desc "run ARGS", "wraps docker-compose exec web unless --service is used to specify"
    def run(args)
      run("docker-compose run #{options[:service]} #{args}")
    end

    method_option :service, default: 'web', type: :string, aliases: '-s'
    desc "exec ARGS", "wraps docker-compose exec web unless --service is used to specify"
    def exec(args)
      run("docker-compose exec #{options[:service]} #{args}")
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

    method_option :elasticsearch, default: false, type: :boolean, aliases: '-e'
    method_option :solr, default: false, type: :boolean, aliases: '-s'
    method_option :postgres, default: false, type: :boolean, aliases: '-p'
    method_option :mysql, default: false, type: :boolean, aliases: '-m'
    method_option :redis, default: false, type: :boolean, aliases: '-r'
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
      end
      project_name = File.basename(File.expand_path(dir))
      db_libs = []
      db_libs << "libpq-dev postgresql-client" if options[:postgres]
      db_libs << "mysql-client" if options[:mysql]
      db_libs = db_libs.join(' ')

      template_path = File.join(File.dirname(__FILE__), '..', '..', 'templates')
      ['.dockerignore', 'Dockerfile', 'docker-compose.yml', 'docker-compose-prod.yml', '.gitlab-ci.yml', '.env'].each do |template|

        renderer = ERB.new(File.read(File.join(template_path, template + '.erb')), 0, '-')
        File.write(template, renderer.result(binding))
      end
    end

  end
end
