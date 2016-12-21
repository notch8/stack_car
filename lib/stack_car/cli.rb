require 'thor'
module StackCar
  class HammerOfTheGods < Thor
    desc "hello NAME", "This will greet you"
    long_desc <<-HELLO_WORLD

    `hello NAME` will print out a message to the person of your choosing.

    Brian Kernighan actually wrote the first "Hello, World!" program 
    as part of the documentation for the BCPL programming language 
    developed by Martin Richards. BCPL was used while C was being 
    developed at Bell Labs a few years before the publication of 
    Kernighan and Ritchie's C book in 1972.

    http://stackoverflow.com/a/12785204
    HELLO_WORLD
    option :upcase
    def hello( name )
      greeting = "Hello, #{name}"
      greeting.upcase! if options[:upcase]
      puts greeting
    end


    desc 'dockerize DIR', 'Will copy the docker tempates in to your project'
    method_option :environment, default: "development", aliases: '-e'
    method_option :elasticsearch, default: false, type: :boolean, aliases: '-e'
    method_option :solr, default: false, type: :boolean, aliases: '-s'  # TODO
    method_option :postgres, default: false, type: :boolean, aliases: '-p'
    method_option :mysql, default: false, type: :boolean, aliases: '-m'
    method_option :redis, default: false, type: :boolean, aliases: '-r'
    method_option :sidekiq, default: false, type: :boolean, aliases: '-sq' # TODO
    method_option :mongodb, default: false, type: :boolean, aliases: '-mg' # TODO
    def dockerize(dir=nil)
      if dir
        Dir.chdir(dir)
      end

      db_libs = []
      db_libs << "libpq-dev postgresql-client" if postgres
      db_libs << "mysql-client" if mysql
      db_libs = db_libs.join(' ')

      template_path = File.join(File.dirname(__FILE__), '..', '..', 'templates')
      ['.dockerignore', 'Dockerfile', 'docker-compose.yml'].each do |template|

        renderer = ERB.new(File.read(File.join(template_path, template + '.erb')), 0, '-')
        File.write(template, renderer.result(binding))
      end
    end

  end
end
