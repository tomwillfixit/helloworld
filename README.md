# HelloWorld Walkthrough using Docker 1.12 

At DockerCon 2016 1.12 was announced and 2 significant new features are now available in beta.  More details on the official blog :

https://blog.docker.com/2016/06/docker-1-12-built-in-orchestration/

Swarm Mode and Services

## Swarm mode

Previous to Docker 1.12 swarm creation and management was done using the swarm:latest image or from pre-built swarm binaries.  In 1.12 the swarm commands are now baked into the docker cli.  This makes the creation and maintainance of swarm clusters super simple. In the walkthrough below we will create a 3 node swarm cluster and run a simple 'HelloWorld' app on the cluster.

## Services

The 'docker service' command enables you to create a multi container service which can run locally or across a swarm cluster.  This provides out-of-box replication, distribution and load balancing. The 'docker service' command also provides the ability to perform rolling updates in which service configuration changes can be rolled out over a period of time. We will cover this in the walkthrough below.


## Walkthrough

We have all seen 'HelloWorld' examples in the past and typically they involve running a single web application in a single container on a single host. This walkthrough will cover the steps to setup a simple 3 node swarm cluster and run a multi container HelloWorld app across all swarm nodes.

This walkthrough has been tested on Ubuntu 16.04 with Docker 1.12-RC2 build.

## Prerequisites 

docker 1.12
docker-machine 0.7.0
VirtualBox

### Install Docker 1.12

Follow the official documentation or update using :
```
wget -qO- https://test.docker.com/ | sh
```

### Install docker-machine
```
$ curl -L https://github.com/docker/machine/releases/download/v0.7.0/docker-machine-`uname -s`-`uname -m` > /usr/local/bin/docker-machine && \
chmod +x /usr/local/bin/docker-machine
```

### Install VirtualBox

Follow the official documentation here : https://www.virtualbox.org/manual/ch02.html

### Create a 3 node swarm cluster

The swarm manager will be on the host on which you installed Docker. The 2 swarm workers will be boot2docker VMs provisioned using docker-machine. 

#### Swarm Manager 
```
HOST_IP=$(ip route get 8.8.8.8 | awk '{print $NF; exit}')
docker swarm init --listen-addr ${HOST_IP}:2377
```

#### Swarm workers
```
for node in sw01 sw02;
do
    echo "Creating swarm node :  ${node}"
    docker-machine create -d virtualbox --virtualbox-boot2docker-url=https://github.com/boot2docker/boot2docker/releases/download/v1.12.0-rc2/boot2docker-experimental.iso ${node} 

    docker-machine ssh ${node} docker swarm join ${HOST_IP}:2377 
done

```

### Create a 'HelloWorld' service

#### Create an overlay network 
```
docker network create -d overlay helloworld_net
```

#### Create the 'HelloWorld' service

Using a 'helloworld' image from Docker Hub for this walkthrough but feel free to build your own. Source included in this repo.

```
docker service create --name helloworld --network helloworld_net --replicas 1 --publish 80 thshaw/helloworld
```

#### List tasks running as part of the helloworld service
```
docker service tasks helloworld
```

#### Scale to 5 'HelloWorld' containers
```
docker service update --replicas 5 helloworld 
```

#### List all tasks in the 'HelloWorld' service
```
docker service tasks helloworld 

Example Output :

ID                         NAME          SERVICE     IMAGE              LAST STATE          DESIRED STATE  NODE
6nuvokhvty38firhcw3lj2dmw  helloworld.1  helloworld  thshaw/helloworld  Running 4 minutes   Running        sw02
0ewirsrtyjm6kqlnjvj9avo2k  helloworld.2  helloworld  thshaw/helloworld  Accepted 4 seconds  Accepted       tom-laptop
98uzr4j19ks48akg7dsdwjkip  helloworld.3  helloworld  thshaw/helloworld  Running 4 minutes   Running        sw01
92w8gcc0jtvz0z4v807zu6ra7  helloworld.4  helloworld  thshaw/helloworld  Running 4 minutes   Running        sw01
832uhk9mlwbo2sik6457cgggp  helloworld.5  helloworld  thshaw/helloworld  Running 4 minutes   Running        sw02

```


#### List everything running across the cluster 

```
for node_name in $(docker node ls -q); 
do 
    echo "Swarm Node : ${node_name}"
    docker node tasks ${node_name}
done
```

#### Test that the helloworld service is accessible from any node

Find which port (SWARM PORT) the service is accessible on the overlay network.
The SWARM PORT default begins from port 30000. Default range is 30000 to 32000

```
docker service inspect helloworld
echo "curl <node ip>:30000"
```

#### Rolling update

Looks like the HelloWorld app has a bug in it.  Docker 1.12 supports rolling updates so we can replace the service config over time.
In this example we will update the 'HelloWorld' image being used from : thshaw/helloworld:latest to thshaw/helloworld:v2.
We will replace one container every 30 seconds until all nodes are using the correct image.

```
docker service update --update-delay 30s --update-parallelism 1 --image thshaw/helloworld:v2 helloworld 

Example Output :

docker service tasks helloworld
ID                         NAME          SERVICE     IMAGE                 LAST STATE          DESIRED STATE  NODE
38erc4vxxzfbb9q01jp9hxtty  helloworld.1  helloworld  thshaw/helloworld:v2  Assigned 1 seconds  Accepted       tom-laptop
0kkgvaf88ie0xo56b7y7ejsnh  helloworld.2  helloworld  thshaw/helloworld:v2  Accepted 1 seconds  Accepted       tom-laptop
98uzr4j19ks48akg7dsdwjkip  helloworld.3  helloworld  thshaw/helloworld     Running 11 minutes  Running        sw01
92w8gcc0jtvz0z4v807zu6ra7  helloworld.4  helloworld  thshaw/helloworld     Running 11 minutes  Running        sw01
832uhk9mlwbo2sik6457cgggp  helloworld.5  helloworld  thshaw/helloworld     Running 11 minutes  Running        sw02

docker service tasks helloworld
ID                         NAME          SERVICE     IMAGE                 LAST STATE          DESIRED STATE  NODE
0xg2pd2fpfb0v43wlzfspxzf1  helloworld.1  helloworld  thshaw/helloworld:v2  Accepted 1 seconds  Accepted       sw02
7dpwtq9pfbc4dc2gzr48sj3aq  helloworld.2  helloworld  thshaw/helloworld:v2  Running 14 seconds  Running        sw02
98uzr4j19ks48akg7dsdwjkip  helloworld.3  helloworld  thshaw/helloworld     Running 11 minutes  Running        sw01
92w8gcc0jtvz0z4v807zu6ra7  helloworld.4  helloworld  thshaw/helloworld     Running 11 minutes  Running        sw01
ao7jiwu9dlrrhri40q0xlqmg0  helloworld.5  helloworld  thshaw/helloworld:v2  Accepted 2 seconds  Accepted       tom-laptop

docker service tasks helloworld
ID                         NAME          SERVICE     IMAGE                 LAST STATE           DESIRED STATE  NODE
6xnm0oowd8yq258jku9z9am9n  helloworld.1  helloworld  thshaw/helloworld:v2  Accepted 2 seconds   Accepted       tom-laptop
7dpwtq9pfbc4dc2gzr48sj3aq  helloworld.2  helloworld  thshaw/helloworld:v2  Running 27 seconds   Running        sw02
98uzr4j19ks48akg7dsdwjkip  helloworld.3  helloworld  thshaw/helloworld     Running 11 minutes   Running        sw01
92w8gcc0jtvz0z4v807zu6ra7  helloworld.4  helloworld  thshaw/helloworld     Running 11 minutes   Running        sw01
2bhaxigkgtyy7l8c2ktthefgq  helloworld.5  helloworld  thshaw/helloworld:v2  Preparing 5 seconds  Running        sw02

docker service tasks helloworld
ID                         NAME          SERVICE     IMAGE                 LAST STATE                    DESIRED STATE  NODE
75q27c15b0r3od3siomuesp7u  helloworld.1  helloworld  thshaw/helloworld:v2  Running 17 seconds            Running        sw01
7dpwtq9pfbc4dc2gzr48sj3aq  helloworld.2  helloworld  thshaw/helloworld:v2  Running About a minute        Running        sw02
98uzr4j19ks48akg7dsdwjkip  helloworld.3  helloworld  thshaw/helloworld     Running 12 minutes            Running        sw01
9j2swo61cfo6tgw0tuo6meevr  helloworld.4  helloworld  thshaw/helloworld:v2  Allocated Less than a second  Accepted       
erlzrf8shiobg4f7j7fhoqra1  helloworld.5  helloworld  thshaw/helloworld:v2  Accepted 3 seconds            Accepted       sw02

docker service tasks helloworld
ID                         NAME          SERVICE     IMAGE                 LAST STATE              DESIRED STATE  NODE
75q27c15b0r3od3siomuesp7u  helloworld.1  helloworld  thshaw/helloworld:v2  Running 35 seconds      Running        sw01
7dpwtq9pfbc4dc2gzr48sj3aq  helloworld.2  helloworld  thshaw/helloworld:v2  Running About a minute  Running        sw02
dht5mzpqjmclwfcop36259unw  helloworld.3  helloworld  thshaw/helloworld:v2  Rejected 5 seconds      Running        tom-laptop
cxxkt1ewhmxtwhvcwnoqto27z  helloworld.4  helloworld  thshaw/helloworld:v2  Preparing 4 seconds     Running        sw02
1d6r957aei0h5etsxpzm8pw94  helloworld.5  helloworld  thshaw/helloworld:v2  Accepted 2 seconds      Accepted       sw01

```

That's it.  Ok so it might be overkill to run a simple 'HelloWorld' app across a swarm cluster but it demonstrates the simplicity of moving from a single container/host application to a clustered multi container application.  This will be great for developers as it moves them even closer to a production like setup.
