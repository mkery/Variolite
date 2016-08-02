import sys
import operator
import json
import matplotlib.pyplot as plt
import numpy as np
from parse import *


inFile = sys.argv[1]
outFile = sys.argv[2]

#ʕ•ᴥ•ʔ#
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

def countTryCatchOnly(results, desc):
    #results includes end try and end catch for debugging (sanity checking)
    cs = csv.reader(StringIO.StringIO(desc), delimiter='|', quotechar='"')
    desc = list(cs)[0]
    count = [] #for nested blocks, we need a stack of statement_count
    statement_count = -1
    for blk in desc:
        label = [x.strip() for x in blk.split(":")]
        kind = label[0]
        #---count # of statements in each catch block in in CATCH : #N
        if kind == "CATCH":
            if len(count) > 0:
                results["Nested Catch"] += 1
            count.append(statement_count+0) #old one in case nested
            statement_count = int(label[1])
            results["Catch"] += 1
        elif kind == "END_CATCH":
            results["Statement Count"] += statement_count
            statement_count = count.pop()
            results["End Catch"] += 1
        elif kind == "TRY":
            results["Try"] += 1
        elif kind == "END_TRY":
            results["End Try"] +=1
    return results



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


def parseExpression(desc):
    c_EXPRESSION["TOTAL"] += 1
    m = parse("{method}({rest}", desc["c_code"])
    if(m is None):
        m = parse("{method}.{rest}", desc["c_code"])
    if(m is None):
        m = ""
        #print "DID NOT PARSE |"+desc["c_code"]+"|"
    else:
        methd = m["method"]
        if methd.find("printStackTrace") != -1:
            c_EXPRESSION["stackTrace"] += 1
        elif methd.startswith("System.out.println") or methd.startswith("System.err.println"):
            c_EXPRESSION["println"] +=1
        elif methd.find("print") != -1:
            c_EXPRESSION["print(general)"] +=1
        elif methd.lower().startswith("log") or methd.lower().find(".log") != -1:
            c_EXPRESSION["log"] +=1
            #print desc["c_code"]
        elif methd.lower().startswith("assert"):
            c_EXPRESSION["Assert"] +=1
        else:
            c_EXPRESSION["unaccounted"] += 1
            lines.append(methd)
##ʕ•ᴥ•ʔ

#ʕ•ᴥ•ʔ#Count returns, throwsʔ
lines = []
c_RETURN = {"TOTAL" : 0, "LITERAL" : 0, "NOTHING" : 0, "OTHER" : 0}
c_THROW = {"TOTAL" : 0}
unaccounted = 0
total_lines = 0
c_EXPRESSION = {"TOTAL" : 0, "stackTrace" : 0, "print(general)": 0, "println" : 0, "log" : 0, "Assert" : 0, "unaccounted" : 0}

def parseReturn(desc):
    c_RETURN["TOTAL"] += 1
    if desc["c_code"] == "\n":
        c_RETURN["NOTHING"] += 1
    else:
        ret = parse("{ret_type}: {ret_value}",desc["c_code"])
        #print ret
        if(ret is None):
            return
            #print "DID NOT PARSE |"+desc["c_code"]+"|"
        elif(ret["ret_type"] == "LITERAL"):
            c_RETURN["LITERAL"] += 1
        else:
            c_RETURN["OTHER"] += 1

def parseThrow(desc):
    c_THROW["TOTAL"] +=1

with open(inFile,'r') as f:
    for line in f:
        total_lines += 1
        c = parse("CatchDesc[{c_type}][{lines_num}] = {c_type2}: {c_code}", line)
        if c is None:
            c = parse("CatchDesc[{c_type}] = ", line)
        if c is None:
            print "DID NOT PARSE "+line
        else:
            desc = c.named
            if(desc["c_type"] == "RETURN"):
                parseReturn(desc)
            elif(desc["c_type"] == "THROW"):
                parseThrow(desc)
            elif(desc["c_type"] == "EXPRESSION"):
                parseExpression(desc)
            else:
                unaccounted += 1


print "Total lines: "+str(total_lines)
print "Expression " + str(c_EXPRESSION)
print "Return " + str(c_RETURN)
print "Throw " + str(c_THROW)
print unaccounted + c_EXPRESSION["unaccounted"]


        # spl = line.split("=")
        # if len(spl)<2:
        #     continue
        # s_type = spl[0].split("[","]")
        # lines.append(float(num))

#print lines
with open(outFile, 'w') as outfile:
    for l in lines:
        outfile.write("{}\n".format(l))
##ʕ•ᴥ•ʔ

#ʕ•ᴥ•ʔ#Count throwsʔ
header = []

testc = 0 #debug only
#----similarity scores by matching
sim_file = []
sim_diff = []
sim_project = []


proj_Q = {}
testCount = 0
fileCount = 0
trycatchcountTotal = {}
with open(inFile,'r') as f:
    prev = {} #line that came before
    currentFile = None
    for line in f:
        #if testc > 1000000:
        #      break;
        testc += 1
        total_lines += 1
        tc = parse("CatchDesc[{project}][{file}] = {desc}", line)
        if tc is None:
            print "DID NOT PARSE "+line
        else:
            tcDict = tc.named
            if "test" not in tcDict["file"].lower():
                if tcDict["project"] not in grouping:
                    grouping[tcDict["project"]] = {}
                    currrent_count = {"File Count":0,"Try":0, "Catch":0, "Statement Count":0,"Nested Try":0, "Nested Catch":0, "End Try": 0, "End Catch":0}
                else:
                    currrent_count = grouping[tcDict["project"]]
                #if tcDict["file"] not in grouping:
                #    grouping[tcDict["project"]][tcDict["file"]] = {}
                #    currrent_count = {"Try":0, "Catch":0, "Statement Count":0, "Nested Try":0, "Nested Catch":0, "End Try": 0, "End Catch":0}
                currrent_count["File Count"] += 1
                grouping[tcDict["project"]] = countTryCatchOnly(currrent_count, tcDict["desc"])

print grouping
#simba = []
#sampleUnrelatedBlocks(simba)
#sampleWithinProjects(simba)#calcSimByBlockLength_diffProj()
#print str(total_lines) + " total lines"
#print proj_Q
#print blocks

with open(outFile, "w") as outfile:
    outfile.write("project, file count, Try, Catch, Statement Count, Nested Try, Nested Catch \n")
    for proj in grouping:
        statement_mean = 0
        if grouping[proj]["Catch"] >0:
            statement_mean= (float(grouping[proj]["Statement Count"]))/(float (grouping[proj]["Catch"]))
        outfile.write(proj +"," + str(grouping[proj]["File Count"]) + "," + str(grouping[proj]["Try"]) + "," + str(grouping[proj]["Catch"]) + "," + str(statement_mean)+ ","
                        + str(grouping[proj]["Nested Try"]) + "," + str(grouping[proj]["Nested Catch"]) + "\n")
##ʕ•ᴥ•ʔ

#ʕ•ᴥ•ʔ#Count returnsʔ

#parses description of try/catch block into csv components, and then counts
#the number of instances of each component, eg. RETURN or THROW
def countReturnsOnly(returns, tDict):
    cs = csv.reader(StringIO.StringIO(tDict), delimiter='|', quotechar='"')
    desc = list(cs)[0]
    count = [] #for nested blocks, we need a stack of statement_count
    statement_count = -1
    prev = None
    for blk in desc:
        label = [x.strip() for x in blk.split(":")]
        kind = label[0]
        if kind == "CATCH":
            count.append(statement_count+0) #old one in case nested
            statement_count = int(label[1])
        elif kind == "END_CATCH":
            statement_count = count.pop()
        elif kind == "RETURN":
            ret = label[1]
            if(ret == "\"LITERAL"):
                ret = label[2]
                if(ret.startswith("\"")):
                    ret = "String"
                else:
                    try:
                        ret = ret.strip('"')
                        #print ret
                        f = int(ret)
                        ret = "Number"
                    except:
                        ret = ret.strip('"')
                        if ret.lower() == "false":
                            ret = "false"
                        elif ret.lower() == "true":
                            ret = "true"
                        elif ret == "null":
                            ret = "null"
                        else:
                            ret = "OTHER"

            elif ret == '""':
                ret = "return"
            else:
                ret = "OTHER"
            num = "1"
            if statement_count > 1:
                num = ">1"
            if num not in returns:
                returns[num] = {}
            if ret not in returns[num]:
                returns[num][ret] = 1
            else:
                 returns[num][ret] += 1
    return returns



proj_Q = {}
testCount = 0
fileCount = 0
trycatchcountTotal = {}
countReturns = {}
with open(inFile,'r') as f:
    prev = {} #line that came before
    currentFile = None
    for line in f:
        #if testc > 1000000:
        #      break;
        #testc += 1
        total_lines += 1
        tc = parse("CatchDesc[{project}][{file}] = {desc}", line)
        if tc is None:
            print "DID NOT PARSE "+line
        else:
            tcDict = tc.named
            if "test" not in tcDict["file"].lower():
                countReturnsOnly(countReturns, tcDict["desc"])

print countReturns

with open(outFile, 'w') as outfile:
    for ret in countReturns:
        outfile.write(ret +","+str(countReturns[ret])+"\n")
##ʕ•ᴥ•ʔ
