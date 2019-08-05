FROM dlang2/dmd-ubuntu:latest
LABEL Name=quirks Version=0.0.1

# install required packages
RUN apt-get -y update
RUN apt-get -y --fix-missing install git
RUN apt-get -y --fix-missing install gcc
RUN apt-get -y --fix-missing install libz-dev
RUN apt-get -y --fix-missing install libevent-dev
RUN apt-get -y --fix-missing install libssl-dev
RUN apt-get -y --fix-missing install curl
RUN apt-get -y --fix-missing install xz-utils
RUN snap install --classic hub