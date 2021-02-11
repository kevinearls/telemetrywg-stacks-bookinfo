FROM golang
LABEL maintainer="Kevin Earls <kearls@redhat.com>"
RUN go get -u github.com/tsenart/vegeta

ADD traffic-generator.sh .
CMD (./traffic-generator.sh)
