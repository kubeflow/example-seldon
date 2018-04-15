FROM rocker/r-base

RUN apt-get update -qq && apt-get install -y \
      git-core \
      libssl-dev \
      libcurl4-gnutls-dev

COPY /install.R /tmp/
RUN cd /tmp && \
    Rscript install.R


RUN mkdir training
COPY /train.R /training/train.R
COPY /get_data.sh /training/get_data.sh

RUN cd /training && \
    ./get_data.sh

WORKDIR /training

CMD ["Rscript","train.R"]
