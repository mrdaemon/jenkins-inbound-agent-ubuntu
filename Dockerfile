# I'm terribly sorry about all of this.

ARG UBUNTU_RELEASE=22.04

FROM ubuntu:"${UBUNTU_RELEASE}" AS builder

ARG JAVA_VERSION=17.0.15_6
ARG TARGETPLATFORM

SHELL ["/bin/bash", "-e", "-u", "-o", "pipefail", "-c"]

COPY files/adoptium-get-jdk-link.sh /usr/local/bin/adoptium-get-jdk-link.sh
COPY files/adoptium-install-jdk.sh /usr/local/bin/adoptium-install-jdk.sh

RUN set -x ; chmod +x /usr/local/bin/adoptium-get-jdk-link.sh \
    && chmod +x /usr/local/bin/adoptium-install-jdk.sh \
    && apt-get update \
    && apt-get install --no-install-recommends -y \
        curl \ 
        ca-certificates \
        jq \
    && /usr/local/bin/adoptium-install-jdk.sh

ENV PATH="/opt/jdk-${JAVA_VERSION}/bin:${PATH}"

# Generate smaller java runtime without unneeded files
# for now we include the full module path to maintain compatibility
# while still saving space (approx 200mb from the full distribution)
RUN if [[ "${TARGETPLATFORM}" != "linux/arm/v7" ]]; then \
    case "$(jlink --version 2>&1)" in \
      "17."*) set -- "--compress=2" ;; \
      # the compression argument is different for JDK21
      "21."*) set -- "--compress=zip-6" ;; \
      *) echo "ERROR: unmanaged jlink version pattern" && exit 1 ;; \
    esac; \
    jlink \
      --strip-java-debug-attributes \
      "$1" \
      --add-modules ALL-MODULE-PATH \
      --no-man-pages \
      --no-header-files \
      --output /javaruntime; \
  else \
    # It is acceptable to have a larger image in arm/v7 (arm 32 bits) environment.
    # Because jlink fails with the error "jmods: Value too large for defined data type" error.
    cp -r "/opt/jdk-${JAVA_VERSION}" /javaruntime; \
  fi

# Agent Image
FROM ubuntu:"${UBUNTU_RELEASE}" AS agent

ARG user=jenkins
ARG group=jenkins
ARG uid=1000
ARG gid=1000

RUN groupadd --gid "${gid}" "${group}" \
    && useradd --shell /bin/bash --create-home --uid "${uid}" --gid "${gid}" "${user}"

ARG AGENT_WORKDIR=/home/${user}/agent
ENV TZ=Etc/UTC

ENV DEBIAN_FRONTEND=noninteractive
RUN apt-get update \
    && apt-get install --no-install-recommends -y \
        ca-certificates \
        curl \
        fontconfig \
        git \
        git-lfs \
        less \
        netbase \
        openssh-client \
        patch \
        tzdata \
    && apt-get clean \
    && rm -rf /tmp/* /var/cache/* /var/lib/apt/lists/*

ARG AGENT_VERSION=3309.v27b_9314fd1a_4
ADD --chown="${user}":"${group}" "https://repo.jenkins-ci.org/public/org/jenkins-ci/main/remoting/${AGENT_VERSION}/remoting-${AGENT_VERSION}.jar" /usr/share/jenkins/agent.jar
RUN chmod 0644 /usr/share/jenkins/agent.jar \
    && ln -sf /usr/share/jenkins/agent.jar /usr/share/jenkins/slave.jar

ENV LANG=C.UTF-8

ENV JAVA_HOME=/opt/java/openjdk
COPY --from=builder /javaruntime "${JAVA_HOME}"
ENV PATH="${JAVA_HOME}/bin:${PATH}"

USER "${user}"
ENV AGENT_WORKDIR="${AGENT_WORKDIR}"
RUN mkdir -p /home/"${user}"/.jenkins \
    && mkdir -p "${AGENT_WORKDIR}" \
    && chown -R "${user}":"${group}" /home/"${user}"/.jenkins \
    && chown -R "${user}":"${group}" "${AGENT_WORKDIR}"

VOLUME /home/"${user}"/.jenkins
VOLUME "${AGENT_WORKDIR}"
WORKDIR "/home/${user}"
ENV USER=${user}

# Inbound Agent (resultant image)
FROM agent

ARG user=jenkins

USER root
COPY files/jenkins-agent /usr/local/bin/jenkins-agent
RUN chmod +x /usr/local/bin/jenkins-agent \
    && ln -sf /usr/local/bin/jenkins-agent /usr/local/bin/jenkins-slave

USER "${user}"

ENTRYPOINT ["/usr/local/bin/jenkins-agent"]