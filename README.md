# Docker_Senior_Design

This repository stores the Dockerfile used to run a container
on the nvidea jetson nano, since this project uses ROS2 Humble, which is not compatible with Ubuntu 18.04.

To build the docker image, just run docker build .

If you want to give the image a tag just add the -t.
ex: docker build -t Docker_Senior_Design/nav:latest .
