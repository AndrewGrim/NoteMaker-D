module main;

import tkd.tkdapplication;   
import std.stdio;
import std.conv;
import std.string;    
import std.algorithm;
import preferences, inputoutput, gui, tabs, syntaxhighlighting, indentation; // source imports

// NoteMaker application.
class Application : TkdApplication {

	// variables
	Window root;
	Gui gui;
	Preferences pref;
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

	// initialize user interface
	override public void initInterface() {

		// sets up root
		this.root = mainWindow()
			.setDefaultIcon([new EmbeddedPng!("NoteMaker.png")])
			.setGeometry(1200, 800, 250, 50);

		root.bind("<<TextWidgetCreated>>", &addIndenationBindings);

		// makes the code in "gui.d" usable in "main.d"
		gui = new Gui(root);

		this.sideBySide = new PanedWindow(root, "horizontal");

		this.main = new Frame(sideBySide);
			noteBook = new NoteBook(main);
				auto mainPane = gui.createMainPane();

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
		io = new InputOutput(root);
		pref = new Preferences(root, gui.textMain, gui.opacitySlider, gui.preferencesFile, gui.textWidgetArray, gui.textWidgetArraySide, gui.saveOnModified);
		tabs = new Tabs(root, noteBook, noteBookSide, gui.textWidgetArray, gui.textWidgetArraySide, gui.frameWidgetArray, gui.frameWidgetArraySide);
		syntax = new Syntax(gui.appDir);

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

		// runs every 3 seconds: resets the title 
		this.root.setIdleCommand(delegate(CommandArgs args) {
			root.setTitle("Note Maker");
			root.setIdleCommand(args.callback, 3000);
		});

		// sets opacity on application boot
		root.setOpacity(gui.opacitySlider.getValue());

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
		// help control-h, as either a message or a help file!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
		root.bind("<Control-q>", &exitApplication); // Quit

		// virtual event functions
		root.bind("<<Modified>>", &saveOnModified);

		// checks if the preferences file exists if false creates one and tells you about it
		if (!gui.preferencesFileExists) {
			auto dialog = new MessageDialog(this.root, "Preferences File")
				.setDetailMessage("Preferences file could not be found and has been created!")
				.show();
		}
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
							io.setOpeningFile(false);
							syntax.setHighlightOnLoad(false);
						} else if (!io.getOpeningFile) {
							io.setOpeningFile(false);
						} else {
							io.saveFile(args, noteBook, tabs.getTextWidgetArray());
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