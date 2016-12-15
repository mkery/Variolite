import numpy as np
import sys
import matplotlib.pyplot as pyplot
import rdp_trip as rdp
import findMatches as findMatches

driver = sys.argv[1]
driverB = 2
"""
for i in range(1,201):
	print "generating rdp for "+str(driver)+" trip "+str(i)
	rdp.generateRDP(str(driver)+"_"+str(i), str(driver), str(i))
"""
results = []

for i in range(1,2):
	aa = open("driver"+str(driver)+"/"+str(driver)+"_"+str(i)+"_angle_dist.csv")
	tripA = np.genfromtxt(aa, delimiter=',')
	aa.close()
	ardp = open("driver"+str(driver)+"/"+str(driver)+"_"+str(i)+"_rdp.csv")
	tripA_rdp = np.genfromtxt(ardp, delimiter=',')
	ardp.close()
	for j in range(1,200):
		if j != i:
			aa = open("driver"+str(driver)+"/"+str(driver)+"_"+str(j)+"_angle_dist.csv")
			tripB = np.genfromtxt(aa, delimiter=',')
			aa.close()
			ardp = open("driver"+str(driver)+"/"+str(driver)+"_"+str(j)+"_rdp.csv")
			tripB_rdp = np.genfromtxt(ardp, delimiter=',')
			ardp.close()
			res = findMatches.matchTrips(tripA, tripA_rdp, tripB, tripB_rdp)
			print "trips "+str(i)+" : "+str(j)+"  "+str(res)
			results.append(findMatches.matchTrips(tripA, tripA_rdp, tripB, tripB_rdp))


np.savetxt(str(driver)+"_matchres.csv", results, delimiter=",")