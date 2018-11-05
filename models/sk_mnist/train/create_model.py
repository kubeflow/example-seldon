from sklearn.ensemble import RandomForestClassifier
from sklearn import datasets, metrics
from sklearn.utils import shuffle
from sklearn.datasets import fetch_mldata
from sklearn.externals import joblib
from six.moves import urllib

if __name__ == '__main__':
    try:
        mnist = fetch_mldata('MNIST original')
    except:
        print("Could not download MNIST data from mldata.org, trying alternative...")

        # Alternative method to load MNIST, if mldata.org is down
        from scipy.io import loadmat
        mnist_alternative_url = "https://github.com/amplab/datascience-sp14/raw/master/lab7/mldata/mnist-original.mat"
        mnist_path = "./mnist-original.mat"
        response = urllib.request.urlopen(mnist_alternative_url)
        with open(mnist_path, "wb") as f:
            content = response.read()
            f.write(content)
        mnist_raw = loadmat(mnist_path)
        mnist = {
            "data": mnist_raw["data"].T,
            "target": mnist_raw["label"][0],
            "COL_NAMES": ["label", "data"],
            "DESCR": "mldata.org dataset: mnist-original",
        }
        print("Success!")

    #mnist = fetch_mldata('MNIST original', data_home="./mnist_sklearn")
    # To apply a classifier on this data, we need to flatten the image, to
    # turn the data in a (samples, feature) matrix:
    n_samples = len(mnist['data'])
    data = mnist['data'].reshape((n_samples, -1))
    targets = mnist['target']

    data,targets = shuffle(data,targets)
    classifier = RandomForestClassifier(n_estimators=30)

    # We learn the digits on the first half of the digits
    classifier.fit(data[:n_samples // 2], targets[:n_samples // 2])

    # Now predict the value of the digit on the second half:
    expected = targets[n_samples // 2:]
    test_data = data[n_samples // 2:]

    print(classifier.score(test_data, expected))

    predicted = classifier.predict(data[n_samples // 2:])

    print("Classification report for classifier %s:\n%s\n"
          % (classifier, metrics.classification_report(expected, predicted)))
    print("Confusion matrix:\n%s" % metrics.confusion_matrix(expected, predicted))

    joblib.dump(classifier, '/data/sk.pkl') 


