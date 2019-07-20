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

	public void highlight(CommandArgs args, NoteBook noteBook, Text[] textWidgetArray, string syntaxTheme, bool manual = false) {
		string[] supportedLanguages = [".d", ".c", ".cpp", ".h", ".hpp"];
		if (supportedLanguages.canFind((noteBook.getTabText(noteBook.getCurrentTabId())).extension)
			|| manual == true) {

			Text textWidget = textWidgetArray[noteBook.getCurrentTabId()];

			textWidget.setForegroundColor("#ffffff");
			configureTags(textWidget, syntaxTheme);
			string[] allTags = ["keyword", "conditional", "loop", "type", "symbol", "number", "char", "string", "escapeCharacter", "function", "comment", "class"];
			foreach (tag; allTags) {
				textWidget.removeTag(tag, "1.0", "end");
			}
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

	// TODO syntax theme
	public void configureTags(Text textWidget, string syntaxTheme) {
		if (syntaxTheme.toLower == "gruvbox") {
			// gruvbox
			textWidget
				.setForegroundColor("#ebdbb2")										// creme
				.setBackgroundColor("#282828")										// dark grey
				.configTag("conditional", "-foreground #fb4934")					// red
				.configTag("loop", "-foreground #fb4934")							// red
				.configTag("type", "-foreground #fb4934")							// red	
				.configTag("keyword", "-foreground #fb4934")						// red
				.configTag("symbol", "-foreground #8ec07c")							// light green
				.configTag("number", "-foreground #d3869b")							// light blue
				.configTag("comment", "-foreground #928374")						// gray
				.configTag("char", "-foreground #b8bb26")							// green
				.configTag("string", "-foreground #b8bb26")							// green
				.configTag("escapeCharacter", "-foreground #fb4934")				// red
				.configTag("function", "-foreground #b8bb26")						// green
				.configTag("class", "-foreground #fabd2f")							// yellow
				.configTag("tabWidth", "-tabs {1c}");								// half of default
		} else {
			// default
			textWidget
				.configTag("conditional", "-foreground #f52a2a")					// red
				.configTag("loop", "-foreground #f52a2a")							// red
				.configTag("type", "-foreground #e277f7")							// light pink	
				.configTag("keyword", "-foreground #e277f7")						// light pink
				.configTag("symbol", "-foreground #fffb00")							// yellow
				.configTag("number", "-foreground #ff9d00")							// orange
				.configTag("comment", "-foreground #085710")						// dark green
				.configTag("char", "-foreground #00fff7")							// cyan
				.configTag("string", "-foreground #00fff7")							// cyan
				.configTag("escapeCharacter", "-foreground #bb2af5")				// neon pink
				.configTag("function", "-foreground #2a78f5")						// blue
				.configTag("class", "-foreground #fabd2f")							// yellow // TODO change color
				.configTag("tabWidth", "-tabs {1c}");								// half of default
		}	
	}

	public void searchHighlight(Text textWidget, string pattern, string tags) {
		string[] patternIndexes = textWidget.findAll(pattern);
		foreach (item; patternIndexes) {
			string[] tclGarbage = item.split('.');
			int lineIndex = tclGarbage[0].to!int;
			int charIndex = tclGarbage[1].to!int;
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
		int numberOfPattern;
		int arrayTypeStart;
		int arrayTypeStop;
		string[] removeTagsFromComments = ["keyword", "conditional", "loop", "type", "symbol", "number", "char", "string", "escapeCharacter", "function", "class"];
		string[] removeTagsFromCharString = ["keyword", "conditional", "loop", "type", "symbol", "number", "comment", "function", "class"];
		string[] capitalLetters = ["A", "B", "C", "D", "E", "F", "G", "H", "I", "J", "K", "L", "M", "N", "O", "P", "Q", "R", "S", "T", "U", "V", "W", "X", "Y", "Z"];

		// TODO refactor the if blocks into separate functions so its not cancer on your eyes
		for (int line = 1; line <= getNumberOfLinesFromText(textWidget); line++) {
			// check for special tk characters
			if (checkLineForToken(textWidget, line, "[") != -1) {
				startIndex = checkLineForToken(textWidget, line, "[");
				stopIndex = startIndex + 1;
				textWidget.addTag("symbol", startIndexFn(line, startIndex), stopIndexFn(line, stopIndex));
				numberOfPattern = numberOfPatternInLine(textWidget, line, "[");
				stopIndex += 1;
				for (int i = 1; i < numberOfPattern; i++) {
					startIndex = checkLineForNextToken(textWidget, line, stopIndex, "[") + stopIndex;
					stopIndex = startIndex + 1;
					textWidget.addTag("symbol", startIndexFn(line, startIndex), stopIndexFn(line, stopIndex));
				}
			}
			if (checkLineForToken(textWidget, line, "]") != -1) {
				startIndex = checkLineForToken(textWidget, line, "]");
				stopIndex = startIndex + 1;
				textWidget.addTag("symbol", startIndexFn(line, startIndex), stopIndexFn(line, stopIndex));
				numberOfPattern = numberOfPatternInLine(textWidget, line, "]");
				stopIndex += 1;
				for (int i = 1; i < numberOfPattern; i++) {
					startIndex = checkLineForNextToken(textWidget, line, stopIndex, "]") + stopIndex;
					stopIndex = startIndex + 1;
					textWidget.addTag("symbol", startIndexFn(line, startIndex), stopIndexFn(line, stopIndex));
				}
			}
			if (checkLineForToken(textWidget, line, "{") != -1) {
				startIndex = checkLineForToken(textWidget, line, "{");
				stopIndex = startIndex + 1;
				textWidget.addTag("symbol", startIndexFn(line, startIndex), stopIndexFn(line, stopIndex));
				numberOfPattern = numberOfPatternInLine(textWidget, line, "{");
				stopIndex += 1;
				for (int i = 1; i < numberOfPattern; i++) {
					startIndex = checkLineForNextToken(textWidget, line, stopIndex, "{") + stopIndex;
					stopIndex = startIndex + 1;
					textWidget.addTag("symbol", startIndexFn(line, startIndex), stopIndexFn(line, stopIndex));
				}
			}
			if (checkLineForToken(textWidget, line, "}") != -1) {
				startIndex = checkLineForToken(textWidget, line, "}");
				stopIndex = startIndex + 1;
				textWidget.addTag("symbol", startIndexFn(line, startIndex), stopIndexFn(line, stopIndex));
				numberOfPattern = numberOfPatternInLine(textWidget, line, "}");
				stopIndex += 1;
				for (int i = 1; i < numberOfPattern; i++) {
					startIndex = checkLineForNextToken(textWidget, line, stopIndex, "}") + stopIndex;
					stopIndex = startIndex + 1;
					textWidget.addTag("symbol", startIndexFn(line, startIndex), stopIndexFn(line, stopIndex));
				}
			}
			if (checkLineForToken(textWidget, line, ";") != -1) {
				startIndex = checkLineForToken(textWidget, line, ";");
				stopIndex = startIndex + 1;
				textWidget.addTag("symbol", startIndexFn(line, startIndex), stopIndexFn(line, stopIndex));
				numberOfPattern = numberOfPatternInLine(textWidget, line, ";");
				stopIndex += 1;
				for (int i = 1; i < numberOfPattern; i++) {
					startIndex = checkLineForNextToken(textWidget, line, stopIndex, ";") + stopIndex;
					stopIndex = startIndex + 1;
					textWidget.addTag("symbol", startIndexFn(line, startIndex), stopIndexFn(line, stopIndex));
				}
			}
			// check for string arrays
			if (checkLineForToken(textWidget, line, "string[") != -1) {
				startIndex = checkLineForToken(textWidget, line, "string[");
				stopIndex = startIndex.to!int + ("string".length).to!int;
				arrayTypeStart = stopIndex + 1;
				arrayTypeStop = checkLineForToken(textWidget, line, "]");
				textWidget.addTag("type", startIndexFn(line, startIndex), stopIndexFn(line, stopIndex));
				if (arrayTypeStart != arrayTypeStop) {
					textWidget.addTag("type", startIndexFn(line, arrayTypeStart), stopIndexFn(line, arrayTypeStop));
				}
			}
			// check for char arrays
			if (checkLineForToken(textWidget, line, "char[") != -1) {
				startIndex = checkLineForToken(textWidget, line, "char[");
				stopIndex = startIndex.to!int + ("string".length).to!int;
				arrayTypeStart = stopIndex + 1;
				arrayTypeStop = checkLineForToken(textWidget, line, "]");
				textWidget.addTag("type", startIndexFn(line, startIndex), stopIndexFn(line, stopIndex));
				if (arrayTypeStart != arrayTypeStop) {
					textWidget.addTag("type", startIndexFn(line, arrayTypeStart), stopIndexFn(line, arrayTypeStop));
				}
			}
			// check for int arrays
			if (checkLineForToken(textWidget, line, "int[") != -1) {
				startIndex = checkLineForToken(textWidget, line, "int[");
				stopIndex = startIndex.to!int + ("string".length).to!int;
				arrayTypeStart = stopIndex + 1;
				arrayTypeStop = checkLineForToken(textWidget, line, "]");
				textWidget.addTag("type", startIndexFn(line, startIndex), stopIndexFn(line, stopIndex));
				if (arrayTypeStart != arrayTypeStop) {
					textWidget.addTag("type", startIndexFn(line, arrayTypeStart), stopIndexFn(line, arrayTypeStop));
				}
			}
			// check for float arrays
			if (checkLineForToken(textWidget, line, "float[") != -1) {
				startIndex = checkLineForToken(textWidget, line, "float[");
				stopIndex = startIndex.to!int + ("string".length).to!int;
				arrayTypeStart = stopIndex + 1;
				arrayTypeStop = checkLineForToken(textWidget, line, "]");
				textWidget.addTag("type", startIndexFn(line, startIndex), stopIndexFn(line, stopIndex));
				if (arrayTypeStart != arrayTypeStop) {
					textWidget.addTag("type", startIndexFn(line, arrayTypeStart), stopIndexFn(line, arrayTypeStop));
				}
			}
			// check for double arrays
			if (checkLineForToken(textWidget, line, "double[") != -1) {
				startIndex = checkLineForToken(textWidget, line, "double[");
				stopIndex = startIndex.to!int + ("string".length).to!int;
				arrayTypeStart = stopIndex + 1;
				arrayTypeStop = checkLineForToken(textWidget, line, "]");
				textWidget.addTag("type", startIndexFn(line, startIndex), stopIndexFn(line, stopIndex));
				if (arrayTypeStart != arrayTypeStop) {
					textWidget.addTag("type", startIndexFn(line, arrayTypeStart), stopIndexFn(line, arrayTypeStop));
				}
			}
			// check for bool arrays
			if (checkLineForToken(textWidget, line, "bool[") != -1) {
				startIndex = checkLineForToken(textWidget, line, "bool[");
				stopIndex = startIndex.to!int + ("string".length).to!int;
				arrayTypeStart = stopIndex + 1;
				arrayTypeStop = checkLineForToken(textWidget, line, "]");
				textWidget.addTag("type", startIndexFn(line, startIndex), stopIndexFn(line, stopIndex));
				if (arrayTypeStart != arrayTypeStop) {
					textWidget.addTag("type", startIndexFn(line, arrayTypeStart), stopIndexFn(line, arrayTypeStop));
				}
			}
			// check for functions
			if (checkLineForToken(textWidget, line, "(") != -1) {
				stopIndex = checkLineForToken(textWidget, line, "(");
				// TODO add checks for ")", "[", "]", ";", ":" and maybe others
				string[] whitespace = textWidget.findAllInLine(" ", line);
				string[] tab = textWidget.findAllInLine("\t", line);
				string[] parentheses = textWidget.findAllInLine("(", line);
				string[] dot = textWidget.findAllInLine(".", line);

				int lastWhitespace = 0;
				int lastTab = 0;
				int lastParentheses = 0;
				int lastDot = 0;
				foreach (item; whitespace) {
					if (item.split(".")[1].to!int > lastWhitespace && item.split(".")[1].to!int < stopIndex) {
						lastWhitespace = item.split(".")[1].to!int;
					}
				}
				foreach (item; tab) {
					if (item.split(".")[1].to!int > lastTab && item.split(".")[1].to!int < stopIndex) {
						lastTab = item.split(".")[1].to!int;
					}
				}
				foreach (item; parentheses) {
					if (item.split(".")[1].to!int > lastParentheses && item.split(".")[1].to!int < stopIndex) {
						lastParentheses = item.split(".")[1].to!int;
					}
				}
				foreach (item; dot) {
					if (item.split(".")[1].to!int > lastDot && item.split(".")[1].to!int < stopIndex) {
						lastDot = item.split(".")[1].to!int;
					}
				}
				startIndex = max(lastWhitespace, lastTab, lastParentheses, lastDot) + 1; // add 1 to define start at the name and not the symbol indicating the end of highlight
				textWidget.addTag("function", startIndexFn(line, startIndex), stopIndexFn(line, stopIndex));
				stopIndex += 1; // add 1 to step over the opening parentheses since we dont highlight it with the function name
				int numberOfParentheses = numberOfParenthesesInLine(textWidget, line);
				for (int i = 1; i < numberOfParentheses; i++) {
					stopIndex = checkLineForNextToken(textWidget, line, stopIndex, "(") + stopIndex;
					whitespace = textWidget.findAllInLine(" ", line);
					tab = textWidget.findAllInLine("\t", line);
					parentheses = textWidget.findAllInLine("(", line);
					dot = textWidget.findAllInLine(".", line);

					lastWhitespace = 0;
					lastTab = 0;
					lastParentheses = 0;
					lastDot = 0;
					foreach (item; whitespace) {
						if (item.split(".")[1].to!int > lastWhitespace && item.split(".")[1].to!int < stopIndex) {
							lastWhitespace = item.split(".")[1].to!int;
						}
					}
					foreach (item; tab) {
						if (item.split(".")[1].to!int > lastTab && item.split(".")[1].to!int < stopIndex) {
							lastTab = item.split(".")[1].to!int;
						}
					}
					foreach (item; parentheses) {
						if (item.split(".")[1].to!int > lastParentheses && item.split(".")[1].to!int < stopIndex) {
							lastParentheses = item.split(".")[1].to!int;
						}
					}
					foreach (item; dot) {
						if (item.split(".")[1].to!int > lastDot && item.split(".")[1].to!int < stopIndex) {
							lastDot = item.split(".")[1].to!int;
						}
					}
					startIndex = max(lastWhitespace, lastTab, lastParentheses, lastDot) + 1;
					textWidget.addTag("function", startIndexFn(line, startIndex), stopIndexFn(line, stopIndex));
					stopIndex += 1;	
				}
			}
			// check for class
			foreach (letter; capitalLetters) {
				startIndex = checkLineForToken(textWidget, line, letter);
				if ((startIndex != -1 && textWidget.getChar(line, startIndex - 1) == " ") ||
					(startIndex != -1 && textWidget.getChar(line, startIndex - 1) == ".") ||
					(startIndex != -1 && textWidget.getChar(line, startIndex - 1) == "\t") ||
					(startIndex != -1 && textWidget.getChar(line, startIndex - 1) == "(") ||
					(startIndex != -1 && textWidget.getChar(line, startIndex - 1) == "\"") ||
					(startIndex != -1 && startIndex == 0)) {
					stopIndex = startIndex;
					for (; stopIndex < (textWidget.getLineLength(line).split(".")[1]).to!int; stopIndex++) {
						if (textWidget.getChar(line, stopIndex) == " " ||
							textWidget.getChar(line, stopIndex) == "{" ||
							textWidget.getChar(line, stopIndex) == "." ||
							textWidget.getChar(line, stopIndex) == "[" ||
							textWidget.getChar(line, stopIndex) == "(" ||
							textWidget.getChar(line, stopIndex) == ")" ||
							textWidget.getChar(line, stopIndex) == "\"" ||
							textWidget.getChar(line, stopIndex) == "!") {
							break;
						}
					}
				textWidget.addTag("class", startIndexFn(line, startIndex), startIndexFn(line, stopIndex));
				numberOfPattern = numberOfPatternInLine(textWidget, line, letter);
				for (int i = 1; i < numberOfPattern; i++) {
					startIndex = checkLineForNextToken(textWidget, line, stopIndex, letter) + stopIndex;
					if ((startIndex != -1 && textWidget.getChar(line, startIndex - 1) == " ") ||
						(startIndex != -1 && textWidget.getChar(line, startIndex - 1) == ".") ||
						(startIndex != -1 && textWidget.getChar(line, startIndex - 1) == "\t") ||
						(startIndex != -1 && textWidget.getChar(line, startIndex - 1) == "(") ||
						(startIndex != -1 && textWidget.getChar(line, startIndex - 1) == "\"")) {
						stopIndex = startIndex;
						for (; stopIndex < (textWidget.getLineLength(line).split(".")[1]).to!int; stopIndex++) {
							if (textWidget.getChar(line, stopIndex) == " " ||
								textWidget.getChar(line, stopIndex) == "{" ||
								textWidget.getChar(line, stopIndex) == "." ||
								textWidget.getChar(line, stopIndex) == "[" ||
								textWidget.getChar(line, stopIndex) == "(" ||
								textWidget.getChar(line, stopIndex) == ")" ||
								textWidget.getChar(line, stopIndex) == "\"" ||
								textWidget.getChar(line, stopIndex) == "!") {
								break;
							}
						}
					}
					textWidget.addTag("class", startIndexFn(line, startIndex), startIndexFn(line, stopIndex));
				}
				}
			}
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
						//stopIndex--; dude :(
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
					textWidget.removeTag(item, lineStart(line), lineEnd(line));
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

	public int numberOfPatternInLine(Text textWidget, int line, char pattern) {
		return (textWidget.getLine(line).count(pattern)).to!int;
	}

	public int numberOfPatternInLine(Text textWidget, int line, string pattern) {
		return (textWidget.getLine(line).count(pattern)).to!int;
	}

	public int numberOfParenthesesInLine(Text textWidget, int line) {
		return (textWidget.getLine(line).count("(")).to!int;
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