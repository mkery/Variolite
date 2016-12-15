# CS349-roads
A final project for CS349: Data Privacy

In order to run the present code, you need to download the data for the Kaggle Driver Telematics contest and place it in a directory "drivers," which can be found at "../drivers" relative to the directory of our code.

Important files:
Trip.py - creates a trip object using from a filename and a binary string specifying what features to be included; 1 in position i indicates that the ith feature should be included; the features are numbered as follows:
0 - total trip distance
1 - average speed
2 - maximum speed
3 - speed
4 - acceleration
5 - turning angle over 3s
6 - turning angle*speed over 3s
7 - speed*acceleration
8 - heading/angle with respect to (1,0)
9 - low speed count
10 - jerk
11 - distance up a point
12 - bee-line distance to the origin
13 - turning angles for bigger turns (over 50 degrees)
14 - turning distances for turns over 50 degrees
15 - average turning speed*angle for turns over 50 degrees

Driver.py - creates a driver object, and contains methods for creating datasets to be used as training/testing data and executing a classification task.

experiment.py - carries out an experiment consisting of a given number of trials

tripmatching - contains code of trip matching and rdp algorithm


