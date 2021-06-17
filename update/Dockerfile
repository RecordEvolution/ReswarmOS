
FROM ubuntu:20.04

RUN apt-get update && apt-get upgrade -y && apt-get install -y \
  ostree ostree-boot \
  rauc rauc-service  

CMD ["sleep","3600"]

