FROM alpine:3.20
LABEL authors="Dimitri Sifoua"
LABEL description="Java Build Agent with Graavlm Support"
LABEL maintainer="Dimitri Sifoua <dimitri.sifoua@gmail.com>"

ARG JAVA_VERSION=21.0.4-graal

ENV UID=10001
ENV GID=10001
ENV USERNAME=dksifoua
ENV HOME=/home/$USERNAME

RUN <<EOF
  apk update
  apk add --no-cache bash curl unzip zip shadow
  groupadd -g $GID $USERNAME
  useradd -m -g $GID -u $UID -s /bin/bash $USERNAME
  apk del shadow
EOF

SHELL ["/bin/bash", "-c"]

USER $UID:$GID

RUN curl -s "https://get.sdkman.io" | bash

RUN <<EOF
  source $HOME/.sdkman/bin/sdkman-init.sh
  sdk install java $JAVA_VERSION
  rm -rf $HOME/.sdkman/archives/*
  rm -rf $HOME/.sdkman/tmp/*
EOF

HEALTHCHECK \
  --interval=30s \
  --timeout=10s \
  --start-period=5s \
  --retries=3 \
  CMD curl --fail http://localhost/ || exit 1

WORKDIR $HOME

CMD ["/bin/bash"]