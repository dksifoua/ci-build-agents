FROM --platform=$BUILDPLATFORM ubuntu:24.10
LABEL authors="Dimitri Sifoua"
LABEL description="Java 21 Build Agent"
LABEL maintainer="Dimitri Sifoua <dimitri.sifoua@gmail.com>"
LABEL version="1.0.1"

ARG TARGETPLATFORM

ENV UID=10001
ENV GID=10001
ENV USERNAME=dksifoua
ENV HOME=/home/$USERNAME

ENV JAVA_HOME=/opt/java-jdk-21
ENV PATH=$JAVA_HOME/bin:$PATH

ENV GRADLE_VERSION=8.10.2
ENV GRADLE_HOME=/opt/gradle-$GRADLE_VERSION
ENV PATH=$GRADLE_HOME/bin:$PATH

RUN apt-get update \
    && apt-get install -y curl unzip \
    && rm -rf /var/lib/apt/lists

RUN curl --location https://taskfile.dev/install.sh | bash -s -- -d

RUN case $TARGETPLATFORM in \
    "linux/amd64") \
      JAVA_FILE="jdk-21_linux-x64_bin.tar.gz"; \
      JAVA_URL="https://download.oracle.com/java/21/latest/$JAVA_FILE"; \
      ;; \
    "linux/arm64") \
      JAVA_FILE="jdk-21_linux-aarch64_bin.tar.gz"; \
      JAVA_URL="https://download.oracle.com/java/21/latest/$JAVA_FILE"; \
      ;; \
    *) \
      echo "Unsupported platform: $BUILDPLATFORM"; exit 1; \
      ;; \
  esac \
    && mkdir -p $JAVA_HOME \
    && curl -L $JAVA_URL -o $JAVA_HOME/$JAVA_FILE \
    && tar -xvzf $JAVA_HOME/$JAVA_FILE --strip-components=1 -C $JAVA_HOME \
    && rm $JAVA_HOME/$JAVA_FILE


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
  && task --version || exit 1

WORKDIR $HOME

CMD ["/bin/bash"]