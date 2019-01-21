import tensorflow as tf
import logging
logging.basicConfig(format='%(asctime)s.%(msecs)03d %(levelname)s {%(module)s} [%(funcName)s] %(message)s', datefmt='%Y-%m-%d,%H:%M:%S', level=logging.INFO)
logger = logging.getLogger(__name__)

class DeepMnist(object):
    def __init__(self):
        self.class_names = ["class:{}".format(str(i)) for i in range(10)]
        self.sess = tf.Session()
        saver = tf.train.import_meta_graph("/data/deep_mnist_model.meta")
        saver.restore(self.sess,tf.train.latest_checkpoint("/data/"))

        graph = tf.get_default_graph()
        self.x = graph.get_tensor_by_name("x:0")
        self.y = graph.get_tensor_by_name("y:0")

    def predict(self,X,feature_names):
        predictions = self.sess.run(self.y,feed_dict={self.x:X})
        return predictions

    
