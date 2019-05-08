FROM rocker/r-apt:bionic

RUN apt-get update && \
    apt-get install -y -qq \
    	r-cran-caret \
    	r-cran-pls \
    	r-cran-e1071

RUN R -e 'install.packages("doParallel")'

RUN mkdir training
COPY /train.R /training/train.R
COPY /get_data.sh /training/get_data.sh
COPY ./train.sh /training/train.sh

RUN cd /training && \
    ./get_data.sh

WORKDIR /training

CMD ["/training/train.sh"]