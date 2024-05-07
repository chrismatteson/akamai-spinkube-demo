# This exists to make it easy to run keadm on Apple Silicon.
# Just run build then run `docker compose run keadm` to get a join token.
# Alternatively you can run other keadm commands by adding them after keadm.

FROM ubuntu
LABEL maintainer="Chris Matteson"

RUN apt-get update
RUN apt-get install wget -y
RUN wget https://github.com/kubeedge/kubeedge/releases/download/v1.17.0/keadm-v1.17.0-linux-arm64.tar.gz
RUN tar -zxvf keadm-v1.17.0-linux-arm64.tar.gz
RUN cp keadm-v1.17.0-linux-arm64/keadm/keadm /usr/local/bin/keadm
COPY ./kubeconfig.yaml /kubeconfig.yaml

ENTRYPOINT ["keadm"]
