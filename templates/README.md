# Docker development setup

1) Install Docker.app 

2) Get .env file from team member or copy it from .env.example and fill it out

3) gem install stack_car

4) sc up

``` bash
gem install stack_car
sc up

```

# Deploy a new release

``` bash
sc release {staging | production} # creates and pushes the correct tags
sc deploy {staging | production} # deployes those tags to the server
```

