[Docker development setup](#docker-development-setup)

[Bash into the container](#bash-into-the-container)

[Deploy a new release](#deploy-a-new-release)
  
[Run import from admin page](#run-import-from-admin-page)

# Docker development setup

We recommend committing .env to your repo with good defaults. .env.development, .env.production etc can be used for local overrides and should not be in the repo.

1) Install Docker.app

2) Install stack car
    ``` bash
    gem install stack_car
    ```

3) Sign in with dory
    ``` bash
    dory up
    ```

4) Install dependencies
    ``` bash
    yarn install
    ```

5) Start the server
    ``` bash
    sc up
    ```

6) Load and seed the database
    ``` bash
    sc be rake db:migrate db: seed
    ```
### Troubleshooting Docker Development Setup
Confirm or configure settings. Sub your information for the examples.
``` bash
git config --global user.name example
git config --global user.email example@example.com
docker login registry.gitlab.com
```

### While in the container you can do the following
- Run rspec
    ``` bash
    bundle exec rspec
    ```
- Access the rails console
    ``` bash
    bundle exec rails c
    ```

# Deploy a new release

``` bash
sc release {staging | production} # creates and pushes the correct tags
sc deploy {staging | production} # deployes those tags to the server
```

Release and Deployment are handled by the gitlab ci by default. See ops/deploy-app to deploy from locally, but note all Rancher install pull the currently tagged registry image
