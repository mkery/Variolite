import numpy as np
import sys
import matplotlib.pyplot as pyplot

"""
edited 4/25 to fit trip default numpy format
If you import a trip and then add a 3rd column to the trip that is time,
when this runs the time field is kept... a bit hacky but works.
"""

def distance(x0, y0, x1, y1):
    return ((x1-x0)**2 + (y1-y0)**2) ** (.5)

def unit_vector(v):
    v_len = (v[0]**2 + v[1]**2)**0.5
    return [v[0]/v_len, v[1]/v_len]

# get angle between 3 points in radians
def angle_3_points(x1, y1, x2, y2, x3, y3):
    v1 = [x2-x1, y2-x1]
    v2 = [x2-x3, y2-y3]
    v1_unit = unit_vector(v1)
    v2_unit = unit_vector(v2)
    angle = np.arccos(np.dot(v1_unit, v2_unit))
    if np.isnan(angle):
        if(v1_unit == v2_unit).all():
            return 0.0
        else:
            return np.pi
    return angle

def dist_point_to_line(x0, x1, x2):
    """ Calculates the distance from the point ``x0`` to the line given
    by the points ``x1`` and ``x2``, all numpy arrays """
    #print str(x0)+", "+ str(x1)+", "+str(x2)
    if x1[0] == x2[0]:
        return np.abs(x0[0] - x1[0])

    return np.divide(np.linalg.norm(np.linalg.det([x2 - x1, x1 - x0])),
                     np.linalg.norm(x2 - x1))


def rdp_simplify(trip, epsilon):
    # find the point with the maximum distance
    dmax = 0
    index = 0
    for i in range(1, trip.shape[0]): #every point but first and last
        d = dist_point_to_line( np.array([trip[i][0], trip[i][1]]),
                    np.array([trip[0][0], trip[0][1]]),
                    np.array([trip[-1][0], trip[-1][1]]) )
        if (d > dmax):
            index = i
            dmax = d
    # If max distance is greater than epsilon, recursively simplify
    if (dmax > epsilon):
        #build the result list
        res1 = rdp_simplify(trip[:index+1], epsilon)
        res2 = rdp_simplify(trip[index:], epsilon)
        return np.vstack((res1[:-1], res2)) #not sure why [:-1] works, but it keeps duplicates from happening
    else:
        return np.vstack((trip[0],trip[-1]))

#takes an rdp simplified trip and interpolates to evenly fill out time points
#so far.... not helpful
def rdp_format_expand(trip, triplen):
    xs = trip[:,0]
    ys = trip[:,1]
    times = trip[:,2]

    xs_interp = np.interp(range(0,triplen), times, xs)
    ys_interp = np.interp(range(0,triplen), times, ys)
    return np.append(xs_interp.reshape(xs_interp.shape[0],1), ys_interp.reshape(ys_interp.shape[0],1), 1)


def rdp_format_angdist(trip):
    angdists = []
    for i in range(1, trip.shape[0]-1):
        x1 = trip[i-1][0]
        y1 = trip[i-1][1]
        ind1 = i-1

        x2 = trip[i][0]
        y2 = trip[i][1]
        ind2 = i

        x3 = trip[i+1][0]
        y3 = trip[i+1][1]
        ind3 = i+1

        dist = (distance(x1, y1, x3, y3))
        ang = (angle_3_points(x1, y1, x2, y2, x3, y3))*180/np.pi #to degrees
        angdists.append((ang, dist, ind1, ind2, ind3))
    return np.array(angdists)


def generateRDP(letter, driverN, tripN):
    """letter = sys.argv[1] #ex, A or B or C, testing
    driverN = sys.argv[2]
    tripN = sys.argv[3]"""

    tripPath = np.genfromtxt("../../drivers/"+driverN+"/"+tripN+".csv", delimiter=',', skip_header=1)
    #add a column for time in seconds (so if we chop data, still have timepoints)
    tripPath = np.append(tripPath, np.arange(tripPath.shape[0]).reshape(tripPath.shape[0],1),1)
    rdp = rdp_simplify(tripPath, epsilon = 0.75)
    print "rdp simplification complete"
    #print str(rdp)
    #rdp = tripPath
    angdists = rdp_format_angdist(rdp)
    #angdists = angdists[angdists[:,1].argsort()] #sort by distance
    #angdists = angdists[::-1,:] #reverse to put in descending order

    """
    pyplot.figure(1)
    pyplot.subplot(211)
    pyplot.scatter(angdists[:,0], angdists[:,1])

    pyplot.subplot(212)
    pyplot.plot(tripPath[:,0], tripPath[:,1], 'rx')
    pyplot.plot(rdp[:,0], rdp[:,1], 'bo')
    pyplot.show()
    """

    np.savetxt(letter+"_rdp.csv", rdp, delimiter=",")
    np.savetxt(letter+"_angle_dist.csv", angdists, delimiter=",")

        #pyplot.show()"""