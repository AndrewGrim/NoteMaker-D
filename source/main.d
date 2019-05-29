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
			.configTag("green", "-foreground greed")
			.configTag("blue", "-foreground blue")
			.configTag("teal", "-foreground teal")
			.configTag("indigo", "-foreground indigo")
			.configTag("violet", "-foreground violet")
			.configTag("black", "-foreground black")
			.configTag("gray", "-foreground gray")
			.configTag("white", "-foreground white");

		string fileToOpen;
		
		version (Windows) {
			fileToOpen = "C:/Users/Grim/Desktop/Dropbox/GitHub/PasswordGenerator-D/source/main.d";
		} else {
			fileToOpen = "/home/grim/Dropbox/GitHub/PasswordGenerator-D/source/main.d";
		}
		
		auto f = File(fileToOpen, "r");

			string fileContent;

            while (!f.eof()) { 
                string line = chomp(f.readln()); 
                fileContent ~= line ~ "\n"; 
                }

            f.close();

		tabs.updateArray()[0].insertText(0, 0, fileContent);

		// maybe change to regular expression to avoid duplicates like "[" and "[]"
		syntaxHighlight(tabs.updateArray()[0], "module", "violet");
		syntaxHighlight(tabs.updateArray()[0], "import", "violet");
		syntaxHighlight(tabs.updateArray()[0], "private", "violet");
		syntaxHighlight(tabs.updateArray()[0], "public", "violet");
		syntaxHighlight(tabs.updateArray()[0], "true", "violet");
		syntaxHighlight(tabs.updateArray()[0], "false", "violet");
		syntaxHighlight(tabs.updateArray()[0], "override", "violet");
		syntaxHighlight(tabs.updateArray()[0], "protected", "violet");
		syntaxHighlight(tabs.updateArray()[0], "main", "teal");
		syntaxHighlight(tabs.updateArray()[0], "new", "red");
		syntaxHighlight(tabs.updateArray()[0], "if", "red");
		syntaxHighlight(tabs.updateArray()[0], "else", "red");
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
		syntaxHighlight(tabs.updateArray()[0], "(", "yellow");
		syntaxHighlight(tabs.updateArray()[0], ")", "yellow");
		//syntaxHighlight(tabs.updateArray()[0], "[]", "red");
		syntaxHighlight(tabs.updateArray()[0], "[", "yellow");
		syntaxHighlight(tabs.updateArray()[0], "]", "yellow");
		syntaxHighlight(tabs.updateArray()[0], "[]", "yellow");
		syntaxHighlight(tabs.updateArray()[0], "()", "yellow");
		syntaxHighlight(tabs.updateArray()[0], "~", "yellow");
		//syntaxHighlight(tabs.updateArray()[0], "{", "red"); error, probably tcl special character
		//syntaxHighlight(tabs.updateArray()[0], "}", "yellow");
		//syntaxHighlight(tabs.updateArray()[0], '"', "indigo"); lots of problems
		syntaxHighlight(tabs.updateArray()[0], ",", "yellow");
		syntaxHighlight(tabs.updateArray()[0], "=", "yellow");
		syntaxHighlight(tabs.updateArray()[0], ".", "yellow");
		syntaxHighlight(tabs.updateArray()[0], "&", "yellow");
		syntaxHighlight(tabs.updateArray()[0], ":", "yellow");
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
		syntaxHighlight(tabs.updateArray()[0], "else if", "red");
		syntaxHighlight(tabs.updateArray()[0], "while", "violet");
		syntaxHighlight(tabs.updateArray()[0], "for", "violet");
		syntaxHighlight(tabs.updateArray()[0], "break", "violet");
		syntaxHighlight(tabs.updateArray()[0], "continue", "violet");
		syntaxHighlight(tabs.updateArray()[0], "writeln", "teal");
		syntaxHighlight(tabs.updateArray()[0], "length", "red");
		syntaxHighlight(tabs.updateArray()[0], "mainWindow", "orange");
		//syntaxHighlight(tabs.updateArray()[0], "//", "green"); dont work
		//syntaxHighlight(tabs.updateArray()[0], "/", "green"); dont work
		//syntaxHighlight(tabs.updateArray()[0], ";", "red"); error, probably tcl special character

		// go over it again line by line and remove tags within comments and apply comment tags
		// find "//" from that index till endline apply comment tag
		writeln("lines: " ~ tabs.updateArray()[0].numberOfLines());
		tabs.updateArray()[0].insertText(tabs.updateArray()[0].numberOfLines(), "it works!", "");

	}

	// deletes the pattern then replaces it with the tagged version
	// problem with floats going from 2.6 to 19.20 the decimal gets fucked at that point
	// if i can get them to be precise to 2 decimal points it should be good, !!!possibly 3 decimal points!!!
	public void syntaxHighlight(Text textWidget, string pattern, string tags) {
		string[] patternIndexes = textWidget.findAll(pattern);
		writeln(patternIndexes);
		foreach (item; patternIndexes) {
			writeln(item);
			string[] tclGarbage = item.split('.');
			writeln(tclGarbage);
			int lineIndex = tclGarbage[0].to!int;
			writeln(lineIndex);
			int charIndex = tclGarbage[1].to!int ;
			writeln(charIndex);
			string startIndex = lineIndex.to!string ~ "." ~ charIndex.to!string;
			int endIndex = charIndex.to!int + pattern.length.to!int;
			string stopIndex = lineIndex.to!string ~ "." ~ endIndex.to!string;
					
			writeln(item);
			writeln(startIndex.to!string);
			writeln(stopIndex.to!string);
			textWidget.addTag(tags, item, stopIndex.to!string);
		/*
		string[] patternIndexes = textWidget.findAll(pattern);
		writeln(patternIndexes);
		foreach (item; patternIndexes) {
			float startIndex;
			float stopIndex;
			if (item.find(".").length == 2) {
				if (item.find(".") == ".0") {
					writeln("inner if");
					startIndex = item.to!float;
					stopIndex = startIndex + pattern.length / 100.0;
				} else {
					writeln("inner else");
					writeln(item);
					string[] tclGarbage = item.split('.');
					writeln(tclGarbage);
					float lineIndex = tclGarbage[0].to!float;
					writeln(lineIndex);
					float charIndex = tclGarbage[1].to!float / 100.0;
					writeln(charIndex);
					float properIndex = lineIndex + charIndex;
					if (pattern == "private") {
						startIndex = item.to!float;
						stopIndex = startIndex + pattern.length / 10.0;
					} else {
						startIndex = properIndex; // from here make it 68.09 instead of 68.9
						stopIndex = properIndex + pattern.length / 100.0;
					}
					writeln(startIndex);
					writeln(stopIndex);
				}
			} else {
				writeln("outer else");
				startIndex = item.to!float;
				stopIndex = startIndex + pattern.length / 100.0;
			}
			writeln(item);
			writeln(startIndex.to!string);
			writeln(stopIndex.to!string);
			textWidget.addTag(tags, item, stopIndex.to!string);
			*/
			//textWidget.deleteText(item, stopIndex.to!string); // 2.0 and 2.6
			//textWidget.insertText(item, pattern, tags);
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