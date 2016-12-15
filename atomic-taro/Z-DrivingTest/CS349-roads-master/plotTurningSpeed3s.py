#from mpl_toolkits.mplot3d import axes3d
import matplotlib.pyplot as plt
import numpy as np
#from pylab import *
import sys
import math
import rdp_trip as rdp

def computeNorm(x, y):
	return math.sqrt (x**2 + y**2)

def computeAngle (p1, p2):
	dot = 0
	if computeNorm(p2[0], p2[1]) == 0 or computeNorm(p1[0], p1[1])==0: #may be incorrect
		dot = 0
	else:
		dot = (p2[0]*p1[0]+p2[1]*p1[1])/float(computeNorm(p1[0], p1[1])*computeNorm(p2[0], p2[1])) 

	if dot > 1:
		dot = 1
	elif dot < -1:
		dot = -1

	return math.acos(dot)*180/math.pi


doc = sys.argv[1]
f = open (sys.argv[1], "r")

data = f.read().split()

#print data

x = []
y = []
z = []
v = []
dV = []
t = [] #angles
sharpTurns = []
angleOrigin = []

for ind in range (1, len(data)):
	location = data[ind].split(",")
	x.append(float(location[0]))
	y.append(float(location[1]))
	z.append(ind-1)



v.append(0)

maxSp = 0
for ind in range (1, len(z)):
	sp = 3.6*computeNorm((x[ind]-x[ind-1]), (y[ind]-y[ind-1])) 
	v.append(sp)
	dV.append(((x[ind]-x[ind-1]),(y[ind]-y[ind-1])))
	#angleOrigin.append(computeAngle((1,0), (x[ind], y[ind])))

#print dV

t.append([])
t.append([])
t.append([])

sharpTurns.append([])
sharpTurns.append([])
sharpTurns.append([])

for ind in range (2, len(dV)):

	angle = computeAngle(dV[ind-2], dV[ind])
	t[0].append(ind)
	t[1].append(angle)
	t[2].append((v[ind-2]+v[ind-1]+v[ind])/3)

	"""
	if angle > 60:
		sharpTurns[0].append(ind)
		sharpTurns[1].append(v[ind])
		sharpTurns[2].append(angle)
    """
	


plt.subplot (2, 1, 1)
plt.plot(t[0], t[1], "b-", t[0], t[2], "r-")#, sharpTurns[0], sharpTurns[2], "r.") #z[1:], angleOrigin, "k-")
plt.xlabel("Time")
plt.ylabel("Turning Angle")
plt.subplot (2, 1, 2)
plt.plot(t[1], t[2], "bx")#, sharpTurns[2], sharpTurns[1], "rx")
plt.xlabel("Time")
plt.ylabel("Speed")
plt.xlabel("Turning Angle")
	
"""	
plt.subplot (2, 1, 1)	
plt.plot(z, v, "b-", z, a, "r-", [0, len(z)], [0,0], "k-")
plt.xlabel("Time")
plt.ylabel("Speed/Acceleration")

plt.subplot (2, 1, 2)	
plt.plot(v, a, "b-", [0, maxSp], [0,0], "k-")
plt.xlabel("Speed")
plt.ylabel("Acceleration")
"""
plt.show()

f.close()
		



