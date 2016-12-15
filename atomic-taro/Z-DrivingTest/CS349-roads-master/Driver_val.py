import matplotlib.pyplot as pyplot
import numpy as np
import sys
import math
from Trip import Trip
import os
import random
from sklearn.metrics import roc_auc_score
#from sklearn.linear_model import LogisticRegression
from sklearn.ensemble import RandomForestRegressor
from sklearn.ensemble import RandomForestClassifier
from sklearn.svm import SVC
from sklearn.externals import joblib
from sklearn.svm import SVC
import random

num_selfTrips = 180
num_testTrips = 20
num_NOTselfTrips = 400
size = num_testTrips+num_selfTrips


class Driver(object):

	def __init__(self, driverName):
		self.name = driverName


	#we might have to change the rounding at some point, but it's a good way to start
	def calculateResults(self,predicted, true):
		tp = 0
		tn = 0
		fp = 0
		fn = 0

		for i in range (len(true)):
			if (true[i] == 1 and round(predicted[i]) == 1):
				tp+=1
			if (true[i] == 1 and round(predicted[i]) == 0):
				fn+=1
			if (true[i] == 0 and round(predicted[i]) == 1):
				fp+=1
			if (true[i] == 0 and round(predicted[i]) == 0):
				tn+=1

		#print tp, tn, fp, fn
		prec = float(tp)/(tp+fp)
		recall = float(tp)/(tp+fn)
		acc = float (tp+tn)/(tp+tn+fp+fn)
		#print 'Precision: ', prec
		#print 'Recall: ', recall
		auc = roc_auc_score(true, predicted)
		#auc = 0
		return (prec, recall, auc, acc)

	def split_crossval_trials(self):
		f = open("driver_stats/"+str(self.name)+"_selfTrips.csv")
		selfTrips = np.genfromtxt(f, delimiter=',')
		f.close()
		print "split_crossval_trials: loaded self trips"

		g = open("driver_stats/"+str(self.name)+"_NOTtrips.csv")
		othersTrips = np.genfromtxt(g, delimiter=',')
		g.close()
		print "split_crossval_trials: loaded others trips"

		h = open ("answerkey/ans_d"+str(self.name)+".csv")
		answerTarget = np.genfromtxt(h, delimiter=',')
		h.close()
		print "split_crossval_trials: loaded answer key"

		traintrips = []
		testtrips = []
		testLabels =[]

		#not quite cross-val, not 200 choose 20, but faster, possibly okay?
		for start in range(0, 200-num_testTrips+1, num_testTrips):
			end = start + num_testTrips

			test = np.vstack((selfTrips[start:end], othersTrips[start:end]))

			train = np.vstack((selfTrips[:start], selfTrips[end:]))
			train = np.vstack((train, othersTrips[:start]))
			train = np.vstack((train, othersTrips[end:]))
			tlabels = np.hstack((answerTarget[start:end], np.zeros(num_testTrips)))
			traintrips.append(train)
			testtrips.append(test)
			testLabels.append(tlabels)

		#print "sanity check: " + str(traintrips[0][0]) + " vs test " + str(testtrips[0][0])
		print "split_crossval_trials: " + str(len(traintrips)) +" training trips "
		print "split_crossval_trials: " + str(testtrips[0].shape) + " trips per test trips"
		return traintrips, testtrips, testLabels


	def classify_crossval(self):
		traintrips, testtrips, testLabels = self.split_crossval_trials()

		#get list of labels for the trips in traintrips
		g = open("driver_stats/"+str(self.name)+"_trainingLabels.csv")
		trainLabels = np.genfromtxt(g, delimiter=',')
		g.close()

		res = []
		print "starting predictions:"
		for i in range(0, len(traintrips)):
			print "trial " + str(i)
			clf = RandomForestClassifier(random_state=1, n_estimators=500, n_jobs=1, min_samples_leaf=3) 
			#print target
			clf.fit(traintrips[i], trainLabels)
			predLabels = clf.predict (testtrips[i])
			print predLabels
			r = self.calculateResults(predLabels, testLabels[i])
			print r
			res.append(r)

		scoring = np.array(res)
		print str(scoring.shape)
		np.savetxt("driver_stats/"+str(self.name)+"_score.csv", scoring, delimiter=",")





	def classify(self):

		#get training trips for this driver
		f = open("driver_stats/"+str(self.name)+"_training.csv")
		#f.readline() #skip header labels
		traintrips = np.genfromtxt(f, delimiter=',')
		f.close()

		#get list of labels for the trips in traintrips
		g = open("driver_stats/"+str(self.name)+"_trainingLabels.csv")
		target_labels = np.genfromtxt(g, delimiter=',')
		g.close()

		
		#get test trips for this driver
		h = open("driver_stats/"+str(self.name)+"_test.csv")
		testtrips = np.genfromtxt(h, delimiter=',')
		h.close()
		k = open("driver_stats/"+str(self.name)+"_testLabels.csv")
		test_labels = np.genfromtxt(k, delimiter=',')
		k.close() 
		
		#inc = size/5
		res = []
		#for k in range(0,5):
			
		#traintrips, target, testtrips, testtarget = self.splitData(dataset, labels, k)
			
		clf = RandomForestClassifier() 
		
		#print target
		clf.fit(traintrips, target_labels)
		predLabels = clf.predict (testtrips)
		print predLabels
		#print testtarget
		res.append(self.calculateResults(predLabels, test_labels))
		#print self.calculateResults(predLabels, testtarget)
		

		return res
		
		#print clf.score(testtrips, test_target)

		#joblib.dump(clf, "driver_stats/"+str(self.name)+"_clf.pkl")

	def getRandomDriverTrips(self, numtrips):
		notDrivers = os.listdir("../drivers/")
		numNotDrivers = len(notDrivers) #change this parameter to consider a different number
		tripList = []
		for i in range(numtrips):
			dnum = notDrivers[random.randint(1, len(notDrivers) - 1)] #sample a random driver
			while dnum == self.name: #don't sample from self
				dnum = notDrivers[random.randint(1, numNotDrivers - 1)]
			tnum = random.randint(1,200)#sample a random trip
			t = Trip("../drivers/"+str(dnum)+"/"+str(tnum)+".csv")
			tripList.append(t.printFeatures())
		return tripList

	def writeCSV_notDriver(self):
		#list other drivers in directory, since their numbers skip around
		notDrivers = os.listdir("../drivers/")

		g = open ("driver_stats/"+str(self.name)+"_NOTtrips.csv", "w")
		tripList = self.getRandomDriverTrips(num_NOTselfTrips+num_testTrips)
		for other in tripList:
			g.write(other)
		g.close()

	def writeCSV_selfDriver(self):
		g = open ("driver_stats/"+str(self.name)+"_selfTrips.csv", "w")
		for i in range (1, 201): #get features for all driver trips
			t = Trip("../drivers/"+str(self.name)+"/"+str(i)+".csv")
			g.write(t.printFeatures())
		g.close()


	def writeCSV_training(self):
		g = open ("driver_stats/"+str(self.name)+"_training.csv", "w")
		#a header and then the features for each trip
			#g.write("advSpeed,tripDist\n")
		#first trips from this driver
		for i in range (1,num_selfTrips+1):
			t = Trip("../drivers/"+str(self.name)+"/"+str(i)+".csv")
			g.write(t.printFeatures())
		#trips from other drivers
		tripList = self.getRandomDriverTrips(num_NOTselfTrips)
		for other in tripList:
			g.write(other)
		g.close()

	def writeCSV_test_labels(self):
		g = open ("answerkey/ans_d"+str(self.name)+".csv")
		ans = [line.strip() for line in g]
		g.close()

		#file containing training labels, same for any driver
		h = open ("driver_stats/"+str(self.name)+"_testLabels.csv", "w")
		for i in range (num_selfTrips + 1, num_selfTrips + num_testTrips + 1):
			h.write(str(ans[i-1])+"\n")
		for i in range(num_testTrips):
			h.write(str(0)+"\n")#
		h.close()

	def writeCSV_train_labels(self):
		#file containing test labels, same for any driver
		h = open ("driver_stats/"+str(self.name)+"_trainingLabels.csv", "w")
		for i in range(num_selfTrips):
			h.write(str(1)+"\n")
		for i in range(num_NOTselfTrips):
			h.write(str(0)+"\n")
		h.close()

	def writeCSV_test(self):
		g = open ("driver_stats/"+str(self.name)+"_test.csv", "w")
		#first trips from this driver
		for i in range (num_selfTrips + 1, num_selfTrips + num_testTrips +1):
			t = Trip("../drivers/"+str(self.name)+"/"+str(i)+".csv")
			g.write(t.printFeatures())
		#trips from other drivers
		tripList = self.getRandomDriverTrips(num_testTrips)
		for other in tripList:
			g.write(other)
		g.close()
	
	def createDataSets(self):
		#order = [i for i in range(1, 201)]
		#random.shuffle(order)
		self.writeCSV_training()
		print "wrote training trips"

		self.writeCSV_train_labels()
		print "wrote training labels"

		self.writeCSV_test()
		print "wrote test trips"

		self.writeCSV_test_labels()
		print "wrote test labels"

	def createDataSets_crossval(self):
		self.writeCSV_notDriver()
		print "prepared csv of Not Driver trips"

		self.writeCSV_train_labels()
		print "wrote training labels, can use for all sets"

		self.writeCSV_selfDriver()
		print "wrote feature vector for all Self Driver trips"



d1 = Driver(sys.argv[1])
#d1.createDataSets()
d1.createDataSets_crossval()
d1.split_crossval_trials()
print d1.classify_crossval()


"""d2 = Driver(sys.argv[2])

pyplot.hist(d1.advSpeed, 10, color='blue')
pyplot.hist(d2.advSpeed, 10, color='red')
pyplot.show()"""

"""
fig = pyplot.figure()
f_dist = fig.add_subplot(111)
f_dist.scatter(d1.distance, d1.advSpeed, c='b')
f_dist.scatter(d2.distance, d2.advSpeed, c='r')
pyplot.show()"""