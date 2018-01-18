FROM openjdk:latest

ARG artifact_root="."

ENV JM_SCRIPT=aa-base ACME_WEB_HOST=acmeair-web ACME_WEB_PORT=3000 CONCUR_THREAD=100

COPY $artifact_root/build.sh /build.sh
COPY $artifact_root/entrypoint.sh /entrypoint.sh
COPY $artifact_root/code/ /code/

RUN chmod +x /build.sh /entrypoint.sh && /build.sh

WORKDIR /usr/src/app

ENTRYPOINT ["/entrypoint.sh"]
