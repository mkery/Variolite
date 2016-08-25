import sys
import operator
import json
import matplotlib.pyplot as plt
import numpy as nmp
from parse import *
import csv
import StringIO
import random

inFile = sys.argv[1]
outFile = sys.argv[2]

total_lines = 0 #total instances of exception handling
grouping = {} #dictionary of project, file, the descriptions
blocks = {} #list of catch block labels by size of catch block
#header = ["TOTAL", "ASSERT", "assert","BLOCK", "BREAK", "CASE", "CATCH", "END_CATCH", "CONTINUE",
##	"DO", "EMPTY", "EmptyCatch", "???","FOR", "IF", "LABEL", "log", "OTHER",
#    "print", "RETURN", "SWITCH","SYNCHRONIZED","THROW","TRY", "tryTHROW",
#    "END_TRY","TYPEDECL", "WHILE"]
header = []

testc = 0 #debug only
#----similarity scores by matching
sim_file = []
sim_diff = []
sim_project = []

#%%^%%Similarity metrics
def levenshtein(s1, s2):
    if len(s1) < len(s2):
        return levenshtein(s2, s1)

    # len(s1) >= len(s2)
    if len(s2) == 0:
        return len(s1)

    previous_row = range(len(s2) + 1)
    for i, c1 in enumerate(s1):
        current_row = [i + 1]
        for j, c2 in enumerate(s2):
            insertions = previous_row[j + 1] + 1 # j+1 instead of j since previous_row and current_row are one character longer
            deletions = current_row[j] + 1       # than s2
            substitutions = previous_row[j] + (c1 != c2)
            current_row.append(min(insertions, deletions, substitutions))
        previous_row = current_row

    lfd = previous_row[-1]
    return 1 - (float(lfd)) / (max(len(s1), len(s2))) #percentage match


def calculateSimilarity(line1, line2):
    sim = 0.0
    #print line1 + "   and     " + line2
    for i in range(0, min(len(line1), len(line2))):
        if line1[i] == line2[i]:
            sim += 1.0
    return sim/float(max(len(line1), len(line2)))


#adds a given line from the input file into a dictionary
#that groups by Java project and by class within Java project
def addToGrouping(tDict):
    if tDict["project"] not in grouping:
        grouping[tDict["project"]] = {}
    if tDict["file"] not in grouping:
        grouping[tDict["project"]][tcDict["file"]] = []
    grouping[tDict["project"]][tcDict["file"]].append(tDict["desc"])

def sampleWithinProjects(arr):
    pSet = grouping.keys() #shuffled indexing of projects
    print "Looking at pairs within " +str(len(pSet)) +" projects"
    for proj in pSet:
        p = grouping[proj] # a dictionary of all files in this project
        prev = None
        for key in p.keys(): #look at each file and compare it with the previous one (keys are unsorted order)
            if prev is None:
                prev = key
                continue
            index1 = random.randint(0, len(p[key]) - 1) # each file has a list of try/catch
            index2 = random.randint(0, len(p[prev]) - 1) # each file has a list of try/catch
            blk1 = parseNoSortBlock(p[key][index1])
            blk2 = parseNoSortBlock(p[prev][index2])
            score = levenshtein(blk1, blk2)
            arr.append(score)
            prev = key
    return arr

def sampleUnrelatedBlocks(arr):
    perProject = 200 #approx how many try/catch blocks per project
    print "Looking at unrelated pairs within " +str(len(grouping)) +" projects"
    prev = None
    for key in grouping:
        proj = grouping[key]
        if prev is None:
            prev = proj
            continue
        for i in range(0,perProject):
            rand_file1 = proj[random.choice(proj.keys())] #choose random file
            rand_file2 = prev[random.choice(prev.keys())] #choose random file
            rand_block1 = random.choice(rand_file1) #get random block
            rand_block2 = random.choice(rand_file2) #get random block
            blk1 = parseNoSortBlock(rand_block1)
            blk2 = parseNoSortBlock(rand_block2)
            score = levenshtein(blk1, blk2)
            arr.append(score)
        prev = proj
    return arr

#for each file, calculates similarity by catch blocks of different length
def calcSimByBlockLength_diffFilesameProj():
    simba = {} #statement length, similarity list
    for key in grouping:
        proj = grouping[key] #a github project
        prev = None #previous file
        for f in proj:
            if prev is None:
                prev = f
                continue
            fyl1 = proj[prev]
            fyl2 = proj[f]
            file_d1 = {} #dict of N and list of trycatch arrs that are of len N
            file_d2 = {}
            for trycatch in fyl1:
                sortBlocksByLength(file_d1, trycatch)
            for trycatch in fyl2:
                sortBlocksByLength(file_d2, trycatch)
            for n in file_d1: #blocks of size n
                if n not in file_d2:
                    continue
                for i in range(0, min(len(file_d1[n]), len(file_d2[n]))):
                    blk1 = file_d1[n][i]
                    blk2 = file_d2[n][i]
                    score = levenshtein(blk1, blk2)
                    print "MATCHING " + str(n) +" " + str(blk1) + " # " + str(blk2) + "  SCORE:" + str(score)
                    if n not in simba:
                        simba[n] = []
                    simba[n].append(score)
            prev = f
    return simba

#for each file, calculates similarity by catch blocks of different length
def calcSimByBlockLength_diffProj():
    simba = {} #statement length, similarity list
    prev = None
    fly1 = None
    for key in grouping:
        if prev is None:
            prev = key
            continue
        proj1 = grouping[prev] #a github project
        proj2 = grouping[key] #a github project

        for (k1, k2) in zip(proj1.keys(), proj2.keys()): #each file in this project
            file_d1 = {} #dict of N and list of trycatch arrs that are of len N
            file_d2 = {}
            for trycatch in proj1[k1]:
                sortBlocksByLength(file_d1, trycatch)
            for trycatch in proj2[k2]:
                sortBlocksByLength(file_d2, trycatch)
            for n in file_d1: #blocks of size n
                if n not in file_d2:
                    continue
                blk1 = random.choice(file_d1[n])
                blk2 = random.choice(file_d2[n])
                score = levenshtein(blk1, blk2)
                print "MATCHING " + str(n) +" " + str(blk1) + " # " + str(blk2) + "  SCORE:" + str(score)
                if n not in simba:
                    simba[n] = []
                simba[n].append(score)
        prev = key

    return simba

def calcSimByBlockLength():
    simba = {} #statement length, similarity list
    for key in grouping:
        proj = grouping[key] #a github project
        for fyl in proj.keys(): #each file in this project
            #print fyl
            file_Simba = {} #dict of N and list of trycatch arrs that are of len N
            for trycatch in proj[fyl]:
                #print trycatch
                sortBlocksByLength(file_Simba, trycatch)
            #print file_Simba
            for n in file_Simba: #each size catch block
                for i in range(1, len(file_Simba[n])):
                    #print str(i)+" "+ str(file_Simba[n])
                    blk1 = file_Simba[n][i-1]
                    blk2 = file_Simba[n][i]
                    score = levenshtein(blk1, blk2)
                    print "MATCHING " + str(n) +" " + str(blk1) + " # " + str(blk2) + "  SCORE:" + str(score)
                    if n not in simba:
                        simba[n] = []
                    simba[n].append(score)
    return simba

#puts blocks by length, but other than that desribed as an array
def sortBlocksByLength(file_Simba, desc):
    cs = csv.reader(StringIO.StringIO(desc), delimiter='|', quotechar='"')
    desc = list(cs)[0]
    count = [] #for nested blocks, we need a stack of statement_count
    statement_count = -1
    temp_desc = []
    prev = None
    for blk in desc:
        label = [x.strip() for x in blk.split(":")]
        kind = label[0]
        #---count # of statements in each catch block in in CATCH : #N
        if (kind == "TRY" or kind == "END_TRY") and len(count)==0:
            continue
        if kind == "CATCH":
            count.append(statement_count+0) #old one in case nested
            statement_count = int(label[1])
            if statement_count == 0:
                continue #don't need to worry about similarity between two empty statements
            if len(count) == 0: #not nested
                continue
        if kind == "END_CATCH":
            if statement_count not in file_Simba:
                file_Simba[statement_count] = []
            file_Simba[statement_count].append(temp_desc)
            temp_desc = []
            statement_count = count.pop()
            if len(count) == 0:
                continue
        #---if an expression, compare by the full string because we don't
        #---know what it is
        elif kind == "EXPRESSION":
            kind = "???"+label[1]
        elif kind == "THROW" and prev is not None and prev == "TRY" :
            kind = "tryTHROW"
        #---a lot of these are IF-BLOCK, which mean one thing, don't re-add
        elif kind == "BLOCK" and prev is not None and prev == "IF" :
            prev = "BLOCK"
            continue
        #---parsing error, probably part of an expression
        elif not kind.isalpha():
            continue
        #---add to dictionary by statement count
        temp_desc.append(kind)
        prev = kind #save to keep track of sequenced blocks
#^^%^^


#%%^%%Sort by length
#puts blocks by length, but other than that desribed as an array
def parseNoSortBlock(desc):
    cs = csv.reader(StringIO.StringIO(desc), delimiter='|', quotechar='"')
    desc = list(cs)[0]
    temp_desc = []
    prev = None
    in_catch = 0
    for blk in desc:
        label = [x.strip() for x in blk.split(":")]
        kind = label[0]
        #---count # of statements in each catch block in in CATCH : #N
        if (kind == "TRY" or kind == "END_TRY") and in_catch==0:
            continue
        if kind == "CATCH":
            in_catch += 1
            if in_catch == 1: #not nested
                continue
        if kind == "END_CATCH":
            in_catch -= 1
            if in_catch == 0:
                continue
        #---if an expression, compare by the full string because we don't
        #---know what it is
        elif kind == "EXPRESSION":
            kind = "???"+label[1]
        elif kind == "THROW" and prev is not None and prev == "TRY" :
            kind = "tryTHROW"
        #---a lot of these are IF-BLOCK, which mean one thing, don't re-add
        elif kind == "BLOCK" and prev is not None and prev == "IF" :
            prev = "BLOCK"
            continue
        #---parsing error, probably part of an expression
        elif not kind.isalpha():
            continue
        #---add to dictionary by statement count
        temp_desc.append(kind)
        prev = kind #save to keep track of sequenced blocks
    return temp_desc

#sort by: if I have catch blocks of size n + kind, how many catch blocks that are of length N and do kind
# are there
def sortByQuestion(statement_N, kind_N, blk):
    question = [0,0] #matches, doesn't
    cs = csv.reader(StringIO.StringIO(blk), delimiter='|', quotechar='"')
    desc = list(cs)[0]
    matches = None
    count = [] #for nested blocks, we need a stack of statement_count
    statement_count = -1
    prev = None
    for blk in desc:
        label = [x.strip() for x in blk.split(":")]
        kind = label[0]
        #---count # of statements in each catch block in in CATCH : #N
        if (kind == "TRY" or kind == "END_TRY") and len(count)==0:
            continue
        if kind == "CATCH":
            count.append(statement_count+0) #old one in case nested
            statement_count = int(label[1])
            if len(count) == 0: #not nested
                continue
        if kind == "END_CATCH":
            statement_count = count.pop()
            if not matches:
                question[0] += 1
                matches = False
            if len(count) == 0:
                continue
        #---if an expression, compare by the full string because we don't
        #---know what it is
        elif kind == "EXPRESSION":
            kind = parseExpression(label[1])
        elif kind == "THROW" and prev is not None and prev == "TRY" :
            kind = "tryTHROW"
        #---a lot of these are IF-BLOCK, which mean one thing, don't re-add
        elif kind == "BLOCK" and prev is not None and prev == "IF" :
            prev = "BLOCK"
            continue
        #---parsing error, probably part of an expression
        elif not kind.isalpha():
            continue
        #---add to dictionary by statement count
        #print str(statement_count) +" v "+str(statement_N)+ " k "+kind
        if (kind == kind_N or statement_count==0):
            if(matches is None):
                question[1] += 1
                matches = True
        else:#matches is true
            matches = False
        prev = kind #save to keep track of sequenced blocks
    return question
#^^%^^

#%%^%%Block desc functions
#parses description of try/catch block into csv components, and then counts
#the number of instances of each component, eg. RETURN or THROW
def countBlocks(tDict):
    cs = csv.reader(StringIO.StringIO(tDict["desc"]), delimiter='|', quotechar='"')
    desc = list(cs)[0]
    count = [] #for nested blocks, we need a stack of statement_count
    statement_count = -1
    prev = None
    for blk in desc:
        label = [x.strip() for x in blk.split(":")]
        kind = label[0]
        #---count # of statements in each catch block in in CATCH : #N
        if kind == "CATCH":
            if len(count) == 0: #not nested
                kind = "TOTAL" #top level Catch, to distinguish nested
            count.append(statement_count+0) #old one in case nested
            statement_count = int(label[1])
            if statement_count == 0:
                blocks[0]["EmptyCatch"] += 1
        if kind == "END_CATCH":
            statement_count = count.pop()
        #---if an expression, parse out kind like printStackTrace
        elif kind == "EXPRESSION":
            kind = parseExpression(label[1])
    	#---TOP level try, nothing before it
        elif kind == "TRY" and prev is None:
            statement_count = -2
        elif kind == "THROW" and prev is not None and prev == "TRY" :
            kind = "tryTHROW"
        #---a lot of these are IF-BLOCK, which mean one thing, don't re-add
        elif kind == "BLOCK" and prev is not None and prev == "IF" :
            prev = "BLOCK"
            continue
        #---parsing error, probably part of an expression
        elif kind != "END_TRY" and not kind.isalpha():
            continue
        #---add to dictionary by statement count
        if statement_count not in blocks:
            blocks[statement_count] = {}
        if kind in blocks[statement_count]:
             blocks[statement_count][kind] += 1
        else:
             blocks[statement_count][kind] = 1
        prev = kind #save to keep track of sequenced blocks

#takes expression block and describes it in more detail
def parseExpression(desc):
    m = parse("\"{method}({rest}\"", desc)
    if(m is None):
        m = parse("\"{method}.{rest}\"", desc)
    if(m is None):
        m = ""
        #print "DID NOT PARSE |"+desc+"|"
        return "???"
    else:
        methd = m["method"]
        if methd.find("printStackTrace") != -1:
            return "print"#"printStackTrace"
        elif methd.startswith("System.out.println") or methd.startswith("System.err.println"):
            return "print"#"println"
        elif methd.find("print") != -1:
            return "print"#"print_general"
        elif methd.startswith("System.exit") or methd.find("quit") != -1:
            return "terminate"#"print_general"
        elif methd.lower().startswith("log") or methd.lower().find(".log") != -1 or methd.lower().find("log.") != -1  or methd.lower().find("logger.") != -1:
            return "log"
        elif methd.lower().startswith("assert"):
            return "assert"
        else:
            #print methd
            return "???"
#^^%^^

#%%^%%Catch and Throw details
def whatDidYouThrow(tDict):
	cs = csv.reader(StringIO.StringIO(tDict["desc"]), delimiter='|', quotechar='"')
	desc = list(cs)[0]
	count = [] #for nested blocks, we need a stack of statement_count
	statement_count = -1
	prev = None
	catchvar = []
	for blk in desc:
		label = [x.strip() for x in blk.split(":")]
		kind = label[0]
		throw = None
		#---count # of statements in each catch block in in CATCH : #N
		if kind == "CATCH":
		    if len(count) == 0: #not nested
		        kind = "TOTAL" #top level Catch, to distinguish nested
		    count.append(statement_count+0) #old one in case nested
		    statement_count = int(label[1])
			#catchvar[]
		if kind == "END_CATCH":
		    statement_count = count.pop()
		if kind == "THROW":
			if prev != "TRY":
				throw = label[1]
				if throw == '\"NEW':
					throw = label[2]
				elif throw == '\"VARACCES':
					print "d"

				#print "THROW is  "+throw + "| "+str(label) +"  | "+label[2]
		#---add to dictionary by statement count
		if throw is not None:
		    if statement_count not in blocks:
		        blocks[statement_count] = {}
		    if throw in blocks[statement_count]:
		         blocks[statement_count][throw] += 1
		    else:
		         blocks[statement_count][throw] = 1
		prev = kind #save to keep track of sequenced blocks

def whatDidYouCatch(tDict):
    cs = csv.reader(StringIO.StringIO(tDict["desc"]), delimiter='|', quotechar='"')
    desc = list(cs)[0]
    count = [] #for nested blocks, we need a stack of statement_count
    statement_count = -1
    prev = None
    for blk in desc:
        label = [x.strip() for x in blk.split(":")]
        kind = label[0]
        catch = None
        #---count # of statements in each catch block in in CATCH : #N
        if kind == "CATCH":
            if len(count) == 0: #not nested
                kind = "TOTAL" #top level Catch, to distinguish nested
            count.append(statement_count+0) #old one in case nested
            statement_count = int(label[1])
            tocatch = label[2][1:-1].split("|")
            catch = []
            for c in tocatch:
                catch.append(c)
        if kind == "END_CATCH":
            statement_count = count.pop()
        		#print "THROW is  "+throw + "| "+str(label) +"  | "+label[2]
        #---add to dictionary by statement count
        if catch is not None:
            if statement_count not in blocks:
                blocks[statement_count] = {}
            for c in catch:
            	if c in blocks[statement_count]:
            	     blocks[statement_count][c] += 1
            	else:
            	     blocks[statement_count][c] = 1
        prev = kind #save to keep track of sequenced blocks

#^^%^^


#%%^%%Count what caught
# proj_Q = {}
# testCount = 0
# fileCount = 0
# with open(inFile,'r') as f:
#     prev = {} #line that came before
#     currentFile = None
#     for line in f:
#         total_lines += 1
#         tc = parse("CatchDesc[{project}][{file}] = {desc}", line)
#         if tc is None:
#             print "DID NOT PARSE "+line
#         else:
#             tcDict = tc.named
#             if "test" not in tcDict["file"].lower():
#                 whatDidYouCatch(tcDict)
#
#
#
# hdict = {}
# for n in blocks:
# 	for excp in blocks[n]:
# 		count = blocks[n][excp]
# 		if excp in hdict:
# 			hdict[excp] += count
# 		else:
# 			hdict[excp] = count
# header = sorted(hdict, key=hdict.get, reverse=True)
# print header
#
# with open(outFile, 'w') as outfile:
# 	outfile.write(" ,")
# 	for h in header:
# 	     outfile.write("{},".format(h))
# 	outfile.write("\n")
# 	for count in blocks:
# 	     outfile.write("{},".format(count))
# 	     for h in header:
# 	         if h in blocks[count]:
# 	             outfile.write("{},".format(blocks[count][h]))
# 	         else:
# 	            outfile.write("0,")
# 	     outfile.write("\n")
# 	outfile.write("Total,")
# 	for h in header:
# 		outfile.write(str(hdict[h])+",")
# 	outfile.write("\n")
#^^%^^

#%%^%%Count contents
proj_Q = {}
testCount = 0
fileCount = 0
with open(inFile,'r') as f:
    #%%^%%test
    if testCount > 100:
        break;
    testCount ++
    #^^%^^
    prev = {} #line that came before
    currentFile = None
    for line in f:
        total_lines += 1
        tc = parse("CatchDesc[{project}][{file}] = {desc}", line)
        if tc is None:
            print "DID NOT PARSE "+line
        else:
            tcDict = tc.named
            if "test" not in tcDict["file"].lower():
                countBlocks(tcDict)

print blocks #test

with open(outFile, 'w') as outfile:
	outfile.write(" ,")
	for h in header:
	     outfile.write("{},".format(h))
	outfile.write("\n")
	for count in blocks:
	     outfile.write("{},".format(count))
	     for h in header:
	         if h in blocks[count]:
	             outfile.write("{},".format(blocks[count][h]))
	         else:
	            outfile.write("0,")
#^^%^^
