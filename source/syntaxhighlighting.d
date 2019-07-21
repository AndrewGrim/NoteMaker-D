module syntaxhighlighting;

import tkd.tkdapplication;   
import std.stdio;
import std.conv;
import std.string;    
import std.algorithm;
import std.path;
import std.file;

/// Class for highlighting the syntax.
class Syntax {

	/// Variable used by saveOnModified to determine whether to save upong loading the file.
	/// Because syntax highlight triggers the flag.
	bool highlightOnLoad;

	public bool getHighlightOnLoad() {
		return highlightOnLoad;
	}

	public void setHighlightOnLoad(bool state) {
		highlightOnLoad = state;
	}

	/// Main method. Checks if the file extension is supported. If so proceeds.
	/// Goes through all the syntax text files and uses Tk's Text's built in search to highlight keywords, types, numbers etc.
	/// Then does a second pass. Going line by line to highlight everything else.
	public void highlight(CommandArgs args, NoteBook noteBook, Text[] textWidgetArray, string syntaxTheme, Text terminalWidget, bool manual = false) { // @suppress(dscanner.suspicious.unused_parameter) // @suppress(dscanner.style.long_line)
		string[] supportedLanguages = [".d", ".c", ".cpp", ".h", ".hpp"];
		if (supportedLanguages.canFind((noteBook.getTabText(noteBook.getCurrentTabId())).extension)
			|| manual == true) {

			Text textWidget = textWidgetArray[noteBook.getCurrentTabId()];

			textWidget.setForegroundColor("#ffffff");
			configureTags(textWidget, syntaxTheme, terminalWidget);
			string[] allTags = ["keyword", "conditional", "loop", "type", "symbol", "number", "char", "string",
								"escapeCharacter", "function", "comment", "class"];
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

	/// Adds all the required tags to the Text widget. Tag options are different depending on the theme.
	public void configureTags(Text textWidget, string syntaxTheme, Text terminalWidget) {
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

			terminalWidget
				.setForegroundColor("#ebdbb2")
				.setBackgroundColor("#282828");
		} else {
			// default
			textWidget
				.setForegroundColor("#ffffff")										// white
				.setBackgroundColor("#000000")										// black
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
				.configTag("class", "-foreground #fadc0f")							// yellow
				.configTag("tabWidth", "-tabs {1c}");								// half of default
			
			terminalWidget
				.setForegroundColor("#ffffff")
				.setBackgroundColor("#000000");
		}	
	}

	/// Uses Tk's search to highligh certain things grabbed from the syntax text files.
	public void searchHighlight(Text textWidget, string pattern, string tags) {
		string[] patternIndexes = textWidget.findAll(pattern);
		foreach (item; patternIndexes) {
			string[] tclGarbage = item.split('.');
			const int lineIndex = tclGarbage[0].to!int;
			const int charIndex = tclGarbage[1].to!int;
			const int endIndex = charIndex.to!int + pattern.length.to!int;
			const string stopIndex = lineIndex.to!string ~ "." ~ endIndex.to!string;
			textWidget.addTag(tags, item, stopIndex.to!string);
		}
	}
		
	/// Second pass. Goes through the text line by line and checks for arrays, special symbol, escape characters,
	/// functions, classes, enums, structs, strings, chars, comments and multi line comments.
	public void lineByLineHighlight(Text textWidget) {
		bool isMultiLineComment = false;
		int startIndex;
		int stopIndex;
		int numberOfPattern;
		int arrayTypeStart;
		int arrayTypeStop;
		string[] removeTagsFromComments = ["keyword", "conditional", "loop", "type", "symbol", "number",
										   "char", "string", "escapeCharacter", "function", "class"];
		string[] removeTagsFromCharString = ["keyword", "conditional", "loop", "type",
											 "symbol", "number", "comment", "function", "class"];
		string[] capitalLetters = ["A", "B", "C", "D", "E", "F", "G", "H", "I", "J",
								   "K", "L", "M", "N", "O", "P", "Q", "R", "S", "T", "U", "V", "W", "X", "Y", "Z"];
		string[] specialTkSymbols = ["[", "]", "{", "}", ";"];
		string[] arrayTypes = ["string[", "char[", "int[", "float[", "double[", "bool["];

		// TODO refactor the if blocks into separate functions so its not cancer on your eyes
		for (int line = 1; line <= getNumberOfLinesFromText(textWidget); line++) {
			// Check for special tk characters.
			foreach (symbol; specialTkSymbols) {
				if (checkLineForToken(textWidget, line, symbol) != -1) {
					startIndex = checkLineForToken(textWidget, line, symbol);
					stopIndex = startIndex + 1;
					textWidget.addTag("symbol", startIndexFn(line, startIndex), stopIndexFn(line, stopIndex));
					numberOfPattern = getNumberOfPatternInLine(textWidget, line, symbol);
					stopIndex += 1;
					for (int i = 1; i < numberOfPattern; i++) {
						startIndex = checkLineForNextToken(textWidget, line, stopIndex, symbol) + stopIndex;
						stopIndex = startIndex + 1;
						textWidget.addTag("symbol", startIndexFn(line, startIndex), stopIndexFn(line, stopIndex));
					}
				}
			}
			// Check for arrays.
			foreach (arrayType; arrayTypes) {
				if (checkLineForToken(textWidget, line, arrayType) != -1) {
					startIndex = checkLineForToken(textWidget, line, arrayType);
					stopIndex = startIndex.to!int + ("string".length).to!int;
					arrayTypeStart = stopIndex + 1;
					arrayTypeStop = checkLineForToken(textWidget, line, "]");
					textWidget.addTag("type", startIndexFn(line, startIndex), stopIndexFn(line, stopIndex));
					if (arrayTypeStart != arrayTypeStop) {
						textWidget.addTag("type", startIndexFn(line, arrayTypeStart), stopIndexFn(line, arrayTypeStop));
					}
				}
			}
			// Check for functions.
			if (checkLineForToken(textWidget, line, "(") != -1) {
				stopIndex = checkLineForToken(textWidget, line, "(");
				string[] whitespace = textWidget.findAllInLine(" ", line); // @suppress(dscanner.suspicious.unmodified)
				string[] tab = textWidget.findAllInLine("\t", line); // @suppress(dscanner.suspicious.unmodified)
				string[] openingParentheses = textWidget.findAllInLine("(", line); // @suppress(dscanner.suspicious.unmodified)
				string[] closingParentheses = textWidget.findAllInLine(")", line); // @suppress(dscanner.suspicious.unmodified)
				string[] dot = textWidget.findAllInLine(".", line); // @suppress(dscanner.suspicious.unmodified)
				string[] semicolon = textWidget.findAllInLine(";", line); // @suppress(dscanner.suspicious.unmodified)
				string[] colon = textWidget.findAllInLine(":", line); // @suppress(dscanner.suspicious.unmodified)
				string[] exclamation = textWidget.findAllInLine("!", line); // @suppress(dscanner.suspicious.unmodified)
				string[] openingBrackets = textWidget.findAllInLine("[", line); // @suppress(dscanner.suspicious.unmodified)
				string[] closingBrackets = textWidget.findAllInLine("]", line); // @suppress(dscanner.suspicious.unmodified)
				string[] newline = textWidget.findAllInLine("\n", line); // @suppress(dscanner.suspicious.unmodified)
				string[][string] functionEnds;
				int[string] lastSymbol;

				int lastWhitespace = 0; // @suppress(dscanner.suspicious.unmodified)
				int lastTab = 0; // @suppress(dscanner.suspicious.unmodified)
				int lastOpeningParentheses = 0; // @suppress(dscanner.suspicious.unmodified)
				int lastClosingParentheses = 0; // @suppress(dscanner.suspicious.unmodified)
				int lastDot = 0; // @suppress(dscanner.suspicious.unmodified)
				int lastSemicolon = 0; // @suppress(dscanner.suspicious.unmodified)
				int lastColon = 0; // @suppress(dscanner.suspicious.unmodified)
				int lastExclamation = 0; // @suppress(dscanner.suspicious.unmodified)
				int lastOpeningBrackets = 0; // @suppress(dscanner.suspicious.unmodified)
				int lastClosingBrackets = 0; // @suppress(dscanner.suspicious.unmodified)
				int lastNewline = 0; // @suppress(dscanner.suspicious.unmodified)

				functionEnds["whitespace"] = whitespace;
				functionEnds["tab"] = tab;
				functionEnds["openingParentheses"] = openingParentheses;
				functionEnds["closingParentheses"] = closingParentheses;
				functionEnds["dot"] = dot;
				functionEnds["semicolon"] = semicolon;
				functionEnds["colon"] = colon;
				functionEnds["exclamation"] = exclamation;
				functionEnds["openingBrackets"] = openingBrackets;
				functionEnds["closingBrackets"] = closingBrackets;
				functionEnds["newline"] = newline;

				lastSymbol["whitespace"] = lastWhitespace;
				lastSymbol["tab"] = lastTab;
				lastSymbol["openingParentheses"] = lastOpeningParentheses;
				lastSymbol["closingParentheses"] = lastClosingParentheses;
				lastSymbol["dot"] = lastDot;
				lastSymbol["semicolon"] = lastSemicolon;
				lastSymbol["colon"] = lastColon;
				lastSymbol["exclamation"] = lastExclamation;
				lastSymbol["openingBrackets"] = lastOpeningBrackets;
				lastSymbol["closingBrackets"] = lastClosingBrackets;
				lastSymbol["newline"] = lastNewline;

				foreach (key, value; functionEnds) {
					foreach (item; value) {
						if (item.split(".")[1].to!int > lastSymbol[key] && item.split(".")[1].to!int < stopIndex) {
							lastSymbol[key] = item.split(".")[1].to!int;
						}
					}
				}

				startIndex = max(lastSymbol["whitespace"],
								 lastSymbol["tab"],
								 lastSymbol["openingParentheses"],
								 lastSymbol["closingParentheses"],
								 lastSymbol["dot"],
								 lastSymbol["semicolon"],
								 lastSymbol["colon"],
								 lastSymbol["exclamation"],
								 lastSymbol["openingBrackets"],
								 lastSymbol["closingBrackets"],
								 lastSymbol["newline"]
								 ); 
				if (startIndex != 0) {
					startIndex += 1; // Add 1 to define start at the name and not the symbol indicating the end of highlight.
				}
				textWidget.addTag("function", startIndexFn(line, startIndex), stopIndexFn(line, stopIndex));
				stopIndex += 1; // Add 1 to step over the opening parentheses since we dont highlight it with the function name.
				const int numberOfParentheses = getNumberOfParenthesesInLine(textWidget, line);
				for (int i = 1; i < numberOfParentheses; i++) {
					stopIndex = checkLineForNextToken(textWidget, line, stopIndex, "(") + stopIndex;

					lastSymbol["whitespace"] = lastWhitespace;
					lastSymbol["tab"] = lastTab;
					lastSymbol["openingParentheses"] = lastOpeningParentheses;
					lastSymbol["closingParentheses"] = lastClosingParentheses;
					lastSymbol["dot"] = lastDot;
					lastSymbol["semicolon"] = lastSemicolon;
					lastSymbol["colon"] = lastColon;
					lastSymbol["exclamation"] = lastExclamation;
					lastSymbol["openingBrackets"] = lastOpeningBrackets;
					lastSymbol["closingBrackets"] = lastClosingBrackets;
					lastSymbol["newline"] = lastNewline;

					foreach (key, value; functionEnds) {
						foreach (item; value) {
							if (item.split(".")[1].to!int > lastSymbol[key] && item.split(".")[1].to!int < stopIndex) {
								lastSymbol[key] = item.split(".")[1].to!int;
							}
						}
					}

					startIndex = max(lastSymbol["whitespace"],
								 lastSymbol["tab"],
								 lastSymbol["openingParentheses"],
								 lastSymbol["closingParentheses"],
								 lastSymbol["dot"],
								 lastSymbol["semicolon"],
								 lastSymbol["colon"],
								 lastSymbol["exclamation"],
								 lastSymbol["openingBrackets"],
								 lastSymbol["closingBrackets"],
								 lastSymbol["newline"]
								 ) + 1; // Add 1 to define start at the name and not the symbol indicating the end of highlight.
					textWidget.addTag("function", startIndexFn(line, startIndex), stopIndexFn(line, stopIndex));
				}
			}
			// Check for class.
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
				numberOfPattern = getNumberOfPatternInLine(textWidget, line, letter);
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
			// Check for literal string.
			if (checkLineForToken(textWidget, line, '"') != -1) {
				startIndex = checkLineForToken(textWidget, line, '"');
				int fromStartToClose = getStringLength(textWidget, line, '"', startIndex);
				stopIndex = startIndex + fromStartToClose;
				const int numberOfLiterals = getNumberOfStringsInLine(textWidget, line);
				foreach (item; removeTagsFromCharString) {
					textWidget.removeTag(item, startIndexFn(line, startIndex), stopIndexFn(line, stopIndex));
				}
				textWidget.addTag("string", startIndexFn(line, startIndex), stopIndexFn(line, stopIndex));
				if (checkLineForToken(textWidget, line, "\"\\\"\"") != -1) {
					// Corner case where the last " in "\"" would not get tagged, because they're coded to work in pairs .
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
						// Corner case where the last " in "\"" would not get tagged, because they're coded to work in pairs. 
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
			// Check for char.
			if (checkLineForToken(textWidget, line, "'") != -1) {
				startIndex = checkLineForToken(textWidget, line, "'");
				int fromStartToClose = checkLineForNextToken(textWidget, line, startIndex + 1, "'") + 2;
				stopIndex = startIndex + fromStartToClose;
				const int numberOfLiterals = getNumberOfCharsInLine(textWidget, line);
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
			// Check for escape characters.
			if (checkLineForToken(textWidget, line, "\\") != -1) {
				startIndex = checkLineForToken(textWidget, line, "\\");
				stopIndex = startIndex + 2;
				const int numberOfEscapes = getNumberOfEscapesInLine(textWidget, line);
				foreach (item; removeTagsFromComments) {
					textWidget.removeTag(item, startIndexFn(line, startIndex), stopIndexFn(line, stopIndex));
				}
				textWidget.addTag("escapeCharacter", startIndexFn(line, startIndex), stopIndexFn(line, stopIndex));
				for (int i = 1; i < numberOfEscapes; i++) {
					startIndex = checkLineForNextToken(textWidget, line, stopIndex, "\\") + stopIndex;
					stopIndex = startIndex + 2;
					if (i == (numberOfEscapes - 1)) {
						stopIndex -= 1;
					}
					foreach (item; removeTagsFromComments) {
						textWidget.removeTag(item, startIndexFn(line, startIndex), stopIndexFn(line, stopIndex));
					}
					textWidget.addTag("escapeCharacter", startIndexFn(line, startIndex), stopIndexFn(line, stopIndex));
				}
			}
			// Check for comment.
			if (checkLineForToken(textWidget, line, "//") != -1 || checkLineForToken(textWidget, line, "///") != -1) {
				if (checkLineForNextToken(textWidget, line, checkLineForToken(textWidget, line, "//") + 2, '"') == 0) {
					// Check if the next char after // is " and ignore it because the "comment" is part of a string.
				} else {
					startIndex = checkLineForToken(textWidget, line, "//");
					foreach (item; removeTagsFromComments) {
						textWidget.removeTag(item, startIndexFn(line, startIndex), lineEnd(line));
					}
					textWidget.addTag("comment", startIndexFn(line, startIndex), lineEnd(line));
				}
			}
			// Check for multiline comment.
			if (checkLineForToken(textWidget, line, "/*") != -1) {
				// Comment in string literal.
				if (checkLineForNextToken(textWidget, line, checkLineForToken(textWidget, line, "/*") + 2, '"') == 0) {
					// Do nothing.
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
			// Closes multiline comment.
			if (checkLineForToken(textWidget, line, "*/") != -1) {
				if (checkLineForNextToken(textWidget, line, checkLineForToken(textWidget, line, "*/") + 2, '"') == 0) {
					// Do nothing.
				} else {
					isMultiLineComment = false;
					foreach (item; removeTagsFromComments) {
						textWidget.removeTag(item, startIndexFn(line, startIndex), lineEnd(line));
					}
					textWidget.addTag("comment", lineStart(line), lineStringDot(line) ~ getEndOfMultiLineComment(textWidget, line));
				}
			}
		}
	}

	public int getNumberOfLinesFromText(Text textWidget) {
		return (textWidget.getNumberOfLines().split(".")[0]).to!int;
	}

	/// Checks if the token is in line. If its is returns the index otherwise -1.
	public int checkLineForToken(Text textWidget, int line, char token) {
		return (textWidget.getLine(line).countUntil(token)).to!int;
	}

	/// Checks if the token is in line. If its is returns the index otherwise -1.
	public int checkLineForToken(Text textWidget, int line, string token) {
		return (textWidget.getLine(line).countUntil(token)).to!int;
	}

	/// Checks if there is another token in line. If its is returns the index otherwise -1.
	public int checkLineForNextToken(Text textWidget, int line, int stopIndex, char token) {
		return (textWidget.getPartialLine(line, stopIndex).countUntil(token)).to!int;
	}

	/// Checks if there is another token in line. If its is returns the index otherwise -1.
	public int checkLineForNextToken(Text textWidget, int line, int stopIndex, string token) {
		return (textWidget.getPartialLine(line, stopIndex).countUntil(token)).to!int;
	}

	public int getStringLength(Text textWidget, int line, char token, int startIndex) {
		return (textWidget.getPartialLine(line, startIndex + 1).countUntil(token)).to!int + 2;
	}

	public int getNumberOfStringsInLine(Text textWidget, int line) {
		return (textWidget.getLine(line).count('"')).to!int / 2;
	}

	public int getNumberOfCharsInLine(Text textWidget, int line) {
		return (textWidget.getLine(line).count("'")).to!int / 2;
	}

	public int getNumberOfEscapesInLine(Text textWidget, int line) {
		return (textWidget.getLine(line).count("\\")).to!int;
	}

	public int getNumberOfPatternInLine(Text textWidget, int line, char pattern) {
		return (textWidget.getLine(line).count(pattern)).to!int;
	}

	public int getNumberOfPatternInLine(Text textWidget, int line, string pattern) {
		return (textWidget.getLine(line).count(pattern)).to!int;
	}

	public int getNumberOfParenthesesInLine(Text textWidget, int line) {
		return (textWidget.getLine(line).count("(")).to!int;
	}

	/// Concatenates the line number and the startIndex.
	public string startIndexFn(int line, int startIndex) {
		return line.to!string ~ "." ~ startIndex.to!string;
	} 

	/// Concatenates the line number and the stopIndex.
	public string stopIndexFn(int line, int stopIndex) {
		return line.to!string ~ "." ~ stopIndex.to!string;
	} 

	/// Concatenates line number with "0" which signifies the beginning of the line.
	public string lineStart(int line) {
		return line.to!string ~ ".0";
	}

	/// Concatenates line number with "end" which signifies the end of the line.
	public string lineEnd(int line) {
		return line.to!string ~ ".end";
	}
 
	public string getEndOfMultiLineComment(Text textWidget, int line) {
		return (textWidget.getLine(line).countUntil("*/") + 2).to!string;
	}

	/// Concatenates the line number and the "." which separates the line from the character index.
	public string lineStringDot(int line) {
		return line.to!string ~ ".";
	}	
}