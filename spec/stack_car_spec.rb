require "spec_helper"
ROOT_DIR = File.expand_path("#{File.dirname(__FILE__)}/..")

describe StackCar do
  def destination_root
    @destination_root ||= File.join(ROOT_DIR, 'tmp', 'dockerize')
  end

  def setup_test_app
    Dir.chdir ROOT_DIR
    test_app_path = File.join(ROOT_DIR, 'test_app')
    FileUtils.rm_rf test_app_path
    FileUtils.mkdir_p test_app_path
    Dir.chdir('test_app')
    FileUtils.touch 'Gemfile'
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

  it 'can write the compose_paras' do
    runner.options = {postgres: true}
    expect(runner.send(:compose_depends)).to eq("      - postgres")
  end

  it "generates Docker files for local building and development" do
    setup_test_app

    `git init`
    `echo '.bundle' > .gitignore`
    runner({postgres: true, mysql: true, delayed_job: true})
    action("dockerize", '.')
  end

  it "sets up Docker and Helm chart in the stack_car directory if it exists" do
    setup_test_app
    FileUtils.mkdir_p 'stack_car'

    `git init`
    `echo '.bundle' > .gitignore`
    runner({postgres: true, mysql: true, delayed_job: true, helm: true})
    action("dockerize", '.')
  end
end
