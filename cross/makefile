
docker-build:
	sudo docker build . --tag=gcc-cross-build

docker-run:
	sudo docker run -it --rm gcc-cross-build:latest

docker-run-volume:
	sudo docker run -it --rm -v /home/mario/Downloads/gcc-build/:/gcc-build/ gcc-cross-build:latest

docker-run-volume-deamon:
	sudo docker run -it -d --rm -v /home/mario/Downloads/gcc-build/:/gcc-build/ gcc-cross-build:latest

check-tools:
	./prerequisites-check.sh | grep missing

