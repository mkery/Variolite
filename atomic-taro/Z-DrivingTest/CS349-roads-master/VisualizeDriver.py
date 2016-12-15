import matplotlib.pyplot as pyplot
from math import hypot
import numpy as np
import os
import rdp_trip
import sys

def distance(x0, y0, x1, y1):
    """Computes 2D euclidean distance"""
    return hypot((x1 - x0), (y1 - y0))

def findStops(speeds):
	stops = [] #stops are a start and end time pair
	start = -1
	end = -1
	for i in range(1, len(speeds)):
		advS = (speeds[i] + speeds[i-1])/2 #smooth out noise in stop duration
		if speeds[i] == 0: #start of stop
			end = i
			if start == -1:
				start = i
		elif start > -1 and advS > 1: 
			stops.append([start,end])
			start = -1
			end = -1
	if start > -1:
		stops.append([start, len(speeds)])
	return stops

def velocities_and_distance_covered(trip):
	"""
    Returns velocities just using difference in distance between coordinates as well as accumulated distances

    Input: x-coordinates and y-coordinates as lists
    Output: list of velocities
    """
	v = []
	distancesum = 0.0
	for i in range(1, len(trip)):
		dist = distance(trip[i-1][0], trip[i-1][1], trip[i][0], trip[i][1])
		v.append(dist)
		distancesum += dist
	return v, distancesum

def plotTrip(filename):
	tripName = int(os.path.basename(filename).split(".")[0])
	tripPath = np.genfromtxt(filename, delimiter=',', skip_header=1, dtype=(float,float))

	reducedTrip = rdp_trip.rdp(tripPath, epsilon=0.75)
	v, distancesum = velocities_and_distance_covered(tripPath)
	stops = findStops(v)

	"""pyplot.figure(1)
	pyplot.subplot(211)"""
	startPoint = (tripPath[0][0], tripPath[1][1]) 
	pyplot.plot(tripPath[:,0], tripPath[:,1], 'bx', startPoint[0], startPoint[1], 'bs')
	for (x, y) in reducedTrip:
   		 pyplot.plot(x, y, 'ro')
   		 print str((x,y))
   	for (st,en) in stops:
   		 pyplot.plot(tripPath[st][0], tripPath[st][1], "go")

	pyplot.ylabel('y')
	pyplot.xlabel('x')
	pyplot.show()
	"""pyplot.subplot(212)
	pyplot.plot(v, label='velocity')
	pyplot.show()"""


doc = sys.argv[1]
plotTrip(doc)