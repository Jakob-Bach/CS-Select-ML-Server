FROM rocker/r-base
LABEL maintainer="Jakob Bach <jakob.bach@kit.edu>"

RUN mkdir -p /CSSelectMLServer/
WORKDIR /CSSelectMLServer/
COPY ./ ./
RUN Rscript Setup.R

EXPOSE 8000
ENTRYPOINT ["Rscript", "RunMLServer.R"]
