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
	bool firstTextWidget = true;

	// initialize user interface
	override public void initInterface() {

		// sets up root
		this.root = mainWindow()
			.setDefaultIcon([new EmbeddedPng!("NoteMaker.png")])
			.setGeometry(1200, 800, 250, 50);

		root.bind("<<TextWidgetCreated>>", &addIndenationBindings);

		// makes the code in "gui.d" usable in "main.d"
		gui = new Gui(root);

		// creates the noteBook and the default tab
		noteBook = new NoteBook();
		auto mainPane = gui.createMainPane();

		firstTextWidget = false;

		// shows the noteBook adds the default tab to it
		noteBook
			.addTab("Main File", mainPane)
			.pack(0, 0, GeometrySide.top, GeometryFill.both, AnchorPosition.center, true);

		// makes the code in other files usable in "main.d"
		io = new InputOutput(root, gui.textMain, noteBook);
		pref = new Preferences(root, gui.textMain, gui.opacitySlider, gui.preferencesFile, noteBook, gui.textWidgetArray);
		tabs = new Tabs(root, noteBook, gui.textWidgetArray);
		syntax = new Syntax(gui.appDir);

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
			.addEntry("Syntax Highlight", &manualHighlight, "Ctrl+L")
			.addSeparator()
			.addEntry("Quit", &exitApplication, "Ctrl+Q");

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
		root.bind("<Control-l>", &manualHighlight); // Syntax Highlight
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

	// adds the indentation bindings to all the text widgets so that they can be actually used
	public void addIndenationBindings(CommandArgs args) {
		gui.textMain.bind("<Control-`>", &indent);
		gui.textMain.bind("<Shift-Tab>", &unindent);
		if (!firstTextWidget) {
			foreach (widget; tabs.updateArray()) {
				widget.bind("<Control-`>", &indent);
				widget.bind("<Shift-Tab>", &unindent);
			}
		}
	}

	// indents the text, works with both single lines and selection
	public void indent(CommandArgs args) {
		indentation.Indentation.indent(noteBook, tabs.updateArray());
	}

	// unindents the text, works with both single lines and selection
	public void unindent(CommandArgs args) {
		indentation.Indentation.unindent(noteBook, tabs.updateArray());
	}

	// opens a file according to the dialog
	public void openFile(CommandArgs args) {
		io.openOpenFileDialog(args, tabs.updateArray());
		automaticHighlight(args);
	}

	// saves the file sans dialog using the path from opening or saving the file previously
	public void saveFile(CommandArgs args) {
		io.saveFile(args, tabs.updateArray());
		automaticHighlight(args);
	}

	// saves a file according to the dialog
	public void saveFileAs(CommandArgs args) {
		io.openSaveFileDialog(args, tabs.updateArray());
		automaticHighlight(args);
	}

	// saves the file every time the text widget's contents are modified
	public void saveOnModified(CommandArgs args) {
		// put code in IO
		//change to proper syntax and add option to save as you go??
		// maybe create a custom switch that uses the scale widget as base??? or just checkbox or radio
		/*
		if (tabs.updateArray()[0].getModified()) { 
			auto f = File("c:/users/grim/desktop/testingModified.txt", "w");
			f.write(tabs.updateArray()[0].getText());
			f.close();

			tabs.updateArray()[0].setModified(false);
		}
		*/
	}

	// opens the preferences window
	public void openPreferences(CommandArgs args) {
		pref.openPreferencesWindow(args, tabs.updateArray());
	}

	// automatically highlights the defined syntax
	public void automaticHighlight(CommandArgs args) {
		syntax.highlight(args, noteBook, tabs.updateArray());
	}

	// manually highlights the defined syntax bypassing the supported extensions check, results will vary
	public void manualHighlight(CommandArgs args) {
		syntax.highlight(args, noteBook, tabs.updateArray(), true);
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