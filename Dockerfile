FROM phusion/baseimage:0.10.1

LABEL version="0.1"
LABEL description="docker with fuzz tools"

ENV DEBIAN_FRONTEND noninteractive

ENV TZ Asia/Shanghai

RUN apt-get -y update && \
    apt install git sudo python-pip wget -y

RUN echo 0|sudo tee /proc/sys/kernel/yama/ptrace_scope

#build afl-fuzz but not install it
RUN apt install libtool-bin automake bison libglib2.0-dev -y

RUN wget https://lcamtuf.coredump.cx/afl/releases/afl-latest.tgz -O /fuzz/ftools/afl-latest.tgz && \
    tar zxvf afl-latest.tgz && rm -rf *.tgz && \
    cd /fuzz/ftools/afl-2.52b && make && cd /fuzz/ftools/afl-2.52b/qemu_mode && ./build_qemu_support.sh

#build qsym but not install it
RUN apt-get install -y libc6 libstdc++6 linux-libc-dev gcc-multilib \
    llvm-dev g++ g++-multilib python lsb-release

RUN cd /fuzz/ftools && git clone https://github.com/sslab-gatech/qsym.git && \
    cd /fuzz/ftools/qsym/ && git submodule init && git submodule update
#./setup.sh
RUN cd /fuzz/ftools/qsym/third_party/z3 && ./configure && \
    cd /fuzz/ftools/qsym/third_party/z3/build && make -j$(nproc) && sudo make install

RUN  cd /fuzz/ftools/qsym/third_party/z3 && rm -rf /fuzz/ftools/qsym/third_party/z3/build && \
    ./configure --x86 && cd /fuzz/ftools/qsym/third_party/z3/build && make -j$(nproc) && cp ./libz3.so /usr/lib32/

RUN python -m pip install --upgrade pip && cd /fuzz/ftools/qsym && make -C qsym/pintool -j$(nproc) && \
    export TARGET=ia32 &&  make -C qsym/pintool -j$(nproc) && cd /fuzz/ftools/qsym/qsym/pintool/codegen && python ./gen_expr_builder.py && python ./gen_expr.py

WORKDIR /fuzz/fzwork


CMD ["/sbin/my_init"]
    
