# docker-ark-cluster
A simple docker image/container setup for an ARK: Survival Evolved cluster world.

## Prerequisites 
* docker
* docker-compose
* knowledge of how to use docker and docker-compose

## Instructions

### First, build your image
```
docker build -t arkimage .
```
Then, edit your docker-compose.yml and .env files with values that you want

### Usage

#### Running a world
```
docker-compose up -d World_Name
```

#### Shutting down a world
```
docker-compose exec World_Name /controlARK.bash stop
```

#### Updating ARK Data
```
# First, shut down any worlds running
docker-compose up -d UPDATE
```

#### Backup up your ARK worlds
```
docker-compose up -d BACKUP
```
