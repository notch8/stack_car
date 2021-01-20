# StackCar

![logo](logo.jpg)

Stack Car is an opinionated set of tools around Docker and Rails.  It provides convenent methods to start and stop docker-compose, to deploy with rancher and a set of templates to get a new Rails app in to docker as quickly as possible.


## Installation

Because stack_car will be used to run your application in side of Docker, you want to install stack car in to your system Ruby instead of putting in your applications Gemfile

```bash
gem install stack_car 
```

## Usage

Commands are accesible via the "sc" short cut. Note: this will need to be in your command path in front of the spreadsheet command (sc), which is a fairly archaiac unix spreadsheet tool. We're guessing you don't edit a lot of spreadsheets in your terminal, but if you do, we also figure you can override your path order pretty easily.  Many of these commands have short versions or alias to make remembering them easier.  If there are obvious aliases missing, PRs are welcome.

```ruby
Commands:
  stack_car bundle_exec ARGS  # wraps docker-compose exec web bundle exec unless --service is used to specify (sc be ARGS)
  stack_car console ARGS      # shortcut to start rails console
  stack_car dockerize DIR     # Will copy the docker tempates in to your project, see options for supported dependencies
  stack_car exec ARGS         # wraps docker-compose exec web unless --service is used to specify
  stack_car help [COMMAND]    # Describe available commands or one specific command
  stack_car stop              # starts docker-compose with rebuild and orphan removal, defaults to all
  stack_car up                # starts docker-compose with rebuild and orphan removal, defaults to web
  stack_car walk ARGS         # wraps docker-compose run web unless --service is used to specify
```

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

**To install this gem onto your local machine**
- Run `bundle exec rake install`

### Workflow

**Create a dummy rails app**

Developing stack_car often requires a rails application for you to run updated commands and templates against. Generate one for this purpose:
- `rails new <dummy-app-name>`

**Make and test your changes**
- In stack_car, make your command / template changes
- Run `rake install` to update your local gem
- In your dummy application, test the updated command
- Commit your changes

### Releasing a new version
- Update the version number in `version.rb`
- Run `bundle exec rake release`
  - This will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Generating a Helm Chart

stack_car's **dockerize** command can be used in conjunction with available flags to generate a **Helm chart** template for your application. You will need to create the *values* files with necessary configuration values from the *sample-values* provided by stack_car, but the command will effectively give you the baseline Notch8 template (scripts, template files, template helpers, sample values file) for a **Helm base Kubernetes deploy**

The following examples are to be run in the repo of the application you are creating the chart for.

**To generate a Helm chart template**

- `sc dockerize --helm`
  - This command without additional flags will only generate Rails web related template files

In broad strokes adding additional flags signals stack_car to generate template files for other services. Note that any configuration that would normally be applied for these services in a non Helm context (without the `--helm` flag) still apply.

**For example**:
- `sc dockerize --helm --fcrepo --solr`
  - This command will add templates for the **fcrepo** service and add a **solr chart dependency** in the `Chart.yaml` (You can think of `Chart.yaml` like the **Gemfile** or **package.json** of a Helm chart)

**Creating values files**

Values files allows you to configure your helm deploy from number of web instances to hostname for your ingress to environment variables required by your application.

When starting from a new helm chart, you'll want to copy the sample values file to one named after the environment you're creating a deployment for.

For example:
`cp sample-values.yaml staging-values.yaml`

*Note: You will do this once for every environment you'd like to deploy*

**Handling values files**

Since values files are likely to contain sensitive information like API keys, they should never be committed to your repository. The scripts that stack_car includes in your chart simplifies encrypting and decrypting values for version control.

Example workflow (given values file is already created):
- Edit values file
- `chart/bin/encrypt staging <keybase-team-name>`
  - This command will create `staging-values.yaml.enc`
- `git add staging-values.yaml.enc`
- Commit and push

When pulling down a repo or branch, you will need to start by decrypting.

Example:
- `chart/bin/decrypt staging`

## Contributing

Bug reports and pull requests are welcome on Gitlab at https://gitlab.com/notch8/stack_car.

## TODO

- move .env files to dot style
- make .env secret by default
- update .gitlab to latest (see learn and ansur)

- Fill out readme
- Implement deploy
- Implement deploy templates
- Implement database dump and restore
- Implement secret sync
- Specs
