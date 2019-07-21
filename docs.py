import os

localDir = os.path.abspath(os.path.dirname(__file__))
try:
	os.system("cd " + localDir + " & dub build --build=docs & dir")
except:
	os.system("cd " + localDir + " && dub build --build=docs & dir")

path = localDir + "/source"
sourceContents = os.listdir(path)
iter = 0
for file in sourceContents:
	changeExtension = file.split(".")[0] + ".html"
	sourceContents[iter] = changeExtension
	iter += 1

path = localDir + "/docs"
docsContents = os.listdir(path)

for file in docsContents:
	if file not in sourceContents:
		os.remove(path + "/" + file)