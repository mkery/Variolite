import numpy as np
import sys
import matplotlib.pyplot as pyplot


def matchAngles(tripA, tripB, angle_min = 5, dist_min = 5):
	matches = []

	for i in range(0, tripA.shape[0]):
		angleA = tripA[i][0]
		distA = tripA[i][1]

		#find closest match angle to this one, keep track of min's index in B
		min_score = angle_min + dist_min
		#min_j = -1

		for j in range(0, tripB.shape[0]):
			angleB = tripB[j][0]
			distB = tripB[j][1]
			score = abs(angleA - angleB) + abs(distA - distB) # score close to 0 is best
			if(score <= min_score):
				#print "match found: angA =" + str(angleA) +", distA =" + str(distA) +", angleB ="+str(angleB) + ", distB =" + str(distB)
				#min_score = score
				#min_j = j
				matches.append((score, i, j))

		#if min_j != -1:
		#	matches.append((min_score, i, min_j))

	n_matches = np.array(matches)
	return n_matches[n_matches[:,0].argsort()] #order matches from best scores to worst


def chain_matchforward(chain, tripA, tripB, ai, bj, min_score):
	if ai >= tripA.shape[0] or bj >= tripB.shape[0]:
		#print "we're run out captain!"
		return chain

	angleA = tripA[ai][0]
	distA = tripA[ai][1]

	angleB = tripB[bj][0]
	distB = tripB[bj][1]
	score = abs(angleA - angleB) + abs(distA - distB) # score close to 0 is best
	if score <= min_score:
		chain.append((ai,bj))
		#print "a match! " + str(chain)
		return chain_matchforward(chain, tripA, tripB, ai+1, bj+1, min_score)
	else:
		return chain

def chain_matchbackwards(chain, tripA, tripB, ai, bj, min_score):
	if ai < 0 or bj <0:
		#print "we're run out captain!"
		return chain

	angleA = tripA[ai][0]
	distA = tripA[ai][1]

	angleB = tripB[bj][0]
	distB = tripB[bj][1]
	score = abs(angleA - angleB) + abs(distA - distB) # score close to 0 is best
	if score <= min_score:
		chain.insert(0, (ai,bj))
		#print "a match! " + str(chain)
		return chain_matchbackwards(chain, tripA, tripB, ai-1, bj-1, min_score)
	else:
		return chain

def chainMatches(tripA, tripB, matches, angle_min = 5, dist_min = 5):
	chains = []
	min_score = 20

	i=0
	while i<len(matches): #ai is index in tripA, bj is index in tripB
		score, ai, bj = matches[i]

		ch = chain_matchforward([(ai,bj)], tripA, tripB, ai+1, bj+1, min_score)
		i = i+len(ch)
		ch = chain_matchbackwards(ch, tripA, tripB, ai-1, bj-1, min_score)

		if len(ch)>2 and ch not in chains:
			chains.append(ch)
			#print str(ch)

	return chains


def matchTrips(tripA, tripA_rdp, tripB, tripB_rdp):
	matches = matchAngles(tripA, tripB)
	chains = chainMatches(tripA, tripB, matches)
	return (len(matches), len(chains))

"""
#to start, just comparing 2 trips at a time
a = sys.argv[1]
tripA = np.genfromtxt(a+"_angle_dist.csv", delimiter=',')
tripA_rdp = np.genfromtxt(a+"_rdp.csv", delimiter=',')

b = sys.argv[2]
tripB = np.genfromtxt(b+"_angle_dist.csv", delimiter=',')
tripB_rdp = np.genfromtxt(b+"_rdp.csv", delimiter=',')


matches = matchAngles(tripA, tripB)
print len(matches)
chains = chainMatches(tripA, tripB, matches)
print len(chains)

pyplot.figure(1)
pyplot.plot(tripA_rdp[:,0], tripA_rdp[:,1], 'r-')
pyplot.plot(tripB_rdp[:,0], tripB_rdp[:,1], 'b-')

for ch in chains:
	for ai, bj in ch:
		angA, distA, t1A, t2A, t3A = tripA[ai]
		angB, distB, t1B, t2B, t3B = tripB[bj]
		pyplot.plot(tripA_rdp[t1A][0], tripA_rdp[t1A][1], 'ro')
		pyplot.plot(tripB_rdp[t1B][0], tripB_rdp[t1B][1], 'bo')
		pyplot.plot([tripA_rdp[t1A][0], tripB_rdp[t1B][0]], [tripA_rdp[t1A][1], tripB_rdp[t1B][1]], 'g-')


		pyplot.plot(tripA_rdp[t2A][0], tripA_rdp[t2A][1], 'ro')
		pyplot.plot(tripA_rdp[t3A][0], tripA_rdp[t3A][1], 'ro')
		pyplot.plot(tripB_rdp[t1B][0], tripB_rdp[t1B][1], 'bo')
		pyplot.plot(tripB_rdp[t2B][0], tripB_rdp[t2B][1], 'bo')
		pyplot.plot(tripB_rdp[t3B][0], tripB_rdp[t3B][1], 'bo')

pyplot.show()"""

