binary:
	echo "Building helloworld go binary"
	CGO_ENABLED=0 GOOS=linux go build -a -installsuffix cgo -o helloworld.bin helloworld.go

container:
	echo "Building Alpine Docker Image with helloworld binary included"
	docker build -t helloworld:latest .
run:
	echo "Starting helloworld container"
	docker run -d -p 80:80 --name helloworld helloworld:latest

all: binary container run test
	echo "Building the Go binary, adding it to a Docker image and starting a helloworld container"	

test:
	docker ps |grep helloworld || echo "Oops! Helloworld container is not running"
	curl http://localhost:8888
