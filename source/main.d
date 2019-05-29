module main;

import tkd.tkdapplication;   
import std.stdio;
import std.conv;
import std.string;    
import std.algorithm;
import preferences, inputoutput, gui, tabs; // source imports

// NoteMaker application.
class Application : TkdApplication {

	// variables
	Window root;
	Gui gui;
	Preferences pref;
	InputOutput io;
	Tabs tabs;

	// initialize user interface
	override public void initInterface() {

		// sets up root
		this.root = mainWindow()
			.setDefaultIcon([new EmbeddedPng!("NoteMaker.png")])
			.setGeometry(0, 0, 600, 50)
			.setMinSize(700, 800)
			.setFullscreen(true);

		// makes the code in "gui.d" usable in "main.d"
		gui = new Gui(root);

		// creates the noteBook and the default tab
		auto noteBook = new NoteBook();
		auto mainPane = gui.createMainPane();

		// shows the noteBook adds the default tab to it
		noteBook
			.addTab("Main File", mainPane)
			.pack(0, 0, GeometrySide.top, GeometryFill.both, AnchorPosition.center, true);

		// makes the code in other files usable in "main.d"
		io = new InputOutput(root, gui.textMain, noteBook);
		tabs = new Tabs(root, noteBook, gui.textWidgetArray);
		pref = new Preferences(root, gui.textMain, gui.opacitySlider, gui.preferencesFile, noteBook, gui.textWidgetArray);

		// create the menu bar at the top
		auto menuBar = new MenuBar(root);

		// sets up the "File" menu
		auto fileMenu = new Menu(menuBar, "File", 0)
			.addEntry("Open File...", &openFile, "Ctrl+O")
			.addEntry("Save", &saveFile, "Ctrl+S")
			.addEntry("Save As", &saveFileAs, "Ctrl+Alt+S")
			.addSeparator()
			.addEntry("New Tab", &tabs.createNewTab, "Ctrl+T")
			.addEntry("Close Tab", &tabs.closeTab, "Ctrl+W")
			.addEntry("Next Tab", &tabs.nextTab, "Ctrl+1")
			.addEntry("Previous Tab", &tabs.previousTab, "Ctrl+2") 
			.addEntry("Reopen Closed Tab", &tabs.reopenClosedTab, "Ctrl+3")
			.addSeparator()
			.addEntry("Preferences", &openPreferences, "Ctrl+P")
			.addSeparator()
			.addEntry("Syntax Highlight", &this.highlight, "Ctrl+L")
			.addEntry("Quit", &this.exitApplication, "Ctrl+Q");

		// runs every 3 seconds: resets the title 
		this.root.setIdleCommand(delegate(CommandArgs args) {
			root.setTitle("Note Maker");
			root.setOpacity(gui.opacitySlider.getValue());
			root.setIdleCommand(args.callback, 3000);
		});

		// sets opacity on application boot
		root.setOpacity(gui.opacitySlider.getValue());

		// sets up the keybindings
		root.bind("<Control-o>", &openFile); // Open#
		root.bind("<Control-s>", &saveFile); // Save
		root.bind("<Control-Alt-s>", &saveFileAs); // Save As
		root.bind("<Control-t>", &tabs.createNewTab); // New Tab
		root.bind("<Control-w>", &tabs.closeTab); // Close Tab
		root.bind("<Control-KeyPress-1>", &tabs.nextTab); // Next Tab
		root.bind("<Control-KeyPress-2>", &tabs.previousTab); // Previous Tab
		root.bind("<Control-KeyPress-3>", &tabs.reopenClosedTab); // Reopen Closed Tab
		root.bind("<Control-p>", &openPreferences); // Preferences
		root.bind("<Control-q>", &this.exitApplication); // Quit
		root.bind("<Control-l>", &this.highlight);
		
		// checks if the preferences file exists if false creates one and tells you about it
		if (!gui.preferencesFileExists) {
			auto dialog = new MessageDialog(this.root, "Preferences File")
				.setDetailMessage("Preferences file could not be found and has been created!")
				.show();
		}
	}

	// opens a file according to the dialog
	public void openFile(CommandArgs args) {
		io.openOpenFileDialog(args, tabs.updateArray());
	}

	public void saveFile(CommandArgs args) {
		io.saveFile(args, tabs.updateArray());
	}

	// saves a file according to the dialog
	public void saveFileAs(CommandArgs args) {
		io.openSaveFileDialog(args, tabs.updateArray());
	}

	// opens the preferences window
	public void openPreferences(CommandArgs args) {
		pref.openPreferencesWindow(args, tabs.updateArray());
	}

	// !Testing! highlights the defined syntax
	public void highlight(CommandArgs args) {
		tabs.updateArray()[0]
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

		string fileToOpen;
		
		version (Windows) {
			fileToOpen = "C:/Users/Grim/Desktop/Dropbox/GitHub/NoteMaker-D/source/main.d";
		} else {
			fileToOpen = "/home/grim/Dropbox/GitHub/NoteMaker-D/source/main.d";
		}
		
		auto f = File(fileToOpen, "r");

			string fileContent;

			while (!f.eof()) { 
				string line = chomp(f.readln()); 
				fileContent ~= line ~ "\n"; 
				}

			f.close();

		tabs.updateArray()[0].insertText(0, 0, fileContent);

		syntaxHighlight(tabs.updateArray()[0], "module", "violet");
		syntaxHighlight(tabs.updateArray()[0], "import", "violet");
		syntaxHighlight(tabs.updateArray()[0], "private", "violet");
		syntaxHighlight(tabs.updateArray()[0], "public", "violet");
		syntaxHighlight(tabs.updateArray()[0], "true", "violet");
		syntaxHighlight(tabs.updateArray()[0], "false", "violet");
		syntaxHighlight(tabs.updateArray()[0], "override", "violet");
		syntaxHighlight(tabs.updateArray()[0], "protected", "violet");
		//syntaxHighlight(tabs.updateArray()[0], "main", "teal");
		syntaxHighlight(tabs.updateArray()[0], "new ", "red");
		syntaxHighlight(tabs.updateArray()[0], "if ", "red");
		syntaxHighlight(tabs.updateArray()[0], "else ", "red");
		syntaxHighlight(tabs.updateArray()[0], "class", "yellow");
		syntaxHighlight(tabs.updateArray()[0], "string", "violet");
		syntaxHighlight(tabs.updateArray()[0], "int", "violet");
		syntaxHighlight(tabs.updateArray()[0], "float", "violet");
		syntaxHighlight(tabs.updateArray()[0], "void", "violet");
		syntaxHighlight(tabs.updateArray()[0], "auto", "violet");
		syntaxHighlight(tabs.updateArray()[0], "char", "violet");
		syntaxHighlight(tabs.updateArray()[0], "bool", "violet");
		syntaxHighlight(tabs.updateArray()[0], "this.", "teal");
		syntaxHighlight(tabs.updateArray()[0], "Window", "orange");
		syntaxHighlight(tabs.updateArray()[0], "SpinBox", "orange");
		syntaxHighlight(tabs.updateArray()[0], "CheckButton", "orange");
		syntaxHighlight(tabs.updateArray()[0], "Entry", "orange");
		syntaxHighlight(tabs.updateArray()[0], "Button", "orange");
		syntaxHighlight(tabs.updateArray()[0], "Frame", "orange");
		//syntaxHighlight(tabs.updateArray()[0], "(", "yellow");
		//syntaxHighlight(tabs.updateArray()[0], ")", "yellow");
		//syntaxHighlight(tabs.updateArray()[0], "[", "yellow");
		//syntaxHighlight(tabs.updateArray()[0], "]", "yellow");
		//syntaxHighlight(tabs.updateArray()[0], "[]", "yellow");
		//syntaxHighlight(tabs.updateArray()[0], "()", "yellow");
		syntaxHighlight(tabs.updateArray()[0], "~", "yellow");
		//syntaxHighlight(tabs.updateArray()[0], "{", "red"); error, probably tcl special character
		//syntaxHighlight(tabs.updateArray()[0], "}", "yellow");
		syntaxHighlight(tabs.updateArray()[0], "'", "green");
		//syntaxHighlight(tabs.updateArray()[0], ",", "yellow");
		syntaxHighlight(tabs.updateArray()[0], "=", "yellow");
		//syntaxHighlight(tabs.updateArray()[0], ".", "yellow");
		syntaxHighlight(tabs.updateArray()[0], "&", "yellow");
		syntaxHighlight(tabs.updateArray()[0], "<", "yellow");
		syntaxHighlight(tabs.updateArray()[0], ">", "yellow");
		syntaxHighlight(tabs.updateArray()[0], ">=", "yellow");
		syntaxHighlight(tabs.updateArray()[0], ">=", "yellow");
		//syntaxHighlight(tabs.updateArray()[0], "-", "yellow");
		syntaxHighlight(tabs.updateArray()[0], "+", "yellow");
		syntaxHighlight(tabs.updateArray()[0], "*", "yellow");
		syntaxHighlight(tabs.updateArray()[0], "/", "yellow");
		//syntaxHighlight(tabs.updateArray()[0], ":", "yellow");
		syntaxHighlight(tabs.updateArray()[0], "0", "orange");
		syntaxHighlight(tabs.updateArray()[0], "1", "orange");
		syntaxHighlight(tabs.updateArray()[0], "2", "orange");
		syntaxHighlight(tabs.updateArray()[0], "3", "orange");
		syntaxHighlight(tabs.updateArray()[0], "4", "orange");
		syntaxHighlight(tabs.updateArray()[0], "5", "orange");
		syntaxHighlight(tabs.updateArray()[0], "6", "orange");
		syntaxHighlight(tabs.updateArray()[0], "7", "orange");
		syntaxHighlight(tabs.updateArray()[0], "8", "orange");
		syntaxHighlight(tabs.updateArray()[0], "9", "orange");
		syntaxHighlight(tabs.updateArray()[0], "else if ", "red");
		syntaxHighlight(tabs.updateArray()[0], "while ", "violet");
		syntaxHighlight(tabs.updateArray()[0], "for ", "violet");
		syntaxHighlight(tabs.updateArray()[0], "break", "violet");
		syntaxHighlight(tabs.updateArray()[0], "continue", "violet");
		syntaxHighlight(tabs.updateArray()[0], "writeln", "teal");
		syntaxHighlight(tabs.updateArray()[0], ".length", "red");
		syntaxHighlight(tabs.updateArray()[0], "mainWindow", "orange");
		syntaxHighlight(tabs.updateArray()[0], "to!", "red"); 
		syntaxHighlight(tabs.updateArray()[0], "TkdApplication", "orange"); 
		syntaxHighlight(tabs.updateArray()[0], "Application", "orange"); 
		//syntaxHighlight(tabs.updateArray()[0], ";", "red"); error, probably tcl special character

		writeln("lines: " ~ tabs.updateArray()[0].getNumberOfLines());
		bool isMultiLineComment = false;
		bool withinString = false;
		int startIndex;
		int stopIndex;
		int patternNumber = 1;

		for (int line = 1; line <= tabs.updateArray()[0].getNumberOfLines().split(".")[0].to!int; line++) {
			// add check for comments where if they are withing "", they get ignored!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
			// check for comment
			if (tabs.updateArray()[0].getLine(line).countUntil("//") != -1 || tabs.updateArray()[0].getLine(line).countUntil("///") != -1) {
				if (tabs.updateArray()[0].getPartialLine(line, tabs.updateArray()[0].getLine(line).countUntil("//") + 2).countUntil("\"") == 0 ||
					tabs.updateArray()[0].getPartialLine(line, tabs.updateArray()[0].getLine(line).countUntil("//") + 2).countUntil("\"") == 1) {
					writeln("closing comment should be ignored");
				} else {
					startIndex = tabs.updateArray()[0].getLine(line).countUntil("//");
					tabs.updateArray()[0].removeTag("violet", line.to!string ~ "." ~ startIndex.to!string, line.to!string ~ ".end");
					tabs.updateArray()[0].addTag("black", line.to!string ~ "." ~ startIndex.to!string, line.to!string ~ ".end");
				}
			}
			// check for multiline comment
			if (tabs.updateArray()[0].getLine(line).countUntil("/*") != -1) {
				// comment in string literal
				if (tabs.updateArray()[0].getPartialLine(line, tabs.updateArray()[0].getLine(line).countUntil("/*") + 2).countUntil("\"") == 0) {
					writeln("comment should be ignored");
				} else {
					startIndex = tabs.updateArray()[0].getLine(line).countUntil("/*");
					isMultiLineComment = true;
					tabs.updateArray()[0].addTag("black", line.to!string ~ "." ~ startIndex.to!string, line.to!string ~ ".end");
				}
			} else if (isMultiLineComment == true) { // if multiline comment then apply tag, hoping this will fix it
				tabs.updateArray()[0].addTag("black", line.to!string ~ ".0", line.to!string ~ ".end");
			}
			// closes multiline comment
			if (tabs.updateArray()[0].getLine(line).countUntil("*/") != -1) {
				if (tabs.updateArray()[0].getPartialLine(line, tabs.updateArray()[0].getLine(line).countUntil("*/") + 2).countUntil("\"") == 0) {
					writeln("closing comment should be ignored");
				} else {
					isMultiLineComment = false;
				tabs.updateArray()[0].addTag("black", line.to!string ~ ".0", line.to!string ~ "." ~ (tabs.updateArray()[0].getLine(line).countUntil("*/") + 2).to!string);
				}
			}
			// check for literal string
			if (tabs.updateArray()[0].getLine(line).countUntil('"') != -1) {
				startIndex = tabs.updateArray()[0].getLine(line).countUntil('"');
				int fromStartToClose = (tabs.updateArray()[0].getPartialLine(line, startIndex + 1).countUntil('"')) + 2;
				stopIndex = startIndex + fromStartToClose;
				int numberOfLiterals = tabs.updateArray()[0].getLine(line).count("\"") / 2;
				tabs.updateArray()[0].removeTag("violet", line.to!string ~ "." ~ startIndex.to!string, line.to!string ~ "." ~ stopIndex.to!string);
				tabs.updateArray()[0].addTag("green", line.to!string ~ "." ~ startIndex.to!string, line.to!string ~ "." ~ stopIndex.to!string);
				for (int i = 1; i < numberOfLiterals; i++) {
					startIndex = tabs.updateArray()[0].getPartialLine(line, stopIndex).countUntil('"') + stopIndex;
					fromStartToClose = tabs.updateArray()[0].getPartialLine(line, startIndex + 1).countUntil('"') + 2;
					stopIndex = startIndex + fromStartToClose;
					tabs.updateArray()[0].removeTag("violet", line.to!string ~ "." ~ startIndex.to!string, line.to!string ~ "." ~ stopIndex.to!string);
					tabs.updateArray()[0].addTag("green", line.to!string ~ "." ~ startIndex.to!string, line.to!string ~ "." ~ stopIndex.to!string);
				}
			}
		}
	}

	public void syntaxHighlight(Text textWidget, string pattern, string tags) {
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

	// quits the application.
	public void exitApplication(CommandArgs args) {
		this.exit();
		writeln("Application closed!");
	}
}

// runs the application.
void main(string[] args) {
	auto app = new Application();                      
	app.run();                                  
}