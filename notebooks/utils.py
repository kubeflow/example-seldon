import requests
from requests.auth import HTTPBasicAuth
from random import randint,random
from proto import prediction_pb2
from proto import prediction_pb2_grpc
import grpc
import json
from visualizer import get_graph
from matplotlib import pyplot as plt
import numpy as np
from tensorflow.examples.tutorials.mnist import input_data
from google.protobuf.json_format import MessageToJson

AMBASSADOR_API_IP="localhost:8002"

def rest_request(deploymentName,request):
    response = requests.post(
                "http://"+AMBASSADOR_API_IP+"/seldon/"+deploymentName+"/api/v0.1/predictions",
                json=request)
    j = response.json()
    return j
    
def rest_request_auth(deploymentName,data,username,password):
    payload = {"data":{"ndarray":data.tolist()}}
    response = requests.post(
                "http://"+AMBASSADOR_API_IP+"/seldon/"+deploymentName+"/api/v0.1/predictions",
                json=payload,
                auth=HTTPBasicAuth(username, password))
    print(response.status_code)
    return response.json()   

def grpc_request(deploymentName,data):
    datadef = prediction_pb2.DefaultData(
            names = ["a","b"],
            tensor = prediction_pb2.Tensor(
                shape = [1,784],
                values = data
                )
            )
    request = prediction_pb2.SeldonMessage(data = datadef)
    channel = grpc.insecure_channel(AMBASSADOR_API_IP)
    stub = prediction_pb2_grpc.SeldonStub(channel)
    metadata = [('seldon',deploymentName)]
    response = stub.Predict(request=request,metadata=metadata)
    return response

def send_feedback_rest(deploymentName,request,response,reward):
    feedback = {
        "request": request,
        "response": response,
        "reward": reward
    }
    ret = requests.post(
         "http://"+AMBASSADOR_API_IP+"/seldon/"+deploymentName+"/api/v0.1/feedback",
        json=feedback)
    return ret.text


def gen_image(arr):
    two_d = (np.reshape(arr, (28, 28)) * 255).astype(np.uint8)
    plt.imshow(two_d,cmap=plt.cm.gray_r, interpolation='nearest')
    return plt

def download_mnist():
    return input_data.read_data_sets("MNIST_data/", one_hot = True)


def predict_rest_mnist(mnist):
    batch_xs, batch_ys = mnist.train.next_batch(1)
    chosen=0
    gen_image(batch_xs[chosen]).show()
    data = batch_xs[chosen].reshape((1,784))
    features = ["X"+str(i+1) for i in range (0,784)]
    request = {"data":{"names":features,"ndarray":data.tolist()}}
    predictions = rest_request("mnist-classifier",request)
    print(json.dumps(predictions,indent=2))
    #print("Route:"+json.dumps(predictions["meta"]["routing"],indent=2))
    fpreds = [ '%.2f' % elem for elem in predictions["data"]["ndarray"][0] ]
    m = dict(zip(predictions["data"]["names"],fpreds))
    print("Returned probabilities")
    print(json.dumps(m,indent=2))



def predict_grpc_mnist(mnist):
    batch_xs, batch_ys = mnist.train.next_batch(1)
    chosen=0
    gen_image(batch_xs[chosen]).show()
    data = batch_xs[chosen].reshape((784))
    resp = grpc_request("mnist-classifier",data)
    predictions = MessageToJson(resp)
    predictions = json.loads(predictions)
    print(json.dumps(predictions,indent=2))    
    fpreds = [ '%.2f' % elem for elem in predictions["data"]["tensor"]["values"] ]
    m = dict(zip(predictions["data"]["names"],fpreds))
    print("Returned probabilities")    
    print(json.dumps(m,indent=2))

def evaluate_abtest(mnist,sz=100):
    batch_xs, batch_ys = mnist.train.next_batch(sz)
    routes_history = []
    for idx in range(sz):
        if idx % 10 == 0:
            print("{}/{}".format(idx,sz))
        data = batch_xs[idx].reshape((1,784))
        request = {"data":{"ndarray":data.tolist()}}
        response = rest_request("mnist-classifier",request)
        route = response.get("meta").get("routing").get("random-ab-test")
        routes_history.append(route)

    plt.figure(figsize=(15,6))
    ax = plt.scatter(range(len(routes_history)),routes_history)
    ax.axes.xaxis.set_label_text("Incoming Requests over Time")
    ax.axes.yaxis.set_label_text("Selected Branch")
    plt.yticks([0,1,2])
    _ = plt.title("Branch Chosen for Incoming Requests")


def evaluate_egreedy(mnist,sz=100):
    score = [0.0,0.0,0.0]
    sz = 100
    batch_xs, batch_ys = mnist.train.next_batch(sz)
    routes_history = []
    for idx in range(sz):
        if idx % 10 == 0:
            print("{}/{}".format(idx,sz))
        data = batch_xs[idx].reshape((1,784))
        request = {"data":{"ndarray":data.tolist()}}
        response = rest_request("mnist-classifier",request)
        route = response.get("meta").get("routing").get("eg-router")
        proba = response["data"]["ndarray"][0]
        predicted = proba.index(max(proba))
        correct = np.argmax(batch_ys[idx])
        if predicted == correct:
            score[route] = score[route] + 1
            send_feedback_rest("mnist-classifier",request,response,reward=1)
        else:
            send_feedback_rest("mnist-classifier",request,response,reward=0)
        routes_history.append(route)

    plt.figure(figsize=(15,6))
    ax = plt.scatter(range(len(routes_history)),routes_history)
    ax.axes.xaxis.set_label_text("Incoming Requests over Time")
    ax.axes.yaxis.set_label_text("Selected Branch")
    plt.yticks([0,1,2])
    _ = plt.title("Branch Chosen for Incoming Requests")
    print(score)    

    
