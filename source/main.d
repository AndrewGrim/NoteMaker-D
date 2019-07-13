module main;

import tkd.tkdapplication;   
import std.stdio;
import std.conv;
import std.string;    
import std.algorithm;
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
	NoteBook noteBookSide;
	PanedWindow sideBySide;
	Text lineNumbersTextWidget;

	// initialize user interface
	override public void initInterface() {

		// sets up root
		this.root = mainWindow()
			.setDefaultIcon([new EmbeddedPng!("NoteMaker.png")])
			.setTitle("Note Maker")
			.setGeometry(1200, 800, 250, 50);

		root.bind("<<TextWidgetCreated>>", &addIndenationBindings);

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
			noteBookSide = new NoteBook(side);
				auto sidePane = gui.createSidePane();
			noteBookSide
				.addTab("Side File", sidePane)
				.pack(0, 0, GeometrySide.top, GeometryFill.both, AnchorPosition.center, true);
		
		this.sideBySide
			.addPane(main)
			.setPaneWeight(0, 20)
			.pack(0, 0, GeometrySide.top, GeometryFill.both, AnchorPosition.center, true);

		applicationInitialization = false;
		secondWidget = true;

		// makes the code in other files usable in "main.d"
		io = new InputOutput(root, lineNumbersTextWidget);
		pref = new PreferencesWindow(root, gui.textMain, gui.preferences, gui.textWidgetArray, gui.textWidgetArraySide, lineNumbersTextWidget);
		tabs = new Tabs(root, noteBook, noteBookSide, gui.textWidgetArray, gui.textWidgetArraySide, gui.frameWidgetArray, gui.frameWidgetArraySide);
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
		root.bind("<Control-t>", &tabs.createNewTab); // New Tab
		root.bind("<Control-w>", &tabs.closeTab); // Close Tab
		root.bind("<Control-KeyPress-1>", &tabs.nextTab); // Next Tab
		root.bind("<Control-KeyPress-2>", &tabs.previousTab); // Previous Tab
		root.bind("<Control-KeyPress-3>", &tabs.reopenClosedTab); // Reopen Closed Tab
		root.bind("<Control-p>", &openPreferences); // Preferences
		root.bind("<Control-l>", &manualHighlight); // Syntax Highlight
		root.bind("<Control-b>", &sideBySideMode); // Enable/Disable SideBySide Mode
		// help control-h, as either a message or a help file // TODO help or about
		root.bind("<Control-q>", &exitApplication); // Quit

		// virtual event functions
		//root.bind("<<Modified>>", &saveOnModified); // FIXME renable once other shit is finished
		root.bind("<<ResetTitle>>", &resetTitle);
		noteBook.bind("<<NotebookTabChanged>>", &lineNumbersUpdate);
		root.bind("<<Modified>>", &updateLines);

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
				.setPaneWeight(1, 20);
		} else {
			sideBySide.removePane(1);
		}
		sideStatus++;
	}

	// adds the indentation bindings to all the text widgets so that they can be actually used
	public void addIndenationBindings(CommandArgs args) {
		gui.textMain.bind("<Control-`>", &indent);
		gui.textMain.bind("<Shift-Tab>", &unindent);
		if (!applicationInitialization) {
			writeln("if");
			writeln(tabs.getTextWidgetArray());
			foreach (widget; tabs.getTextWidgetArray()) {
				widget.bind("<Control-`>", &indent);
				widget.bind("<Shift-Tab>", &unindent);
			}
		}
	}

	// indents the text, works with both single lines and selection
	public void indent(CommandArgs args) {
		if (tabs.checkCurrentNoteBook == "side") {
			indentation.Indentation.indent(noteBookSide, tabs.getTextWidgetArraySide());
		} else {
			indentation.Indentation.indent(noteBook, tabs.getTextWidgetArray());
		}
	}

	// unindents the text, works with both single lines and selection
	public void unindent(CommandArgs args) {
		if (tabs.checkCurrentNoteBook == "side") {
			indentation.Indentation.unindent(noteBookSide, tabs.getTextWidgetArraySide());
		} else {
			indentation.Indentation.unindent(noteBook, tabs.getTextWidgetArray());
		}
	}

	// opens a file according to the dialog
	public void openFile(CommandArgs args) {
		if (tabs.checkCurrentNoteBook == "side") {
			io.openOpenFileDialog(args, noteBookSide, tabs.getTextWidgetArraySide());
			automaticHighlight(args);
			syntax.setHighlightOnLoad(true);
		} else {
			io.openOpenFileDialog(args, noteBook, tabs.getTextWidgetArray());
			automaticHighlight(args);
			syntax.setHighlightOnLoad(true);
		}
	}

	// opens a file in a new tab
	public void openFileInNewTab(CommandArgs args) {
		tabs.createNewTab(args);
		if (tabs.checkCurrentNoteBook == "side") {
			io.openOpenFileDialog(args, noteBookSide, tabs.getTextWidgetArraySide());
			automaticHighlight(args);
			syntax.setHighlightOnLoad(true);
		} else {
			io.openOpenFileDialog(args, noteBook, tabs.getTextWidgetArray());
			automaticHighlight(args);
			syntax.setHighlightOnLoad(true);
		}
	}

	// saves the file sans dialog using the path from opening or saving the file previously
	// opens the save dialog if there isnt a path associated with the file
	public void saveFile(CommandArgs args) { 
		if (tabs.checkCurrentNoteBook == "side") {
			io.saveFile(args, noteBookSide, tabs.getTextWidgetArraySide());
			automaticHighlight(args);
		} else {
			io.saveFile(args, noteBook, tabs.getTextWidgetArray());
			automaticHighlight(args);
		}
	}

	// saves a file according to the dialog
	public void saveFileAs(CommandArgs args) {
		if (tabs.checkCurrentNoteBook == "side") {
			io.openSaveFileDialog(args, noteBookSide, tabs.getTextWidgetArraySide());
			automaticHighlight(args);
		} else {
			io.openSaveFileDialog(args, noteBook, tabs.getTextWidgetArray());
			automaticHighlight(args);
		}
	}

	// saves the file every time the text widget's contents are modified if the checkbutton is checked
	// except for: 
	// when a file is being opened and the syntax is being highlighted or
	// when a file is being opend
	public void saveOnModified(CommandArgs args) {
		if (tabs.checkCurrentNoteBook == "side") {
			if (pref.getSaveOnModified()) {
				foreach (textWidget; tabs.getTextWidgetArraySide()) {
					if (textWidget.getModified()) { 
						if (!io.getOpeningFile && syntax.highlightOnLoad) {
							io.setOpeningFile(false);
							syntax.setHighlightOnLoad(false);
						} else if (!io.getOpeningFile) {
							io.setOpeningFile(false);
						} else {
							io.saveFile(args, noteBookSide, tabs.getTextWidgetArraySide());
						}

						textWidget.setModified(false);
					} 
				}
			}
		} else {
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
	}

	// opens the preferences window
	public void openPreferences(CommandArgs args) {	
		pref.openPreferencesWindow(args, tabs.getTextWidgetArray(), tabs.getTextWidgetArraySide());
	}

	// automatically highlights the defined syntax
	public void automaticHighlight(CommandArgs args) {
		if (tabs.checkCurrentNoteBook == "side") {
			syntax.highlight(args, noteBookSide, tabs.getTextWidgetArraySide());
		} else {
			syntax.highlight(args, noteBook, tabs.getTextWidgetArray());
		}
	}

	// manually highlights the defined syntax bypassing the supported extensions check, results will vary
	public void manualHighlight(CommandArgs args) {
		if (tabs.checkCurrentNoteBook == "side") {
			syntax.highlight(args, noteBookSide, tabs.getTextWidgetArraySide(), true);
		} else {
			syntax.highlight(args, noteBook, tabs.getTextWidgetArray(), true);
		}
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