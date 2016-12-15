Trip matching algorithm, very much a work in progress.

rdp_trip.py - simplifies the (x,y) path using our implementation of the Ramer–Douglas–Peucker algorithm. The program outputs the rdp simplification of a given trip to a csv, and also outputs the trip formatted as a series of angles/distances.

findMatches.py - Takes 2 trips, and uses rdp and angle/distance formats of each to score similair trip segments.

matchDriver.py - Runs an experiment on a single driver. This takes 200 trips of a driver and compares their similarity to test consistency of the matching algorithm... it's not yet very good.



The csv's A, B, and C are for testing. A and B are trips that should match when compared and C is a random non-matching trip to compare against.

