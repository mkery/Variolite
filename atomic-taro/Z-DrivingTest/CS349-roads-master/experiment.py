#This program carries out an experiment consisting on m trials (each consisting of 5 sample runs) with a specified feature set; 
#it takes in the following parameters:
#number m - number of randomly selected drivers on which the model will be tested,
#number n - number of 'other' drivers for each trial, 0 for all drivers,
#binary string of length at most 16 specifying which features to be used (see numbering in readme file)
#file name specifying where the results should be stored. 
#Note that the program outputs values for precision, recall, f1 score, and auc for each trial.

import os
import sys
from Driver import Driver
import random

#get a list of drivers
drivers = os.listdir("../drivers/")
copy = drivers[1:]
random.shuffle(copy)
drivers[1:]=copy


#store input parameters
m = int(sys.argv[1]) #number of drivers in total
n = int(sys.argv[2]) #number of drivers to compare against
feat = sys.argv[3] #binary sequence corresponding to features
g = open (sys.argv[4], "w")
g.write("driver,precision,recall,f1,auc\n")
g.close()

#run experiment on m randomly chosen drivers
for i in range(1, m+1):
	g = open (sys.argv[4], "a") #so we can be able to see the contents as the file is being written
	#print drivers[i]
	
	#execute classification
	d = Driver(drivers[i])
	d.createDataSets(n, feat)
	results = d.classify()

	#output results
	for res in results:
		f1 = 2*(res[0]*res[1])/(res[0]+res[1])
		g.write (drivers[i] + ","+ str(res[0]) + "," + str(res[1]) + "," +str(f1) +"," + str(res[2])+'\n')
	#sys.exit()
	g.close()



