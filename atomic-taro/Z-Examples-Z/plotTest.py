# from https://github.com/mkery/CS349-roads/blob/master/VisualizeDriver.py

#%%^%%v0-1
def plotTrip(filename):
	tripName = int(os.path.basename(filename).split(".")[0])
	tripPath = np.genfromtxt(filename, delimiter=',', skip_header=1, dtype=(float,float))

	reducedTrip = rdp_trip.rdp(tripPath, epsilon=0.75)
	v, distancesum = velocities_and_distance_covered(tripPath)
	stops = findStops(v)

	pyplot.figure(1)
	pyplot.subplot(211)
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
	pyplot.subplot(212)
	pyplot.plot(v, label='velocity')
	pyplot.show()
#^^%^^
