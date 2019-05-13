FROM python:3.7-slim

RUN apt-get update -y
RUN apt-get install -y python-pip python-dev build-essential

COPY /requirements.txt /tmp/
RUN cd /tmp && \
    pip install --no-cache-dir -r requirements.txt

RUN mkdir training
COPY ./create_model.py /training/create_model.py
COPY ./train.sh /training/train.sh
WORKDIR /training

CMD ["/training/train.sh"]
