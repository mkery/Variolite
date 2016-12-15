#This program creates a driver object, and contains methods for creating datasets to be used as training/testing data and executing a classification task.

import matplotlib.pyplot as pyplot
import numpy as np
import sys
import math
from Trip import Trip
import os
import random
from sklearn.metrics import roc_auc_score
from sklearn.ensemble import RandomForestClassifier
from sklearn.svm import SVC
from sklearn.externals import joblib
from sklearn.svm import SVC
import random


num_selfTrips = 160
num_testTrips = 40
num_NOTselfTrips = 160
size = num_testTrips+num_selfTrips
cv = 5 #number of cross-validation trials


class Driver(object):

	def __init__(self, driverName):
		self.name = driverName


	#takes arrays corresponding to the predicted and true labels of the dataset
	#computes and returns the precision, recall, area under the receiver operating characteristic curve (auc), and accuracy
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

	#takes two arrays corresponding to the whole dataset and the corresponding labels and a number k,
	#corresponding to the current trial number out of the series of 5 cross-validation trials
	#returns four lists corresponding to the training data, training labels, testing data, and testing labels respectively
	def splitData(self, data, labels, k):

		traintrips = []
		target = []
		testtrips = []
		testtarget =[]
		inc = size/cv
		#print len (data)
		#print size*2
		for i in range (size*2):

			if (i>=(k*inc) and i<(k+1)*inc) or (i>=((k+cv)*inc) and i<((k+(cv+1))*inc)):
				testtrips.append(data[i])
				testtarget.append(labels[i])
			else:
				traintrips.append(data[i])
				target.append(labels[i])


		return traintrips, target, testtrips, testtarget


	#reads in two files containing the dataset and the data labels and executes 5-fold cross-validation
	#returns the results of the 5 trials in a list
	def classify(self):

		#get training trips for this driver
		f = open("driver_stats/"+str(self.name)+"_training.csv")
		#f.readline() #skip header labels
		#traintrips 
		dataset = np.genfromtxt(f, delimiter=',')
		f.close()

		#get list of labels for the trips in traintrips
		g = open("driver_stats/trainingLabels.csv")
		#target
		labels = np.genfromtxt(g, delimiter=',')
		g.close()

		

		inc = size/cv
		res = []
		for k in range(cv):
			#divide data
			traintrips, target, testtrips, testtarget = self.splitData(dataset, labels, k)
			
			#set up classifier
			clf = RandomForestClassifier(n_estimators=500)
			clf.fit(traintrips, target)
			predLabels = clf.predict (testtrips)
			#print predLabels
			#print testtarget

			#save results
			res.append(self.calculateResults(predLabels, testtarget))
			#print self.calculateResults(predLabels, testtarget)
		return res
	
	#takes a number of trips to be sampled, number of drivers to be sampled from, and binary string specifying features
	#sample random trips from a given number of random drivers
	#returns a list of sample trips	
	def getRandomDriverTrips(self, numtrips, numNotDrivers, feat):

		#get list of drivers and shuffle
		notDrivers = os.listdir("../drivers/")
		copy = notDrivers[1:]
		random.shuffle(copy)
		notDrivers[1:] = copy

		#process number of 'other' drivers
		if numNotDrivers == 0 or numNotDrivers >= len(notDrivers):
			numNotDrivers = len(notDrivers)-1

		#if we are comparing to only one driver and that driver is the same as the original driver
		if numNotDrivers == 1:
			while notDrivers[1] == self.name:
				copy = notDrivers[1:]
				random.shuffle(copy)
				notDrivers[1:] = copy

		#sample trips and output desired features
		tripList = []
		for i in range(numtrips):
			dnum = notDrivers[random.randint(1, numNotDrivers)] #sample a random driver
			#print self.name  + " " + dnum
			while dnum == self.name: #don't sample from self
				dnum = notDrivers[random.randint(1, numNotDrivers)]
			tnum = random.randint(1,200)#sample a random trip
			t = Trip("../drivers/"+str(dnum)+"/"+str(tnum)+".csv", feat)
			tripList.append(t.printFeatures())

		return tripList

	#creates a CSV file containing the full dataset
	def writeCSV(self, order, numNotDrivers, feat):
		g = open ("driver_stats/"+str(self.name)+"_training.csv", "w")
		
		#first trips from this driver
		for i in range (0,num_selfTrips+num_testTrips):
			#print i
			t = Trip("../drivers/"+str(self.name)+"/"+str(order[i])+".csv", feat)
			g.write(t.printFeatures())

		#trips from other drivers
		tripList = self.getRandomDriverTrips(num_NOTselfTrips+num_testTrips, numNotDrivers, feat)
		for other in tripList:
			g.write(other)
		g.close()

	#creates a csv file containing the labels: 1-trip was made by driver in question, 0-trip was made by one of the 'other' drivers
	def writeCSV_labels(self):
		#file containing training labels, same for any driver
		h = open ("driver_stats/"+"trainingLabels.csv", "w")
		for i in range(num_selfTrips+num_testTrips):
			h.write(str(1)+"\n")
		for i in range(num_NOTselfTrips+num_testTrips):
			h.write(str(0)+"\n")
		h.close()

	#creates all necessary datasets for a given classification task
	def createDataSets(self, numNotDrivers, feat):
		order = [i for i in range(1, 201)]
		random.shuffle(order)
		self.writeCSV(order, numNotDrivers, feat)
		self.writeCSV_labels()
		



#d1 = Driver(sys.argv[1])
#d1.createDataSets()
#print d1.classify()
