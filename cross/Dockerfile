
FROM ubuntu:20.04

RUN apt-get update && apt-get install -y \
  build-essential \
  gcc \
  g++ \
  make \
  bison \
  flex

COPY ./gcc-cross-build.sh ./
RUN chmod u+x gcc-cross-build.sh

COPY ./test.sh ./
RUN chmod u+x ./test.sh

RUN mkdir -p gcc-build/

#CMD ["sleep","86400"]
CMD ["./test.sh"]

