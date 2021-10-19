require "spec_helper"
ROOT_DIR = File.expand_path("#{File.dirname(__FILE__)}/..")

describe StackCar do
  def destination_root
    @destination_root ||= File.join(ROOT_DIR, 'tmp', 'dockerize')
  end

  def runner(options = {})
    @runner ||= StackCar::HammerOfTheGods.new([1], options, :destination_root => destination_root)
  end

  def action(*args, &block)
    capture(:stdout) { runner.send(*args, &block) }
  end

  it "has a version number" do
    expect(StackCar::VERSION).not_to be nil
  end

  it 'can write the compose_params' do
    runner.options = {postgres: true}
    expect(runner.send(:compose_depends)).to eq("      - postgres")
  end

  context "dockerize" do

    before(:each) do
      # Set up test Rails project directory
      path = File.join(ROOT_DIR, 'tmp', 'dockerize')
      FileUtils.rm_rf path
      FileUtils.mkdir_p path
      Dir.chdir(path)
      `git init`
      `touch Gemfile`
      `echo '.bundle' > .gitignore`
    end

    it 'generates compose templates' do
      project_root_contents = Dir.entries('.')
      expect(project_root_contents.include?('docker-compose.yml')).to eq false
      expect(project_root_contents.include?('Dockerfile')).to eq false
      action("dockerize", '.')
      dockerized_project_root_contents = Dir.entries('.')
      expect(dockerized_project_root_contents.include?('docker-compose.yml')).to eq true
      expect(dockerized_project_root_contents.include?('Dockerfile')).to eq true
    end

    it 'generates gitlab issue and merge request templates' do
      project_root_contents = Dir.entries('.')
      expect(project_root_contents.include?('.gitlab')).to eq false
      # expect(project_root_contents.include?('all the files')).to eq false
      action("dockerize", '.')
      dockerized_project_root_contents = Dir.entries('.')
      expect(dockerized_project_root_contents.include?('.gitlab')).to eq true
      # expect(dockerized_project_root_contents.include?('all the files')).to eq true
    end

    it 'does not configure services additional to Rails unless a flag is passed' do
      action("dockerize", '.')
      compose = YAML.load_file('docker-compose.yml')
      expect(compose['services'].include?('elasticsearch')).to eq false
      expect(compose['services'].include?('fcrepo')).to eq false
      expect(compose['services'].include?('memcached')).to eq false
      expect(compose['services'].include?('mongodb')).to eq false
      expect(compose['services'].include?('mysql')).to eq false
      expect(compose['services'].include?('postgres')).to eq false
      expect(compose['services'].include?('redis')).to eq false
      expect(compose['services'].include?('solr')).to eq false
      expect(compose['services']['web']['depends_on']).to eq nil
    end

    it 'will configure a elasticsearch service if passed the --elasticsearch flag' do
      runner({elasticsearch: true})
      action("dockerize", '.')
      compose = YAML.load_file('docker-compose.yml')
      expect(compose['services'].include?('elasticsearch')).to eq true
      expect(compose['services']['web']['depends_on'].include?('elasticsearch')).to eq true
    end

    it 'will configure a fcrepo service if passed the --fcrepo flag' do
      runner({fcrepo: true})
      action("dockerize", '.')
      compose = YAML.load_file('docker-compose.yml')
      expect(compose['services'].include?('fcrepo')).to eq true
      expect(compose['services']['web']['depends_on'].include?('fcrepo')).to eq true
    end

    it 'will configure a memcached service if passed the --memcached flag' do
      runner({memcached: true})
      action("dockerize", '.')
      compose = YAML.load_file('docker-compose.yml')
      expect(compose['services'].include?('memcached')).to eq true
      expect(compose['services']['web']['depends_on'].include?('memcached')).to eq true
    end

    it 'will configure a mongodb service if passed the --mongodb flag' do
      runner({mongodb: true})
      action("dockerize", '.')
      compose = YAML.load_file('docker-compose.yml')
      expect(compose['services'].include?('mongodb')).to eq true
      expect(compose['services']['web']['depends_on'].include?('mongodb')).to eq true
    end

    it 'will configure a mysql service if passed the --mysql flag' do
      runner({mysql: true})
      action("dockerize", '.')
      compose = YAML.load_file('docker-compose.yml')
      expect(compose['services'].include?('mysql')).to eq true
      expect(compose['services']['web']['depends_on'].include?('mysql')).to eq true
    end

    it 'will configure a postgres service if passed the --postgres flag' do
      runner({postgres: true})
      action("dockerize", '.')
      compose = YAML.load_file('docker-compose.yml')
      expect(compose['services'].include?('postgres')).to eq true
      expect(compose['services']['web']['depends_on'].include?('postgres')).to eq true
    end

    it 'will configure a redis service if passed the --redis flag' do
      runner({redis: true})
      action("dockerize", '.')
      compose = YAML.load_file('docker-compose.yml')
      expect(compose['services'].include?('redis')).to eq true
      expect(compose['services']['web']['depends_on'].include?('redis')).to eq true
    end

    it 'will configure a sidekiq service if passed the --sidekiq flag' do
      runner({sidekiq: true})
      action("dockerize", '.')
      compose = YAML.load_file('docker-compose.yml')
      expect(compose['services'].include?('worker')).to eq true
      expect(compose['services']['worker']['command']).to eq 'bundle exec sidekiq'
      expect(compose['services']['web']['depends_on'].include?('sidekiq')).to eq true
    end

    it 'will configure a solr service if passed the --solr flag' do
      runner({solr: true})
      action("dockerize", '.')
      compose = YAML.load_file('docker-compose.yml')
      expect(compose['services'].include?('solr')).to eq true
      expect(compose['services']['web']['depends_on'].include?('solr')).to eq true
    end

    it 'will set development solr vars with sensible defaults' do
      project_name = 'dockerize'
      runner({solr: true})
      action("dockerize", '.')
      env_vars = Dotenv.parse(".env")
      expect(env_vars['SOLR_URL']).to eq "http://admin:admin@solr:8983/solr/#{project_name}-development"
      expect(env_vars['SOLR_ADMIN_PASSWORD']).to eq 'admin'
      expect(env_vars['SOLR_ADMIN_USER']).to eq 'admin'
      expect(env_vars['SOLR_COLLECTION_NAME']).to eq "#{project_name}-development"
      expect(env_vars['SOLR_CONFIGSET_NAME']).to eq project_name
      expect(env_vars['SOLR_HOST']).to eq 'solr'
      expect(env_vars['SOLR_PORT']).to eq '8983'
    end

    it 'will generate solr core initialization scripts if --solr flag' do
      runner({solr: true})
      action("dockerize", '.')
      bin_contents = Dir.entries('./bin')
      expect(bin_contents.include?('solrcloud-upload-configset.sh')).to eq true
      expect(bin_contents.include?('solrcloud-assign-configset.sh')).to eq true
    end

    it 'will work from a stack_car dir if it exists' do
      FileUtils.mkdir_p 'stack_car'
      action("dockerize")
      project_root_contents = Dir.entries('..')
      stack_car_dir_contents = Dir.entries('../stack_car')
      expect(project_root_contents.include?('docker-compose.yml')).to eq false
      expect(project_root_contents.include?('Dockerfile')).to eq false
      expect(stack_car_dir_contents.include?('docker-compose.yml')).to eq true
      expect(stack_car_dir_contents.include?('Dockerfile')).to eq true
    end
  end

  context 'dockerize --helm' do

    before(:each) do
      # Set up test Rails project directory
      path = File.join(ROOT_DIR, 'tmp', 'dockerize')
      FileUtils.rm_rf path
      FileUtils.mkdir_p path
      Dir.chdir(path)
      `git init`
      `touch Gemfile`
      `echo '.bundle' > .gitignore`
    end

    it 'will generate helm templates when passed the helm flag' do
      runner({helm: true})
      action("dockerize", '.')
      expect(Dir.exist?('chart')).to eq true
    end

    it 'will work from a stack_car dir if it exists' do
      FileUtils.mkdir_p 'stack_car'
      runner({helm: true})
      action("dockerize")
      project_root_contents = Dir.entries('..')
      stack_car_dir_contents = Dir.entries('../stack_car')
      expect(project_root_contents.include?('chart')).to eq false
      expect(stack_car_dir_contents.include?('chart')).to eq true
    end
  end

  context 'dockerize --helm --hyku' do

    before(:each) do
      # Set up test Rails project directory
      path = File.join(ROOT_DIR, 'tmp', 'dockerize')
      FileUtils.rm_rf path
      FileUtils.mkdir_p path
      Dir.chdir(path)
      `git init`
      `touch Gemfile`
      `echo '.bundle' > .gitignore`
    end
    
    it 'will generate hyku scripts if hyku flag is passed' do
      runner({helm: true, hyku: true})
      action("dockerize", '.')
      bin_contents = Dir.entries('./bin')
      expect(bin_contents.include?('helm_deploy')).to eq true
      expect(bin_contents.include?('helm_delete')).to eq true
    end

    it 'will not generate chart if hyku flag is passed' do
      runner({helm: true, hyku: true})
      action("dockerize", '.')
      expect(Dir.exist?('chart')).to eq false
    end

    it 'adds a sample values files for hyku deploys' do
      runner({helm: true, hyku: true})
      action("dockerize", '.')
      bin_contents = Dir.entries('./ops')
      expect(bin_contents.include?('sample-deploy.tmpl.yaml')).to eq true
      # TODO Expect multitenancy examples
      helm_values = YAML.load_file('ops/sample-deploy.tmpl.yaml')['extraEnvVars'].map { |v|  v["name"] }
      expect(helm_values.include?('SETTINGS__MULTITENANCY__ADMIN_HOST')).to eq true
      expect(helm_values.include?('SETTINGS__MULTITENANCY__DEFAULT_HOST')).to eq true
      expect(helm_values.include?('SETTINGS__MULTITENANCY__ROOT_HOST')).to eq true
      expect(helm_values.include?('SETTINGS__MULTITENANCY__ENABLED')).to eq true
    end
  end

  context 'dockerize --helm --hyrax' do

    before(:each) do
      # Set up test Rails project directory
      path = File.join(ROOT_DIR, 'tmp', 'dockerize')
      FileUtils.rm_rf path
      FileUtils.mkdir_p path
      Dir.chdir(path)
      `git init`
      `touch Gemfile`
      `echo '.bundle' > .gitignore`
    end

    it 'will generate hyrax deploy scripts if hyrax flag is passed' do
      runner({helm: true, hyrax: true})
      action("dockerize", '.')
      bin_contents = Dir.entries('./bin')
      expect(bin_contents.include?('helm_deploy')).to eq true
      expect(bin_contents.include?('helm_delete')).to eq true
    end

    it 'will not generate chart if hyku flag is passed' do
      runner({helm: true, hyrax: true})
      action("dockerize", '.')
      expect(Dir.exist?('chart')).to eq false
    end

    it 'adds a sample values files for hyrax deploys' do
      runner({helm: true, hyrax: true})
      action("dockerize", '.')
      bin_contents = Dir.entries('./ops')
      expect(bin_contents.include?('sample-deploy.tmpl.yaml')).to eq true
    end
  end
end
