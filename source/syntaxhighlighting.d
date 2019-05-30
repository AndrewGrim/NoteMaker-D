module syntaxhighlighting;

import tkd.tkdapplication;   
import std.stdio;
import std.conv;
import std.string;    
import std.algorithm;

class Syntax {

	public void highlight(CommandArgs args, NoteBook noteBook, Text[] textWidgetArray) {
		Text textWidget = textWidgetArray[noteBook.getCurrentTabId()];

		configureTags(textWidget);

		// load from file and do a for loop for all the options specified, way too many lines!!!!!!!!!!!!!!!!!!!!!!!!
		searchHighlight(textWidget, "module ", "violet");
		searchHighlight(textWidget, "import ", "violet");
		searchHighlight(textWidget, "private ", "violet");
		searchHighlight(textWidget, "public ", "violet");
		searchHighlight(textWidget, " true", "violet");
		searchHighlight(textWidget, " false", "violet");
		searchHighlight(textWidget, "override ", "violet");
		searchHighlight(textWidget, "protected ", "violet");
		searchHighlight(textWidget, "new ", "red");
		searchHighlight(textWidget, "if ", "red");
		searchHighlight(textWidget, "else ", "red");
		searchHighlight(textWidget, "class ", "yellow");
		searchHighlight(textWidget, "string ", "violet");
		searchHighlight(textWidget, "string[", "violet"); // use something else to get it working
		searchHighlight(textWidget, "int ", "violet");
		searchHighlight(textWidget, "float ", "violet");
		searchHighlight(textWidget, "void ", "violet");
		searchHighlight(textWidget, "auto ", "violet");
		searchHighlight(textWidget, "char ", "violet");
		searchHighlight(textWidget, "bool ", "violet");
		searchHighlight(textWidget, "this.", "teal");
		searchHighlight(textWidget, "~", "yellow");
		searchHighlight(textWidget, "=", "yellow");
		searchHighlight(textWidget, "&", "yellow");
		searchHighlight(textWidget, "<", "yellow");
		searchHighlight(textWidget, ">", "yellow");
		searchHighlight(textWidget, ">=", "yellow");
		searchHighlight(textWidget, "<=", "yellow");
		searchHighlight(textWidget, "(", "yellow");
		searchHighlight(textWidget, ")", "yellow");
		searchHighlight(textWidget, "+", "yellow");
		searchHighlight(textWidget, "*", "yellow");
		searchHighlight(textWidget, "/", "yellow");
		searchHighlight(textWidget, "0", "orange");
		searchHighlight(textWidget, "1", "orange");
		searchHighlight(textWidget, "2", "orange");
		searchHighlight(textWidget, "3", "orange");
		searchHighlight(textWidget, "4", "orange");
		searchHighlight(textWidget, "5", "orange");
		searchHighlight(textWidget, "6", "orange");
		searchHighlight(textWidget, "7", "orange");
		searchHighlight(textWidget, "8", "orange");
		searchHighlight(textWidget, "9", "orange");
		searchHighlight(textWidget, "else if ", "red");
		searchHighlight(textWidget, "while ", "violet");
		searchHighlight(textWidget, "for ", "violet");
		searchHighlight(textWidget, "break", "violet");
		searchHighlight(textWidget, "continue", "violet");
		searchHighlight(textWidget, "return", "violet");
		searchHighlight(textWidget, "writeln", "teal");
		searchHighlight(textWidget, ".length", "red");
		searchHighlight(textWidget, "to!", "red"); 

		lineByLineHighlight(textWidget);
	}

	public void configureTags(Text textWidget) {
		textWidget
			.configTag("red", "-foreground red")
			.configTag("orange", "-foreground orange")
			.configTag("yellow", "-foreground yellow")
			.configTag("green", "-foreground green")
			.configTag("blue", "-foreground blue")
			.configTag("teal", "-foreground teal")
			.configTag("indigo", "-foreground indigo")
			.configTag("violet", "-foreground violet")
			.configTag("black", "-foreground black")
			.configTag("gray", "-foreground gray")
			.configTag("white", "-foreground white");
	}

	public void searchHighlight(Text textWidget, string pattern, string tags) {
		string[] patternIndexes = textWidget.findAll(pattern);
		int patternNumber = 1;
		foreach (item; patternIndexes) {
			string[] tclGarbage = item.split('.');
			int lineIndex = tclGarbage[0].to!int;
			int charIndex = tclGarbage[1].to!int ;
			string startIndex = lineIndex.to!string ~ "." ~ charIndex.to!string;
			int endIndex = charIndex.to!int + pattern.length.to!int;
			if (pattern == "'" && patternNumber % 2 == 1) {
				endIndex = charIndex.to!int + (pattern.length + 1).to!int;
			}
			patternNumber++;
			string stopIndex = lineIndex.to!string ~ "." ~ endIndex.to!string;
			textWidget.addTag(tags, item, stopIndex.to!string);
		}
	}
		
	// go through and shorten all the lines probably by using a function for counUntil and the like!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
	public void lineByLineHighlight(Text textWidget) {
		bool isMultiLineComment = false;
		bool withinString = false;
		int startIndex;
		int stopIndex;
		int patternNumber = 1;

		for (int line = 1; line <= textWidget.getNumberOfLines().split(".")[0].to!int; line++) {
			// check for comment
			if (textWidget.getLine(line).countUntil("//") != -1 || textWidget.getLine(line).countUntil("///") != -1) {
				if (textWidget.getPartialLine(line, (textWidget.getLine(line).countUntil("//") + 2).to!int).countUntil("\"") == 0 ||
					textWidget.getPartialLine(line, (textWidget.getLine(line).countUntil("//") + 2).to!int).countUntil("\"") == 1) {
					writeln("closing comment should be ignored");
				} else {
					startIndex = (textWidget.getLine(line).countUntil("//")).to!int;
					textWidget.removeTag("violet", line.to!string ~ "." ~ startIndex.to!string, line.to!string ~ ".end");
					textWidget.addTag("black", line.to!string ~ "." ~ startIndex.to!string, line.to!string ~ ".end");
				}
			}
			// check for multiline comment
			if (textWidget.getLine(line).countUntil("/*") != -1) {
				// comment in string literal
				if (textWidget.getPartialLine(line, (textWidget.getLine(line).countUntil("/*") + 2).to!int).countUntil("\"") == 0) {
					writeln("comment should be ignored");
				} else {
					startIndex = (textWidget.getLine(line).countUntil("/*")).to!int;
					isMultiLineComment = true;
					textWidget.addTag("black", line.to!string ~ "." ~ startIndex.to!string, line.to!string ~ ".end");
				}
			} else if (isMultiLineComment == true) { // if multiline comment then apply tag, hoping this will fix it
				textWidget.addTag("black", line.to!string ~ ".0", line.to!string ~ ".end");
			}
			// closes multiline comment
			if (textWidget.getLine(line).countUntil("*/") != -1) {
				if (textWidget.getPartialLine(line, (textWidget.getLine(line).countUntil("*/")).to!int + 2).countUntil("\"") == 0) {
					writeln("closing comment should be ignored");
				} else {
					isMultiLineComment = false;
				textWidget.addTag("black", line.to!string ~ ".0", line.to!string ~ "." ~ (textWidget.getLine(line).countUntil("*/") + 2).to!string);
				}
			}
			// check for literal string
			if (textWidget.getLine(line).countUntil('"') != -1) {
				startIndex = (textWidget.getLine(line).countUntil('"')).to!int;
				int fromStartToClose = (textWidget.getPartialLine(line, startIndex + 1).countUntil('"')).to!int + 2;
				stopIndex = startIndex + fromStartToClose;
				int numberOfLiterals = (textWidget.getLine(line).count("\"")).to!int / 2;
				textWidget.removeTag("violet", line.to!string ~ "." ~ startIndex.to!string, line.to!string ~ "." ~ stopIndex.to!string);
				textWidget.addTag("green", line.to!string ~ "." ~ startIndex.to!string, line.to!string ~ "." ~ stopIndex.to!string);
				if (textWidget.getLine(line).countUntil("\"\\\"\"") != -1) {
					// add conditional to run this even if the there is only one literal string in the line
					// corner case where the last " in "\"" would not get marked green, because they're coded to work in pairs 
					startIndex = textWidget.getPartialLine(line, stopIndex).countUntil('"').to!int + stopIndex;
					fromStartToClose = 1;
					stopIndex = startIndex + fromStartToClose;
					textWidget.addTag("green", line.to!string ~ "." ~ startIndex.to!string, line.to!string ~ "." ~ stopIndex.to!string);
				}
				for (int i = 1; i < numberOfLiterals; i++) {
					startIndex = textWidget.getPartialLine(line, stopIndex).countUntil('"').to!int + stopIndex;
					fromStartToClose = textWidget.getPartialLine(line, startIndex + 1).countUntil('"').to!int + 2;
					stopIndex = startIndex + fromStartToClose;
					textWidget.removeTag("violet", line.to!string ~ "." ~ startIndex.to!string, line.to!string ~ "." ~ stopIndex.to!string);
					textWidget.addTag("green", line.to!string ~ "." ~ startIndex.to!string, line.to!string ~ "." ~ stopIndex.to!string);
					if (textWidget.getLine(line).countUntil("\"\\\"\"") != -1) {
						// add conditional to run this even if the there is only one literal string in the line
						// corner case where the last " in "\"" would not get marked green, because they're coded to work in pairs 
						startIndex = textWidget.getPartialLine(line, stopIndex).countUntil('"').to!int + stopIndex;
						fromStartToClose = 1;
						stopIndex = startIndex + fromStartToClose;
						textWidget.addTag("green", line.to!string ~ "." ~ startIndex.to!string, line.to!string ~ "." ~ stopIndex.to!string);
					}
				}
			}
			// check for char
			if (textWidget.getLine(line).countUntil("'") != -1) {
				startIndex = (textWidget.getLine(line).countUntil("'")).to!int;
				int fromStartToClose = (textWidget.getPartialLine(line, startIndex + 1).countUntil("'")).to!int + 2;
				stopIndex = startIndex + fromStartToClose;
				int numberOfLiterals = (textWidget.getLine(line).count("'")).to!int / 2;
				textWidget.removeTag("violet", line.to!string ~ "." ~ startIndex.to!string, line.to!string ~ "." ~ stopIndex.to!string);
				textWidget.addTag("green", line.to!string ~ "." ~ startIndex.to!string, line.to!string ~ "." ~ stopIndex.to!string);
				for (int i = 1; i < numberOfLiterals; i++) {
					startIndex = textWidget.getPartialLine(line, stopIndex).countUntil("'").to!int + stopIndex;
					fromStartToClose = textWidget.getPartialLine(line, startIndex + 1).countUntil("'").to!int + 2;
					stopIndex = startIndex + fromStartToClose;
					textWidget.removeTag("violet", line.to!string ~ "." ~ startIndex.to!string, line.to!string ~ "." ~ stopIndex.to!string);
					textWidget.addTag("green", line.to!string ~ "." ~ startIndex.to!string, line.to!string ~ "." ~ stopIndex.to!string);
				}
			}
		}
	}
}