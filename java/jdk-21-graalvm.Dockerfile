FROM --platform=$BUILDPLATFORM ubuntu:24.10
LABEL authors="Dimitri Sifoua"
LABEL description="Java Build Agent with GraalVM Support"
LABEL maintainer="Dimitri Sifoua <dimitri.sifoua@gmail.com>"
LABEL version="1.0.1"

ARG TARGETPLATFORM

ENV UID=10001
ENV GID=10001
ENV USERNAME=dksifoua
ENV HOME=/home/$USERNAME

ENV GRAALVM_HOME=/opt/java-jdk-21-graalvm
ENV JAVA_HOME=$GRAALVM_HOME
ENV PATH=$GRAALVM_HOME/bin:$PATH

ENV GRADLE_VERSION=8.10.2
ENV GRADLE_HOME=/opt/gradle-$GRADLE_VERSION
ENV PATH=$GRADLE_HOME/bin:$PATH

RUN apt-get update \
    && apt-get install -y build-essential curl unzip zlib1g-dev \
    && rm -rf /var/lib/apt/lists

RUN curl --location https://taskfile.dev/install.sh | bash -s -- -d

RUN case $TARGETPLATFORM in \
    "linux/amd64") \
      GRAALVM_FILE="graalvm-jdk-21_linux-x64_bin.tar.gz"; \
      GRAALVM_URL="https://download.oracle.com/graalvm/21/latest/$GRAALVM_FILE"; \
      ;; \
    "linux/arm64") \
      GRAALVM_FILE="graalvm-jdk-21_linux-aarch64_bin.tar.gz"; \
      GRAALVM_URL="https://download.oracle.com/graalvm/21/latest/$GRAALVM_FILE"; \
      ;; \
    *) \
      echo "Unsupported platform: $BUILDPLATFORM"; exit 1; \
      ;; \
  esac \
    && mkdir -p $GRAALVM_HOME \
    && curl -L $GRAALVM_URL -o $GRAALVM_HOME/$GRAALVM_FILE \
    && tar -xvzf $GRAALVM_HOME/$GRAALVM_FILE --strip-components=1 -C $GRAALVM_HOME \
    && rm $GRAALVM_HOME/$GRAALVM_FILE

RUN mkdir -p $GRADLE_HOME \
    && GRADLE_URL=https://services.gradle.org/distributions/gradle-$GRADLE_VERSION-bin.zip \
    && curl -L $GRADLE_URL -o $GRADLE_HOME/gradle-$GRADLE_VERSION-bin.zip \
    && unzip $GRADLE_HOME/gradle-$GRADLE_VERSION-bin.zip -d /opt \
    && rm $GRADLE_HOME/gradle-$GRADLE_VERSION-bin.zip

RUN groupadd -g $GID $USERNAME \
    && useradd -m -g $GID -u $UID -s /bin/bash $USERNAME \
    && chmod u-s /usr/bin/chfn /usr/bin/gpasswd /usr/bin/su /usr/bin/passwd /usr/bin/chsh /usr/bin/newgrp /usr/bin/mount /usr/bin/umount \
    && chmod g-s /usr/bin/chage /usr/sbin/pam_extrausers_chkpwd /usr/sbin/unix_chkpwd /usr/bin/expiry

USER $UID:$GID

HEALTHCHECK --interval=5m --timeout=10s --start-period=5s --retries=1 CMD gcc --version \
  && gradle --version \
  && java --version \
  && native-image --version \
  && task --version || exit 1

WORKDIR $HOME

CMD ["/bin/bash"]