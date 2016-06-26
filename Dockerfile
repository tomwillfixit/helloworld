FROM alpine:3.3

MAINTAINER tomwillfixit 

RUN apk update && rm -rf /var/cache/apk/*

COPY helloworld.bin / 

EXPOSE 80

ENTRYPOINT ["/helloworld.bin"]

