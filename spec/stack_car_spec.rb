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

  it 'can write the compose_paras' do
    runner.options = {postgres: true}
    expect(runner.send(:compose_depends)).to eq("      - postgres")
  end

  it "dockerizes" do
    path = File.join(ROOT_DIR, 'tmp', 'dockerize')
    FileUtils.rm_rf path
    FileUtils.mkdir_p path
    Dir.chdir(path)
    `git init`
    `echo '.bundle' > .gitignore`
    runner({postgres: true, mysql: true, delayed_job: true})
    action("dockerize", '.')
  end
end
