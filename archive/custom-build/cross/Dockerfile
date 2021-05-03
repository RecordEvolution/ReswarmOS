
FROM ubuntu:20.04

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && apt-get install -y tzdata
RUN dpkg-reconfigure -f noninteractive tzdata

RUN apt-get update && apt-get install -y \
  build-essential \
  git \
  gcc \
  g++ \
  make \
  bison \
  flex \
  texinfo \
  gawk \
  python3

COPY ./prerequisites.txt ./
COPY ./gcc-cross-build.sh ./
COPY ./prerequisites-check.sh ./

RUN chmod u+x prerequisites-check.sh
RUN chmod u+x gcc-cross-build.sh

#COPY ./test.sh ./
#RUN chmod u+x ./test.sh

RUN mkdir -p gcc-build/

#CMD ["./prerequisites-check.sh"]
CMD ["./gcc-cross-build.sh"]

