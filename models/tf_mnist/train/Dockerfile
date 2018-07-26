FROM tensorflow/tensorflow:1.3.0

RUN mkdir training
COPY ./create_model.py /training/create_model.py
WORKDIR /training

CMD ["python","-u","create_model.py"]
