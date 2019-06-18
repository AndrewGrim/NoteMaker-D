module syntaxhighlighting;

import tkd.tkdapplication;   
import std.stdio;
import std.conv;
import std.string;    
import std.algorithm;
import std.path;
import std.file;

class Syntax {

	// variables
	string appDir;
	bool highlightOnLoad;

	// constructor
	this(string appDir) {
		this.appDir = appDir;
	}

	public bool getHighlightOnLoad() {
		return highlightOnLoad;
	}

	public void setHighlightOnLoad(bool state) {
		highlightOnLoad = state;
	}


	public void highlight(CommandArgs args, NoteBook noteBook, Text[] textWidgetArray, bool manual = false) {
		string[] supportedLanguages = [".d", ".c", ".cpp", ".h", ".hpp"];
		if (supportedLanguages.canFind((noteBook.getTabText(noteBook.getCurrentTabId())).extension) || manual == true) {

			Text textWidget = textWidgetArray[noteBook.getCurrentTabId()];

			textWidget.setForegroundColor("#fff");
			configureTags(textWidget);
			textWidget.addTag("tabWidth", "1.0", "end");
			string[string] tags = [ "keywords.txt" : "keyword", "conditionals.txt" : "conditional", "loops.txt" : "loop",
									"types.txt" : "type", "symbols.txt"  : "symbol", "numbers.txt"  : "number"];
		
			foreach (syntaxFile; dirEntries("syntax", SpanMode.shallow, false)) {
				string filePath = appDir ~ "/" ~ syntaxFile;
				string[] fileContent;

				auto f = File(filePath, "r");
				while (!f.eof()) {
					string line = chomp(f.readln());
					fileContent ~= line;
				}

				foreach (item; fileContent) {
					searchHighlight(textWidget, item, tags[filePath.baseName]);
				}
			}
	
			lineByLineHighlight(textWidget);

		} else {
			writeln("Unsupported file type! @syntax");
		}
	}

	public void configureTags(Text textWidget) {
		textWidget
			.configTag("conditional", "-foreground red")
			.configTag("loop", "-foreground red")
			.configTag("type", "-foreground violet")
			.configTag("keyword", "-foreground violet")
			.configTag("symbol", "-foreground yellow")
			.configTag("number", "-foreground orange")
			.configTag("comment", "-foreground green")
			.configTag("char", "-foreground teal")
			.configTag("string", "-foreground teal")
			.configTag("tabWidth", "-tabs {1c}");
	}

	public void searchHighlight(Text textWidget, string pattern, string tags) {
		string[] patternIndexes = textWidget.findAll(pattern);
		foreach (item; patternIndexes) {
			string[] tclGarbage = item.split('.');
			int lineIndex = tclGarbage[0].to!int;
			int charIndex = tclGarbage[1].to!int ;
			string startIndex = lineIndex.to!string ~ "." ~ charIndex.to!string;
			int endIndex = charIndex.to!int + pattern.length.to!int;
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
		string[] removeTagsFromComments = ["keyword", "conditional", "loop", "type", "symbol", "number", "char", "string"];
		string[] removeTagsFromCharString = ["keyword", "conditional", "loop", "type", "symbol", "number", "comment"];

		for (int line = 1; line <= textWidget.getNumberOfLines().split(".")[0].to!int; line++) {
			// check for literal string
			if (textWidget.getLine(line).countUntil('"') != -1) {
				startIndex = (textWidget.getLine(line).countUntil('"')).to!int;
				int fromStartToClose = (textWidget.getPartialLine(line, startIndex + 1).countUntil('"')).to!int + 2;
				stopIndex = startIndex + fromStartToClose;
				int numberOfLiterals = (textWidget.getLine(line).count("\"")).to!int / 2;
				foreach (item; removeTagsFromCharString) {
					textWidget.removeTag(item, line.to!string ~ "." ~ startIndex.to!string, line.to!string ~ "." ~ stopIndex.to!string);
				}
				textWidget.addTag("string", line.to!string ~ "." ~ startIndex.to!string, line.to!string ~ "." ~ stopIndex.to!string);
				if (textWidget.getLine(line).countUntil("\"\\\"\"") != -1) {
					// corner case where the last " in "\"" would not get marked teal, because they're coded to work in pairs 
					startIndex = textWidget.getPartialLine(line, stopIndex).countUntil('"').to!int + stopIndex;
					fromStartToClose = 1;
					stopIndex = startIndex + fromStartToClose;
					foreach (item; removeTagsFromCharString) {
						textWidget.removeTag(item, line.to!string ~ "." ~ startIndex.to!string, line.to!string ~ "." ~ stopIndex.to!string);
					}
					textWidget.addTag("string", line.to!string ~ "." ~ startIndex.to!string, line.to!string ~ "." ~ stopIndex.to!string);
				}
				for (int i = 1; i < numberOfLiterals; i++) {
					startIndex = textWidget.getPartialLine(line, stopIndex).countUntil('"').to!int + stopIndex;
					fromStartToClose = textWidget.getPartialLine(line, startIndex + 1).countUntil('"').to!int + 2;
					stopIndex = startIndex + fromStartToClose;
					foreach (item; removeTagsFromCharString) {
						textWidget.removeTag(item, line.to!string ~ "." ~ startIndex.to!string, line.to!string ~ "." ~ stopIndex.to!string);
					}
					textWidget.addTag("string", line.to!string ~ "." ~ startIndex.to!string, line.to!string ~ "." ~ stopIndex.to!string);
					if (textWidget.getLine(line).countUntil("\"\\\"\"") != -1) {
						// corner case where the last " in "\"" would not get marked green, because they're coded to work in pairs 
						startIndex = textWidget.getPartialLine(line, stopIndex).countUntil('"').to!int + stopIndex;
						fromStartToClose = 1;
						stopIndex = startIndex + fromStartToClose;
						foreach (item; removeTagsFromCharString) {
							textWidget.removeTag(item, line.to!string ~ "." ~ startIndex.to!string, line.to!string ~ "." ~ stopIndex.to!string);
						}
						textWidget.addTag("string", line.to!string ~ "." ~ startIndex.to!string, line.to!string ~ "." ~ stopIndex.to!string);
					}
				}
			}
			// check for char
			if (textWidget.getLine(line).countUntil("'") != -1) {
				startIndex = (textWidget.getLine(line).countUntil("'")).to!int;
				int fromStartToClose = (textWidget.getPartialLine(line, startIndex + 1).countUntil("'")).to!int + 2;
				stopIndex = startIndex + fromStartToClose;
				int numberOfLiterals = (textWidget.getLine(line).count("'")).to!int / 2;
				foreach (item; removeTagsFromCharString) {
					textWidget.removeTag(item, line.to!string ~ "." ~ startIndex.to!string, line.to!string ~ "." ~ stopIndex.to!string);
				}
				textWidget.addTag("char", line.to!string ~ "." ~ startIndex.to!string, line.to!string ~ "." ~ stopIndex.to!string);
				for (int i = 1; i < numberOfLiterals; i++) {
					startIndex = textWidget.getPartialLine(line, stopIndex).countUntil("'").to!int + stopIndex;
					fromStartToClose = textWidget.getPartialLine(line, startIndex + 1).countUntil("'").to!int + 2;
					stopIndex = startIndex + fromStartToClose;
					foreach (item; removeTagsFromCharString) {
						textWidget.removeTag(item, line.to!string ~ "." ~ startIndex.to!string, line.to!string ~ "." ~ stopIndex.to!string);
					}
					textWidget.addTag("char", line.to!string ~ "." ~ startIndex.to!string, line.to!string ~ "." ~ stopIndex.to!string);
				}
			}
			// check for comment
			if (textWidget.getLine(line).countUntil("//") != -1 || textWidget.getLine(line).countUntil("///") != -1) {
				if (textWidget.getPartialLine(line, (textWidget.getLine(line).countUntil("//") + 2).to!int).countUntil("\"") == 0 ||
					textWidget.getPartialLine(line, (textWidget.getLine(line).countUntil("//") + 2).to!int).countUntil("\"") == 1) {
				} else {
					startIndex = (textWidget.getLine(line).countUntil("//")).to!int;
					foreach (item; removeTagsFromComments) {
						textWidget.removeTag(item, line.to!string ~ "." ~ startIndex.to!string, line.to!string ~ ".end");
					}
					textWidget.addTag("comment", line.to!string ~ "." ~ startIndex.to!string, line.to!string ~ ".end");
				}
			}
			// check for multiline comment
			if (textWidget.getLine(line).countUntil("/*") != -1) {
				// comment in string literal
				if (textWidget.getPartialLine(line, (textWidget.getLine(line).countUntil("/*") + 2).to!int).countUntil("\"") == 0) {
					// do nothing
				} else {
					startIndex = (textWidget.getLine(line).countUntil("/*")).to!int;
					isMultiLineComment = true;
					foreach (item; removeTagsFromComments) {
						textWidget.removeTag(item, line.to!string ~ "." ~ startIndex.to!string, line.to!string ~ ".end");
					}
					textWidget.addTag("comment", line.to!string ~ "." ~ startIndex.to!string, line.to!string ~ ".end");
				}
			} else if (isMultiLineComment == true) {
				foreach (item; removeTagsFromComments) {
					textWidget.removeTag(item, line.to!string ~ "." ~ startIndex.to!string, line.to!string ~ ".end");
				}
				textWidget.addTag("comment", line.to!string ~ ".0", line.to!string ~ ".end");
			}
			// closes multiline comment
			if (textWidget.getLine(line).countUntil("*/") != -1) {
				if (textWidget.getPartialLine(line, (textWidget.getLine(line).countUntil("*/")).to!int + 2).countUntil("\"") == 0) {
					// do nothing
				} else {
					isMultiLineComment = false;
					foreach (item; removeTagsFromComments) {
						textWidget.removeTag(item, line.to!string ~ "." ~ startIndex.to!string, line.to!string ~ ".end");
					}
					textWidget.addTag("comment", line.to!string ~ ".0", line.to!string ~ "." ~ (textWidget.getLine(line).countUntil("*/") + 2).to!string);
				}
			}
		}
	}
}
