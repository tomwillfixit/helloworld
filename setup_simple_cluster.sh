#!/bin/bash

# Description :

# Creates a 3 node swarm cluster.  The swarm manager will be your docker host on which this script is being run.  The other 2 'worker' nodes will be started using boot2docker 1.12 experimental build

HOST_IP=$(ip route get 8.8.8.8 | awk '{print $NF; exit}')

echo "Cleanup previous setup"
docker-machine ls |grep sw && docker-machine rm -f $(docker-machine ls -q) 

echo "Remove previous helloworld service"
docker service ls |grep helloworld && docker service rm helloworld

echo "Create swarm manager on laptop : ${HOST_IP}"
docker swarm init --force-new-cluster --listen-addr ${HOST_IP}:2377
sleep 5

# create swarm nodes

for node in sw01 sw02;
do

    echo "Creating swarm node :  ${node}"
    docker-machine create -d virtualbox --virtualbox-boot2docker-url=https://github.com/boot2docker/boot2docker/releases/download/v1.12.0-rc2/boot2docker-experimental.iso ${node} 

    docker-machine ssh ${node} docker swarm join ${HOST_IP}:2377 
done

# list nodes
docker node ls

#creating a network, starting the server container and scaling

echo "Create helloworld overlay network if it doesn't exist"
docker network ls |grep helloworld_net || docker network create -d overlay helloworld_net

echo "Create helloworld service"
docker service create --name helloworld --network helloworld_net --replicas 1 --publish 80 thshaw/helloworld

echo "List tasks running as part of the helloworld service"
docker service tasks helloworld

#scale to 5 containers

echo "Scaling to 5 replicas"
docker service update --replicas 5 helloworld 

docker service tasks helloworld 

# list everything running across the nodes

for node_name in $(docker node ls -q); do echo "Swarm Node : ${node_name}";docker node tasks ${node_name};done

echo "Test that the helloworld service is accessible from any node"
echo "Find which port the service is accessible on the overlay network (SWARM_PORT)"
echo "SWARM PORT default begins from 30000. Default range is 30000 to 32000"

docker service inspect helloworld
echo "curl <node ip>:30000"
