module main;

import tkd.tkdapplication;   
import std.stdio;
import std.conv;
import std.string;    
import std.algorithm;
import std.process;
import preferenceswindow, inputoutput, gui, tabs, syntaxhighlighting, indentation; // source imports

// NoteMaker application.
class Application : TkdApplication {

	// variables
	Window root;
	Gui gui;
	PreferencesWindow pref;
	InputOutput io;
	Tabs tabs;
	Syntax syntax;
	NoteBook noteBook;
	bool applicationInitialization = true;
	bool secondWidget = false;
	int sideStatus;
	Frame main;
	Frame side;
	NoteBook noteBookTerminal;
	PanedWindow sideBySide;
	Text lineNumbersTextWidget;
	string openingPairKey;
	string closingPairKey;
	string[] selectionRange;
	string selectionText;

	// initialize user interface
	override public void initInterface() {

		// sets up root
		this.root = mainWindow()
			.setDefaultIcon([new EmbeddedPng!("NoteMaker.png")])
			.setTitle("Note Maker")
			.setGeometry(1200, 800, 250, 50);

		root.bind("<<TextWidgetCreated>>", &addTextBindings);

		// makes the code in "gui.d" usable in "main.d"
		gui = new Gui(root);

		this.sideBySide = new PanedWindow(root, "horizontal");

		this.main = new Frame(sideBySide);
			noteBook = new NoteBook(main);
				auto mainPane = gui.createMainPane();
			auto noteBookLines = new NoteBook(main);
				auto linesPane = new Frame();

			// creates the text widget containing the line numbers
			this.lineNumbersTextWidget = new Text(linesPane)
				.configTag("alignCenter", "-justify center")
				.pack(0, 0, GeometrySide.left, GeometryFill.y, AnchorPosition.north, false);

			noteBookLines
				.addTab("#", linesPane)
				.pack(0, 0, GeometrySide.left, GeometryFill.both, AnchorPosition.center, false);

			noteBook
				.addTab("Main File", mainPane)
				.pack(0, 0, GeometrySide.top, GeometryFill.both, AnchorPosition.center, true);

		this.side = new Frame(sideBySide);
			noteBookTerminal = new NoteBook(side);
				auto terminalPane = gui.createTerminalPane();
			noteBookTerminal
				.addTab("Terminal", terminalPane)
				.pack(0, 0, GeometrySide.top, GeometryFill.both, AnchorPosition.center, true);
		
		this.sideBySide
			.addPane(main)
			.setPaneWeight(0, 20)
			.pack(0, 0, GeometrySide.top, GeometryFill.both, AnchorPosition.center, true);

		applicationInitialization = false;
		secondWidget = true;

		// makes the code in other files usable in "main.d"
		io = new InputOutput(root, lineNumbersTextWidget);
		pref = new PreferencesWindow(root, gui.textMain, gui.preferences, gui.textWidgetArray, gui.terminalOutput, lineNumbersTextWidget);
		tabs = new Tabs(root, noteBook, noteBookTerminal, gui.textWidgetArray);
		syntax = new Syntax();

		// create the menu bar at the top
		auto menuBar = new MenuBar(root);

		// sets up the "File" menu
		auto fileMenu = new Menu(menuBar, "File", 0)
			.addEntry("Open File...", &openFile, "Ctrl+F")
			.addEntry("Open File In A New Tab", &openFileInNewTab, "Ctrl+Alt+F")
			.addEntry("Save", &saveFile, "Ctrl+S")
			.addEntry("Save As", &saveFileAs, "Ctrl+Alt+S")
			.addSeparator()
			.addEntry("New Tab", &tabs.createNewTab, "Ctrl+T")
			.addEntry("Close Tab", &tabs.closeTab, "Ctrl+W")
			.addEntry("Next Tab", &tabs.nextTab, "Ctrl+1")
			.addEntry("Previous Tab", &tabs.previousTab, "Ctrl+2") 
			.addEntry("Reopen Closed Tab", &tabs.reopenClosedTab, "Ctrl+3")
			.addSeparator()
			.addEntry("SideBySide", &sideBySideMode, "Ctrl+B")
			.addSeparator()
			.addEntry("About", &about) // TODO shortcut
			.addSeparator()
			.addEntry("Quit", &exitApplication, "Ctrl+Q");

		auto editMenu = new Menu(menuBar, "Edit", 0)
			.addEntry("Preferences", &openPreferences, "Ctrl+P")
			.addSeparator()
			.addEntry("Syntax Highlight", &manualHighlight, "Ctrl+L");
		
		// sets opacity on application boot
		root.setOpacity(gui.preferences.opacity);

		// sets up the keybindings
		root.bind("<Control-f>", &openFile); // Open
		root.bind("<Control-Alt-f>", &openFileInNewTab); // Open File In A New Tab
		root.bind("<Control-s>", &saveFile); // Save
		root.bind("<Control-Alt-s>", &saveFileAs); // Save As
		root.bind("<Control-t>", &tabs.createNewTab); // New Tab // FIXME move the line up?? might need to change the keybind to something that doesnt interfer
		root.bind("<Control-w>", &tabs.closeTab); // Close Tab
		root.bind("<Control-KeyPress-1>", &tabs.nextTab); // Next Tab
		root.bind("<Control-KeyPress-2>", &tabs.previousTab); // Previous Tab
		root.bind("<Control-KeyPress-3>", &tabs.reopenClosedTab); // Reopen Closed Tab
		root.bind("<Control-p>", &openPreferences); // Preferences
		root.bind("<Control-l>", &manualHighlight); // Syntax Highlight
		root.bind("<Control-b>", &sideBySideMode); // Enable/Disable SideBySide Mode
		//root.bind("<Control-h>", &help); //help control-h, as either a message or a help file // TODO help or about
		root.bind("<Control-q>", &exitApplication); // Quit

		// virtual event functions
		//root.bind("<<Modified>>", &saveOnModified); // FIXME renable once other shit is finished
		root.bind("<<ResetTitle>>", &resetTitle);
		noteBook.bind("<<NotebookTabChanged>>", &lineNumbersUpdate);
		root.bind("<<Modified>>", &updateLines);

		gui.terminalInput.bind("<Return>", &terminalCommand);

		// FIXME gets triggered when changing tabs since the the yview is different than it was on the last tab, maybe use Associative Array
		double lastYViewPos = tabs.getTextWidgetArray()[noteBook.getCurrentTabId].getYView()[0];
		root.setIdleCommand(delegate(CommandArgs args){
			if (tabs.getTextWidgetArray()[noteBook.getCurrentTabId].getYView()[0] != lastYViewPos) {
				lastYViewPos = tabs.getTextWidgetArray()[noteBook.getCurrentTabId].getYView()[0];
				lineNumbersTextWidget.setYView(lastYViewPos);
			}
			this.mainWindow.setIdleCommand(args.callback, 10);
		});

		// checks if the preferences file exists if false creates one and tells you about it
		if (!gui.preferences.preferencesFileExists) {
			auto dialog = new MessageDialog(this.root, "Preferences File")
				.setDetailMessage("Preferences file could not be found and has been created!")
				.show();
		}
	}

	// if selection IS empty adds the closingPairKey and moves the cursor back into pair of symbols, so you can start typing function arguments for example
	// if selection is NOT empty calls undo to counteract the symbol replacing the selection, then adds the pair of symbols around the selection range
	public void insertPair(CommandArgs args) { 
		Text textWidget = tabs.getTextWidgetArray()[noteBook.getCurrentTabId()];
		if (!selectionRange.empty) {
			string start = selectionRange[0];
			string end = selectionRange[1].split(".")[0] ~ "." ~ ((selectionRange[1].split(".")[1].to!int) + 1).to!string;
			textWidget.undo();
			textWidget.insertText(start, openingPairKey);
			textWidget.insertText(end, closingPairKey);
			//root.after(&manualHighlight, 1); this can be kept if you do the line below
			// TODO implement highlight for only a specified number of lines to not make the application halt for a second
		} else {
			string cursorPos = textWidget.getInsertCursorIndex();
			int line = cursorPos.split(".")[0].to!int;
			int character = cursorPos.split(".")[1].to!int;
			character += 2;
			textWidget.insertText(line, character, closingPairKey);
			textWidget.moveInsertCursorBack(line, character);
		}
	}

	public void delay(CommandArgs args) {
		if (args.uniqueData == "<KeyPress-bracketleft>") {
			openingPairKey = "[";
			closingPairKey = "]";
			root.after(&insertPair, 1);
		} else if (args.uniqueData == "<KeyPress-braceleft>") {
			openingPairKey = "{";
			closingPairKey = "}";
			root.after(&insertPair, 1);
		} else if (args.uniqueData == "<KeyPress-parenleft>") {
			openingPairKey = "(";
			closingPairKey = ")";
			root.after(&insertPair, 1);
		} else if (args.uniqueData == "<KeyPress-less>") {
			openingPairKey = "<";
			closingPairKey = ">";
			root.after(&insertPair, 1);
		} else if (args.uniqueData == "<KeyPress-quotedbl>") {
			openingPairKey = "\"";
			closingPairKey = "\"";
			root.after(&insertPair, 1);
		} else if (args.uniqueData == "<KeyPress-quoteleft>") {
			openingPairKey = "`";
			closingPairKey = "`";
			root.after(&insertPair, 1);
		} else if (args.uniqueData == "<KeyPress-quoteright>") {
			openingPairKey = "'";
			closingPairKey = "'";
			root.after(&insertPair, 1);
		}
		selectionRange = tabs.getTextWidgetArray()[noteBook.getCurrentTabId()].getTagRanges("sel");
	}

	public void updateLines(CommandArgs args) {
		// TODO create three methods that do stuff on <<modified>> event determined by args callback or something
		// one for save on modified
		// two for updating lines
		// three for checking wheter file has been modified but not saved
		foreach (textWidget; tabs.getTextWidgetArray()) {
			textWidget.setModified(false);
		}
		lineNumbersUpdate(args); // TODO check for change in number of lines and only then call the function
	}

	public void lineNumbersUpdate(CommandArgs arg) {
		string numOfLines = tabs.getTextWidgetArray()[noteBook.getCurrentTabId()].getNumberOfLines().split(".")[0];

		string lineNumbers;
		if (numOfLines == "0") {
			lineNumbers = "1";
		} else {
			for (int i = 1; i < numOfLines.to!int; i++) {
				if (i == (numOfLines.to!int - 1)) {
					lineNumbers ~= i.to!string;
				} else {
					lineNumbers ~= i.to!string ~ "\n";
				}
			}
		}
		lineNumbers ~= "\n" ~ "###";

		lineNumbersTextWidget.setReadOnly(false);
		if ((numOfLines.length).to!int < 3) {
			lineNumbersTextWidget.setWidth(3);
		} else {
			lineNumbersTextWidget.setWidth((numOfLines.length).to!int);
		}
		lineNumbersTextWidget.setFont(tabs.getTextWidgetArray()[noteBook.getCurrentTabId()].getFont());
		lineNumbersTextWidget.setForegroundColor(tabs.getTextWidgetArray()[noteBook.getCurrentTabId()].getForegroundColor());
		lineNumbersTextWidget.setBackgroundColor(tabs.getTextWidgetArray()[noteBook.getCurrentTabId()].getBackgroundColor());
		lineNumbersTextWidget.clear();
		lineNumbersTextWidget.appendText(lineNumbers, "alignCenter");
		lineNumbersTextWidget.setReadOnly();
		lineNumbersTextWidget.setYView(tabs.getTextWidgetArray()[noteBook.getCurrentTabId].getYView()[0]);
	}

	// basic terminal implementation
	// not really suitable for debugging because the main program waits until the process is finished
	// though it does keep the output its not realtime, only afterwards
	public void terminalCommand(CommandArgs args) {
		string command = gui.terminalInput.getValue();
		gui.terminalInput.setValue("");
		auto shell = executeShell(command,
									null,
									Config.none,
									size_t.max,
									null,
									"C:/WINDOWS/System32/WindowsPowerShell/v1.0/powershell.exe"); // TODO setting for default shell
		string separator = "\n=======================\n\n";

		if (shell.output != "") {
			gui.terminalOutput.setReadOnly(false);
			gui.terminalOutput.appendText(shell.output ~ separator);
			gui.terminalOutput.setReadOnly();
		}

		gui.terminalOutput.seeText("end");
	}

	public void about(CommandArgs args) {
		browse("https://google.com");  // TODO point to github
	}

	// resets the title to the name of the program
	public void changeTitle(CommandArgs args) {
		root.setTitle("Note Maker");
	}

	// resets the title after 3seconds once a <<ResetTitle>> event is detected
	public void resetTitle(CommandArgs args) {
		root.after(&changeTitle, 3000);
	}

	// opens and closes the side by side mode
	public void sideBySideMode(CommandArgs args) {
		if (sideStatus % 2 == 0 || sideStatus == 0) {
			sideBySide
				.addPane(side)
				.setPaneWeight(1, 9);
				gui.terminalInput.focus();
		} else {
			sideBySide.removePane(1);
			tabs.getTextWidgetArray[noteBook.getCurrentTabId()].focus();
		}
		sideStatus++;
	}

	// adds the indentation bindings to all the text widgets so that they can be actually used
	public void addTextBindings(CommandArgs args) {
		gui.textMain.bind("<Control-`>", &indent);
		gui.textMain.bind("<Shift-Tab>", &unindent);
		gui.textMain.bind("<KeyPress-bracketleft>", &delay);
		gui.textMain.bind("<KeyPress-braceleft>", &delay);
		gui.textMain.bind("<KeyPress-parenleft>", &delay);
		gui.textMain.bind("<KeyPress-less>", &delay);
		gui.textMain.bind("<KeyPress-quotedbl>", &delay);
		gui.textMain.bind("<KeyPress-quoteleft>", &delay);
		gui.textMain.bind("<KeyPress-quoteright>", &delay);
		if (!applicationInitialization) {
			foreach (widget; tabs.getTextWidgetArray()) {
				widget.bind("<Control-`>", &indent);
				widget.bind("<Shift-Tab>", &unindent);
				widget.bind("<KeyPress-bracketleft>", &delay);
				widget.bind("<KeyPress-braceleft>", &delay);
				widget.bind("<KeyPress-parenleft>", &delay);
				widget.bind("<KeyPress-less>", &delay);
				widget.bind("<KeyPress-quotedbl>", &delay);
				widget.bind("<KeyPress-quoteleft>", &delay);
				widget.bind("<KeyPress-quoteright>", &delay);
			}
		}
	}

	// indents the text, works with both single lines and selection
	public void indent(CommandArgs args) {
		indentation.Indentation.indent(noteBook, tabs.getTextWidgetArray());
	}

	// unindents the text, works with both single lines and selection
	public void unindent(CommandArgs args) {
		indentation.Indentation.unindent(noteBook, tabs.getTextWidgetArray());
	}

	// opens a file according to the dialog
	public void openFile(CommandArgs args) {
		io.openOpenFileDialog(args, noteBook, tabs.getTextWidgetArray());
		automaticHighlight(args);
		syntax.setHighlightOnLoad(true);
	}

	// opens a file in a new tab
	public void openFileInNewTab(CommandArgs args) {
		tabs.createNewTab(args);
		io.openOpenFileDialog(args, noteBook, tabs.getTextWidgetArray());
		automaticHighlight(args);
		syntax.setHighlightOnLoad(true);
	}

	// saves the file sans dialog using the path from opening or saving the file previously
	// opens the save dialog if there isnt a path associated with the file
	public void saveFile(CommandArgs args) { 
		io.saveFile(args, noteBook, tabs.getTextWidgetArray());
		automaticHighlight(args);
	}

	// saves a file according to the dialog
	public void saveFileAs(CommandArgs args) {
		io.openSaveFileDialog(args, noteBook, tabs.getTextWidgetArray());
		automaticHighlight(args);
	}

	// saves the file every time the text widget's contents are modified if the checkbutton is checked
	// except for: 
	// when a file is being opened and the syntax is being highlighted or
	// when a file is being opend
	public void saveOnModified(CommandArgs args) {
		if (pref.getSaveOnModified()) {
			foreach (textWidget; tabs.getTextWidgetArray()) {
				if (textWidget.getModified()) { 
					if (!io.getOpeningFile && syntax.highlightOnLoad) {
						io.setOpeningFile(false); // WTF this seems dumb
						syntax.setHighlightOnLoad(false);
					} else if (!io.getOpeningFile) {
						io.setOpeningFile(false); // WTF this seems dumb
					} else {
						io.saveFile(args, noteBook, tabs.getTextWidgetArray());
						// FIXME save on modified only works once you load the file doesnt work when creating a new file
					}

					textWidget.setModified(false);
				} 
			}
		}
	}

	// opens the preferences window
	public void openPreferences(CommandArgs args) {	
		pref.openPreferencesWindow(args, tabs.getTextWidgetArray());
	}

	// automatically highlights the defined syntax
	public void automaticHighlight(CommandArgs args) {
		syntax.highlight(args, noteBook, tabs.getTextWidgetArray());
	}

	// manually highlights the defined syntax bypassing the supported extensions check, results will vary
	public void manualHighlight(CommandArgs args) {
		syntax.highlight(args, noteBook, tabs.getTextWidgetArray(), true);
	}

	// quits the application
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