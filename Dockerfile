FROM phusion/baseimage:0.10.1

LABEL version="0.1"
LABEL description="docker with fuzz tools"

ENV DEBIAN_FRONTEND noninteractive

ENV TZ Asia/Shanghai

RUN apt-get -y update && \
    apt install git sudo -y

RUN dpkg --add-architecture i386 && \
    apt-get -y update && \
    apt install -y \
    python-pip

RUN wget https://lcamtuf.coredump.cx/afl/releases/afl-latest.tgz -O /fuzz/ftools/afl-latest.tgz && \
    tar zxvf afl-latest.tgz && rm -rf *.tgz && \
    cd /fuzz/ftools/afl-2.52b/ && make



WORKDIR /fuzz/fwork

CMD ["/sbin/my_init"]
    
