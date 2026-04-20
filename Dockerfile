FROM archlinux:latest

COPY . /home/agtix

RUN pacman -Sy --noconfirm jdk21-openjdk ant diffutils

WORKDIR /home/agtix