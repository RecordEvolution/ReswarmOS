
FROM ubuntu:18.04

RUN groupadd reagent && \
    useradd --create-home -g reagent reagent

RUN apt-get update && apt-get upgrade -y && apt-get install -y \
  git \
  golang \
  gcc-aarch64-linux-gnu \
  snap

USER reagent
WORKDIR /home/reagent

RUN whoami && pwd && ls -lh

#COPY build-agent.sh /home/reagent/build-agent.sh

#RUN ls -lha /home/reagent

#CMD ["CGO_ENABLED=1","GOOS=linux","GOARCH=arm64","GOARM=7","CC=aarch64-linux-gnu-gcc","go","build","."]
CMD ["sleep","3000"]
#CMD ["build-agent.sh"]

