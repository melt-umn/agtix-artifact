#FROM archlinux:latest

#COPY . /home/agtix

#RUN pacman -Syu --noconfirm \
#    jdk21-openjdk \
#    ant \
#    diffutils && \
#    pacman -Scc --noconfirm

#WORKDIR /home/agtix


FROM openjdk:21-ea-21-jdk-oracle

COPY . /home/agtix

RUN 

RUN microdnf install -y ant diffutils

WORKDIR /home/agtix
