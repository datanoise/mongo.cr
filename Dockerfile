FROM crystallang/crystal:0.35.1
RUN apt-get update \
  && apt-get -y install cmake libssl-dev libsasl2-dev wget \
  && rm -rf /var/lib/apt/lists/*
WORKDIR /tmp

RUN git clone https://github.com/mongodb/mongo-c-driver.git
WORKDIR /tmp/mongo-c-driver
RUN cmake -DCMAKE_BUILD_TYPE=Release -DENABLE_AUTOMATIC_INIT_AND_CLEANUP=OFF . \
  && make && make install 

WORKDIR /app