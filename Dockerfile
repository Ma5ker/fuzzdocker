FROM phusion/baseimage:0.10.1

LABEL version="0.1"
LABEL description="docker with fuzz tools"

ENV DEBIAN_FRONTEND noninteractive

ENV TZ Asia/Shanghai

RUN apt-get -y update && \
    apt install git sudo python-pip wget -y

CMD ["/sbin/my_init"]

WORKDIR /fuzz/fzwork

RUN mkdir /fuzz/fztools

#build afl-fuzz but not install it
RUN apt install libtool-bin automake bison libglib2.0-dev -y

RUN wget https://lcamtuf.coredump.cx/afl/releases/afl-latest.tgz -O /fuzz/fztools/afl-latest.tgz && \
    cd /fuzz/fztools && tar zxvf afl-latest.tgz && rm -rf *.tgz && \
    cd /fuzz/fztools/afl-2.52b && make && cd /fuzz/fztools/afl-2.52b/qemu_mode && ./build_qemu_support.sh

#build qsym but not install it
RUN apt-get install -y libc6 libstdc++6 linux-libc-dev gcc-multilib \
    llvm-dev g++ g++-multilib python lsb-release

RUN cd /fuzz/fztools && git clone https://github.com/sslab-gatech/qsym.git && \
    cd /fuzz/fztools/qsym/ && git submodule init && git submodule update
#./setup.sh
RUN cd /fuzz/fztools/qsym/third_party/z3 && ./configure && \
    cd /fuzz/fztools/qsym/third_party/z3/build && make -j$(nproc) && sudo make install

RUN  cd /fuzz/fztools/qsym/third_party/z3 && rm -rf /fuzz/fztools/qsym/third_party/z3/build && \
    ./configure --x86 && cd /fuzz/fztools/qsym/third_party/z3/build && make -j$(nproc) && cp ./libz3.so /usr/lib32/

RUN python -m pip install --upgrade pip && cd /fuzz/fztools/qsym && make -C qsym/pintool -j$(nproc) && \
    export TARGET=ia32 &&  make -C qsym/pintool -j$(nproc) && cd /fuzz/fztools/qsym/qsym/pintool/codegen && python ./gen_expr_builder.py && python ./gen_expr.py

RUN apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

COPY my_start.sh /usr/bin/my_start.sh
RUN chmod +x /usr/bin/my_start.sh
ENTRYPOINT "my_start.sh && /bin/bash"