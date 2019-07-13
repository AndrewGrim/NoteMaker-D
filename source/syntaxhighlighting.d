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
	bool highlightOnLoad;

	public bool getHighlightOnLoad() {
		return highlightOnLoad;
	}

	public void setHighlightOnLoad(bool state) {
		highlightOnLoad = state;
	}


	public void highlight(CommandArgs args, NoteBook noteBook, Text[] textWidgetArray, bool manual = false) {
		string[] supportedLanguages = [".d", ".c", ".cpp", ".h", ".hpp"];
		if (supportedLanguages.canFind((noteBook.getTabText(noteBook.getCurrentTabId())).extension)
			|| manual == true) {

			Text textWidget = textWidgetArray[noteBook.getCurrentTabId()];

			textWidget.setForegroundColor("#ffffff");
			configureTags(textWidget);
			textWidget.addTag("tabWidth", "1.0", "end");
			string[string] tags = [ "keywords.txt" : "keyword", "conditionals.txt" : "conditional", "loops.txt" : "loop",
									"types.txt" : "type", "symbols.txt"  : "symbol", "numbers.txt"  : "number"];
		
			foreach (syntaxFile; dirEntries("syntax", SpanMode.shallow, false)) {
				string filePath = getcwd() ~ "/" ~ syntaxFile;
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
			.configTag("escapeCharacter", "-foreground indigo")
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
		
	public void lineByLineHighlight(Text textWidget) {
		bool isMultiLineComment = false;
		bool withinString = false;
		int startIndex;
		int stopIndex;
		int patternNumber = 1;
		string[] removeTagsFromComments = ["keyword", "conditional", "loop", "type", "symbol", "number", "char", "string", "escapeCharacter"];
		string[] removeTagsFromCharString = ["keyword", "conditional", "loop", "type", "symbol", "number", "comment"];

		for (int line = 1; line <= getNumberOfLinesFromText(textWidget); line++) { // TODO ??change to global variables to reduce all the arguments in methods?
			// check for functions // TODO highlight function names 
			//if (checkLineForToken(textWidget, line, "(") != -1) {
			//	writeln("parenthases detected on line: ", line);
			//}
			// check for literal string
			if (checkLineForToken(textWidget, line, '"') != -1) {
				startIndex = checkLineForToken(textWidget, line, '"');
				int fromStartToClose = getStringLength(textWidget, line, '"', startIndex);
				stopIndex = startIndex + fromStartToClose;
				int numberOfLiterals = numberOfStringsInLine(textWidget, line);
				foreach (item; removeTagsFromCharString) {
					textWidget.removeTag(item, startIndexFn(line, startIndex), stopIndexFn(line, stopIndex));
				}
				textWidget.addTag("string", startIndexFn(line, startIndex), stopIndexFn(line, stopIndex));
				if (checkLineForToken(textWidget, line, "\"\\\"\"") != -1) {
					// corner case where the last " in "\"" would not get marked teal, because they're coded to work in pairs 
					startIndex = checkLineForNextToken(textWidget, line, stopIndex, '"') + stopIndex;
					fromStartToClose = 1;
					stopIndex = startIndex + fromStartToClose;
					foreach (item; removeTagsFromCharString) {
						textWidget.removeTag(item, startIndexFn(line, startIndex), stopIndexFn(line, stopIndex));
					}
					textWidget.addTag("string", startIndexFn(line, startIndex), stopIndexFn(line, stopIndex));
				}
				for (int i = 1; i < numberOfLiterals; i++) {
					startIndex = checkLineForNextToken(textWidget, line, stopIndex, '"') + stopIndex;
					fromStartToClose = checkLineForNextToken(textWidget, line, startIndex + 1, '"') + 2;
					stopIndex = startIndex + fromStartToClose;
					foreach (item; removeTagsFromCharString) {
						textWidget.removeTag(item, startIndexFn(line, startIndex), stopIndexFn(line, stopIndex));
					}
					textWidget.addTag("string", startIndexFn(line, startIndex), stopIndexFn(line, stopIndex));
					if (checkLineForToken(textWidget, line, "\"\\\"\"") != -1) {
						// corner case where the last " in "\"" would not get marked green, because they're coded to work in pairs 
						startIndex = checkLineForNextToken(textWidget, line, stopIndex, '"') + stopIndex;
						fromStartToClose = 1;
						stopIndex = startIndex + fromStartToClose;
						foreach (item; removeTagsFromCharString) {
							textWidget.removeTag(item, startIndexFn(line, startIndex), stopIndexFn(line, stopIndex));
						}
						textWidget.addTag("string", startIndexFn(line, startIndex), stopIndexFn(line, stopIndex));
					}
				}
			}
			// check for char
			if (checkLineForToken(textWidget, line, "'") != -1) {
				startIndex = checkLineForToken(textWidget, line, "'");
				int fromStartToClose = checkLineForNextToken(textWidget, line, startIndex + 1, "'") + 2;
				stopIndex = startIndex + fromStartToClose;
				int numberOfLiterals = numberOfCharsInLine(textWidget, line);
				foreach (item; removeTagsFromCharString) {
					textWidget.removeTag(item, startIndexFn(line, startIndex), stopIndexFn(line, stopIndex));
				}
				textWidget.addTag("char", startIndexFn(line, startIndex), stopIndexFn(line, stopIndex));
				for (int i = 1; i < numberOfLiterals; i++) {
					startIndex = checkLineForNextToken(textWidget, line, stopIndex, "'") + stopIndex;
					fromStartToClose = checkLineForNextToken(textWidget, line, stopIndex, "'") + 2;
					stopIndex = startIndex + fromStartToClose;
					foreach (item; removeTagsFromCharString) {
						textWidget.removeTag(item, startIndexFn(line, startIndex), stopIndexFn(line, stopIndex));
					}
					textWidget.addTag("char", startIndexFn(line, startIndex), stopIndexFn(line, stopIndex));
				}
			}
			// check for escape characters
			if (checkLineForToken(textWidget, line, "\\") != -1) {
				startIndex = checkLineForToken(textWidget, line, "\\");
				stopIndex = startIndex + 2;
				int numberOfEscapes = numberOfEscapesInLine(textWidget, line);
				foreach (item; removeTagsFromComments) {
					textWidget.removeTag(item, startIndexFn(line, startIndex), stopIndexFn(line, stopIndex));
				}
				textWidget.addTag("escapeCharacter", startIndexFn(line, startIndex), stopIndexFn(line, stopIndex));
				for (int i = 1; i < numberOfEscapes; i++) {
					startIndex = checkLineForNextToken(textWidget, line, stopIndex, "\\") + stopIndex;
					stopIndex = startIndex + 2;
					if (i == (numberOfEscapes - 1)) {
						stopIndex--;
					}
					foreach (item; removeTagsFromComments) {
						textWidget.removeTag(item, startIndexFn(line, startIndex), stopIndexFn(line, stopIndex));
					}
					textWidget.addTag("escapeCharacter", startIndexFn(line, startIndex), stopIndexFn(line, stopIndex));
				}
			}
			// check for comment
			if (checkLineForToken(textWidget, line, "//") != -1 || checkLineForToken(textWidget, line, "///") != -1) {
				if (checkLineForNextToken(textWidget, line, checkLineForToken(textWidget, line, "//") + 2, '"') == 0) {
					// check if the next char after // is " and ignore it because the "comment" is part of a string
				} else {
					startIndex = checkLineForToken(textWidget, line, "//");
					foreach (item; removeTagsFromComments) {
						textWidget.removeTag(item, startIndexFn(line, startIndex), lineEnd(line));
					}
					textWidget.addTag("comment", startIndexFn(line, startIndex), lineEnd(line));
				}
			}
			// check for multiline comment
			if (checkLineForToken(textWidget, line, "/*") != -1) {
				// comment in string literal
				if (checkLineForNextToken(textWidget, line, checkLineForToken(textWidget, line, "/*") + 2, '"') == 0) {
					// do nothing
				} else {
					startIndex = checkLineForToken(textWidget, line, "/*");
					isMultiLineComment = true;
					foreach (item; removeTagsFromComments) {
						textWidget.removeTag(item, startIndexFn(line, startIndex), lineEnd(line));
					}
					textWidget.addTag("comment", startIndexFn(line, startIndex), lineEnd(line));
				}
			} else if (isMultiLineComment == true) {
				foreach (item; removeTagsFromComments) {
					textWidget.removeTag(item, startIndexFn(line, startIndex), lineEnd(line));
				}
				textWidget.addTag("comment", lineStart(line), lineEnd(line));
			}
			// closes multiline comment
			if (checkLineForToken(textWidget, line, "*/") != -1) {
				if (checkLineForNextToken(textWidget, line, checkLineForToken(textWidget, line, "*/") + 2, '"') == 0) {
					// do nothing
				} else {
					isMultiLineComment = false;
					foreach (item; removeTagsFromComments) {
						textWidget.removeTag(item, startIndexFn(line, startIndex), lineEnd(line));
					}
					textWidget.addTag("comment", lineStart(line), lineStringDot(line) ~ endOfMultiLineComment(textWidget, line));
				}
			}
		}
	}

	public int getNumberOfLinesFromText(Text textWidget) {
		return (textWidget.getNumberOfLines().split(".")[0]).to!int;
	}

	public int checkLineForToken(Text textWidget, int line, char token) {
		return (textWidget.getLine(line).countUntil(token)).to!int;
	}

	public int checkLineForToken(Text textWidget, int line, string token) {
		return (textWidget.getLine(line).countUntil(token)).to!int;
	}

	public int checkLineForNextToken(Text textWidget, int line, int stopIndex, char token) {
		return (textWidget.getPartialLine(line, stopIndex).countUntil(token)).to!int;
	}

	public int checkLineForNextToken(Text textWidget, int line, int stopIndex, string token) {
		return (textWidget.getPartialLine(line, stopIndex).countUntil(token)).to!int;
	}

	public int getStringLength(Text textWidget, int line, char token, int startIndex) {
		return (textWidget.getPartialLine(line, startIndex + 1).countUntil(token)).to!int + 2;
	}

	public int numberOfStringsInLine(Text textWidget, int line) {
		return (textWidget.getLine(line).count('"')).to!int / 2;
	}

	public int numberOfCharsInLine(Text textWidget, int line) {
		return (textWidget.getLine(line).count("'")).to!int / 2;
	}

	public int numberOfEscapesInLine(Text textWidget, int line) {
		return (textWidget.getLine(line).count("\\")).to!int;
	}

	public string startIndexFn(int line, int startIndex) {
		return line.to!string ~ "." ~ startIndex.to!string;
	} 

	public string stopIndexFn(int line, int stopIndex) {
		return line.to!string ~ "." ~ stopIndex.to!string;
	} 

	public string lineStart(int line) {
		return line.to!string ~ ".0";
	}

	public string lineEnd(int line) {
		return line.to!string ~ ".end";
	}

	public string endOfMultiLineComment(Text textWidget, int line) {
		return (textWidget.getLine(line).countUntil("*/") + 2).to!string;
	}

	public string lineString(int line) {
		return line.to!string;
	}

	public string lineStringDot(int line) {
		return line.to!string ~ ".";
	}	
}

