module main;

import tkd.tkdapplication;   
import std.stdio;
import std.conv;
import std.string;    
import std.algorithm;
import std.process;
import std.exception;
import preferenceswindow, inputoutput, gui, tabs, syntaxhighlighting, indentation; // Source imports.

/// NoteMaker application.
class Application : TkdApplication {

	/// The main window of the application.
	Window root;

	/// Variable used for accessing the Gui class.
	Gui gui;

	/// Variable used for accessing the PreferencesWindow class.
	PreferencesWindow pref;

	/// Variable used for accessing the InputOutput class.
	InputOutput io;

	/// Variable used for accessing the Tabs class.
	Tabs tabs;

	/// Variable used for accessing the Syntax class.
	Syntax syntax;

	/// The main NoteBook widget. Contains all the open files in different tabs.
	NoteBook noteBook;

	/// Variable to prevent accessing objects that don't exist yet.
	bool applicationInitialization = true;

	/// Variable to determine whether the terminal PanedWindow is visible.
	int sideStatus;

	/// The frame that contains the NoteBook with all the files, and the NoteBook with line numbers.
	Frame main;

	/// The frame that contains the NoteBook with the terminal.
	Frame side;

	/// NoteBook widget for the terminal. Uses a NoteBook instead of a standalone Text widget for symetry.
	NoteBook noteBookTerminal;

	/// The top container for everything to allow you to resize the terminal using the sash.
	PanedWindow sideBySide;

	/// Text widget containing the line numbers of the currently visible file.
	Text lineNumbersTextWidget;

	/// String containing the opening symbol from a pair of brackets, braces, quotes etc.
	string openingPairKey;

	/// String containing the closing symbol from a pair of brackets, braces, quotes etc.
	string closingPairKey;

	/// An array containing the indices for the start and end of the selected text.
	string[] selectionRange;
	
	/// Initialize user interface, instantiate the class objects etc.
	override public void initInterface() {

		// Assigns and sets up root.
		this.root = mainWindow()
			.setDefaultIcon([new EmbeddedPng!("NoteMaker.png")])
			.setTitle("Note Maker");

		// Creates virutal event that will be generated whenever a new Text widget is created. Used for assigning bindings to Text widgets.
		root.bind("<<TextWidgetCreated>>", &addTextBindings);

		// Makes the code in "gui.d" usable in "main.d"
		gui = new Gui(root);

		this.sideBySide = new PanedWindow(root, "horizontal");

		this.main = new Frame(sideBySide);
			noteBook = new NoteBook(main);
				Frame mainPane = gui.createMainPane();

			// The NoteBook widget containing the line numbers Text widget and the padding Label.
			NoteBook noteBookLines = new NoteBook(main);
				Frame linesPane = new Frame();

			// Creates the Text widget containing the line numbers.
			this.lineNumbersTextWidget = new Text(linesPane)
				.configTag("alignCenter", "-justify center")
				.pack(0, 0, GeometrySide.top, GeometryFill.both, AnchorPosition.center, true);

			// Label to make the line numbers and the text files the same size.
			Label paddingLabel = new Label(linesPane, " ");
				paddingLabel.pack(0, 0, GeometrySide.bottom, GeometryFill.both, AnchorPosition.center, false);

			noteBookLines
				.addTab("#", linesPane)
				.pack(0, 0, GeometrySide.left, GeometryFill.both, AnchorPosition.center, false);

			noteBook
				.addTab("Main File", mainPane)
				.pack(0, 0, GeometrySide.top, GeometryFill.both, AnchorPosition.center, true);

		this.side = new Frame(sideBySide);
			this.noteBookTerminal = new NoteBook(side);
				Frame terminalPane = gui.createTerminalPane();
			noteBookTerminal
				.addTab("Terminal", terminalPane)
				.pack(0, 0, GeometrySide.top, GeometryFill.both, AnchorPosition.center, true);
		
		sideBySide
			.addPane(main)
			.setPaneWeight(0, 20)
			.pack(0, 0, GeometrySide.top, GeometryFill.both, AnchorPosition.center, true);

		applicationInitialization = false;

		// Makes the code in other files usable in "main.d".
		io = new InputOutput(root, 
							lineNumbersTextWidget);

		pref = new PreferencesWindow(root, 
									 gui.textMain,
									 gui.preferences,
									 gui.textWidgetArray, 
									 gui.terminalOutput,
									 lineNumbersTextWidget);

		tabs = new Tabs(root, 
						noteBook, 
						noteBookTerminal, 
						gui.textWidgetArray);

		syntax = new Syntax();

		// Set the size of the main window to whatever the dimensions were when the program was previously closed.
		root.setGeometry(pref.preferences.width, pref.preferences.height, 250, 50);

		// Create the menu bar at the top.
		MenuBar menuBar = new MenuBar(root);

		// Sets up the "File" menu.
		const Menu fileMenu = new Menu(menuBar, "File", 0) // @suppress(dscanner.suspicious.unused_variable)
			.addEntry("Open File...", &openFile, "Ctrl+F")
			.addEntry("Open File In A New Tab", &openFileInNewTab, "Ctrl+Alt+F")
			.addEntry("Save", &saveFile, "Ctrl+S")
			.addEntry("Save As", &saveFileAs, "Ctrl+Alt+S")
			.addSeparator()
			.addEntry("New Tab", &tabs.createNewTab, "Ctrl+N")
			.addEntry("Close Tab", &tabs.closeTab, "Ctrl+W")
			.addEntry("Next Tab", &tabs.nextTab, "Ctrl+1")
			.addEntry("Previous Tab", &tabs.previousTab, "Ctrl+2") 
			.addEntry("Reopen Closed Tab", &tabs.reopenClosedTab, "Ctrl+3")
			.addSeparator()
			.addEntry("Terminal", &terminalPanel, "Ctrl+B")
			.addSeparator()
			.addEntry("About", &about)
			.addSeparator()
			.addEntry("Quit", &exitApplication, "Ctrl+Q");

		// Sets up the "Edit" menu. 
		const Menu editMenu = new Menu(menuBar, "Edit", 0) // @suppress(dscanner.suspicious.unused_variable)
			.addEntry("Preferences", &openPreferences, "Ctrl+P")
			.addSeparator()
			.addEntry("Syntax Highlight", &manualHighlight, "Ctrl+L")
			.addSeparator()
			.addEntry("Indent", &indent, "Tab")
			.addEntry("Unindent", &unindent, "Shift-Tab");
		
		// Sets opacity on application boot.
		root.setOpacity(gui.preferences.opacity);

		// Sets up the keybindings.
		root.bind("<Control-f>", &openFile); 											// Open.
		root.bind("<Control-Alt-f>", &openFileInNewTab); 								// Open File In A New Tab.
		root.bind("<Control-s>", &saveFile); 											// Save.
		root.bind("<Control-Alt-s>", &saveFileAs); 										// Save As.
		root.bind("<Control-n>", &tabs.createNewTab);									// New Tab.
		root.bind("<Control-w>", &tabs.closeTab);										// Close Tab.
		root.bind("<Control-KeyPress-1>", &tabs.nextTab);								// Next Tab.
		root.bind("<Control-KeyPress-2>", &tabs.previousTab);							// Previous Tab.
		root.bind("<Control-KeyPress-3>", &tabs.reopenClosedTab);						// Reopen Closed Tab.
		root.bind("<Control-p>", &openPreferences);										// Preferences Window.
		root.bind("<Control-l>", &manualHighlight);										// Syntax Highlight.
		root.bind("<Control-b>", &terminalPanel);										// Enable/Disable Terminal.
		root.bind("<Control-q>", &exitApplication);										// Quit.

		// Sets up virtual events.
		root.bind("<<ResetTitle>>", &resetTitle);
		noteBook.bind("<<NotebookTabChanged>>", &lineNumbersUpdate);
		root.bind("<<Modified>>", &updateLines);

		// Used for submitting command in the terminal using the "Return" key
		gui.terminalInput.bind("<Return>", &terminalCommand);

		// Check to see if the viewable area of the Text widget has changed.
		// If it did change the line numbers Text widget to the same positon.
		// Runs every 10 miliseconds.
		double lastYViewPos = tabs.getTextWidgetArray()[noteBook.getCurrentTabId].getYView()[0];
		root.setIdleCommand(delegate(CommandArgs args){
			if (tabs.getTextWidgetArray()[noteBook.getCurrentTabId].getYView()[0] != lastYViewPos) {
				lastYViewPos = tabs.getTextWidgetArray()[noteBook.getCurrentTabId].getYView()[0];
				lineNumbersTextWidget.setYView(lastYViewPos);
			}
			this.mainWindow.setIdleCommand(args.callback, 10);
		});

		// On application close get the main window dimensions and save settings to file.
		root.setProtocolCommand(WindowProtocol.deleteWindow, delegate(CommandArgs args){
			pref.preferences.width = root.getWidth();
			pref.preferences.height = root.getHeight();
			openPreferences(args);
			pref.savePreferencesToFile(args);
			exitApplication(args);
		});

		// Checks if the preferences file exists if false creates one and tells you about it.
		// FIXME doesn't work atm, must have changed when I changed the way I read the file.
		if (!gui.preferences.preferencesFileExists) {
			const MessageDialog dialog = new MessageDialog(this.root, "Preferences File") // @suppress(dscanner.suspicious.unused_variable)
				.setDetailMessage("Preferences file could not be found and has been created!")
				.show();
		}
	}

	/// Adds the matching symbol either at insert curosr or around the selection range.
	/// Only runs after the opening symbol is detected within a Text widget after 1 milisecond.
	/// This in addition to setReadOnly() is to prevent the symbol replacing the selected text.
	public void insertPair(CommandArgs args) { // @suppress(dscanner.suspicious.unused_parameter) 
		Text textWidget = tabs.getTextWidgetArray()[noteBook.getCurrentTabId()];
		selectionRange = textWidget.getTagRanges("sel");
		textWidget.setReadOnly(false);
		if (!selectionRange.empty) {
			string start = selectionRange[0];
			string end = selectionRange[1].split(".")[0] ~ "." ~ ((selectionRange[1].split(".")[1].to!int) + 1).to!string;
			textWidget.insertText(start, openingPairKey);
			textWidget.insertText(end, closingPairKey);
			textWidget.setInsertCursor(end);
		} else {
			string cursorPos = textWidget.getInsertCursorIndex();
			const int line = cursorPos.split(".")[0].to!int;
			int character = cursorPos.split(".")[1].to!int;
			character += 2;
			textWidget.insertText(line, character - 1, openingPairKey);
			textWidget.insertText(line, character, closingPairKey);
			textWidget.moveInsertCursorBack(line, character + 1);
		}
	}

	/// Runs everytime one of the the opening pair symbols is detected within a Text widget.
	/// Also handles "Tab" for use with indentation of the entire selected text.
	public void delay(CommandArgs args) {
		Text textWidget = tabs.getTextWidgetArray()[noteBook.getCurrentTabId()];
		if (args.uniqueData == "<KeyPress-bracketleft>") {
			openingPairKey = "[";
			closingPairKey = "]";
			textWidget.setReadOnly();
			root.after(&insertPair, 1);
		} else if (args.uniqueData == "<KeyPress-braceleft>") {
			openingPairKey = "{";
			closingPairKey = "}";
			textWidget.setReadOnly();
			root.after(&insertPair, 1);
		} else if (args.uniqueData == "<KeyPress-parenleft>") {
			openingPairKey = "(";
			closingPairKey = ")";
			textWidget.setReadOnly();
			root.after(&insertPair, 1);
		} else if (args.uniqueData == "<KeyPress-less>") {
			openingPairKey = "<";
			closingPairKey = ">";
			textWidget.setReadOnly();
			root.after(&insertPair, 1);
		} else if (args.uniqueData == "<KeyPress-quotedbl>") {
			openingPairKey = "\"";
			closingPairKey = "\"";
			textWidget.setReadOnly();
			root.after(&insertPair, 1);
		} else if (args.uniqueData == "<KeyPress-quoteleft>") {
			openingPairKey = "`";
			closingPairKey = "`";
			textWidget.setReadOnly();
			root.after(&insertPair, 1);
		} else if (args.uniqueData == "<KeyPress-quoteright>") {
			openingPairKey = "'";
			closingPairKey = "'";
			textWidget.setReadOnly();
			root.after(&insertPair, 1);
		} else if (args.uniqueData == "<KeyPress-Tab>") {
			textWidget.setReadOnly();
			root.after(&indent, 1);
		} else {
			writeln("unhandled key : ", args.uniqueData);
		}
	}

	/// Runs whenever the text is modified.
	/// Resets the modified flag and calls lineNumberUpdate().
	public void updateLines(CommandArgs args) {
		tabs.getTextWidgetArray()[noteBook.getCurrentTabId()].setModified(false);

		lineNumbersUpdate(args);
	}

	/// Runs whenever the tab changes and when called by updateLines().
	/// Check the number of lines in the text to set the lines correctly in the line numbers Text widget.
	/// Sets the customization options to the ones of the current Text widget.
	/// When triggered by "NotebookTabChanged" event, changes the line numbers view to match that of the text.
	public void lineNumbersUpdate(CommandArgs args) {
		Text textWidget = tabs.getTextWidgetArray()[noteBook.getCurrentTabId()];
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
		lineNumbersTextWidget.setFont(textWidget.getFont());
		lineNumbersTextWidget.setForegroundColor(textWidget.getForegroundColor());
		lineNumbersTextWidget.setBackgroundColor(textWidget.getBackgroundColor());
		lineNumbersTextWidget.clear();
		lineNumbersTextWidget.appendText(lineNumbers, "alignCenter");
		lineNumbersTextWidget.setReadOnly();
		if (args.uniqueData == "<<NotebookTabChanged>>") {
			lineNumbersTextWidget.setYView(textWidget.getYView()[0]);
		}
		
	}

	/// Basic terminal implementation.
	/// Not really suitable for debugging because the main program waits until the process is finished.
	/// You can use more than one command at a time by chaining them.
	// TODO scroll through recent terminal commands using arrows
	public void terminalCommand(CommandArgs args) { // @suppress(dscanner.suspicious.unused_parameter)
		string command = gui.terminalInput.getValue(); 
		gui.terminalInput.setValue("");
		string shellPath = pref.preferences.shell;
		
		if (shellPath.toLower == "default") {
			shellPath = userShell();
		}
		auto shell = executeShell(command,
								null,
								Config.none,
								size_t.max,
								null,
								shellPath);
		
		string separator = "\n=======================\n\n";

		if (shell.output != "") {
			gui.terminalOutput.setReadOnly(false);
			gui.terminalOutput.appendText(shell.output ~ separator);
			gui.terminalOutput.setReadOnly();
		}

		// Scrolls to the bottom of the text.
		gui.terminalOutput.seeText("end");
	}
 
	/// Launches the default browser to the projects GitHub page.
	public void about(CommandArgs args) { // @suppress(dscanner.suspicious.unused_parameter)
		browse("https://github.com/AndrewGrim/NoteMaker-D");
	}

	/// Changes the title to the name of the program.
	public void changeTitle(CommandArgs args) { // @suppress(dscanner.suspicious.unused_parameter)
		root.setTitle("Note Maker");
	}

	/// Resets the title after 1.5 seconds by calling changeTitle() once a "ResetTitle" event is detected.
	public void resetTitle(CommandArgs args) { // @suppress(dscanner.suspicious.unused_parameter)
		root.after(&changeTitle, 1500);
	}

	/// Opens and closes the terminal panel.
	public void terminalPanel(CommandArgs args) { // @suppress(dscanner.suspicious.unused_parameter)
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

	/// Adds the indentation and symbol pair bindings to all the text widgets so that they can be actually used.
	public void addTextBindings(CommandArgs args) { // @suppress(dscanner.suspicious.unused_parameter)
		gui.textMain.bind("<KeyPress-Tab>", &delay);
		gui.textMain.bind("<Shift-Tab>", &unindent);
		gui.textMain.bind("<KeyPress-bracketleft>", &delay);
		gui.textMain.bind("<KeyPress-braceleft>", &delay);
		gui.textMain.bind("<KeyPress-parenleft>", &delay);
		gui.textMain.bind("<KeyPress-less>", &delay);
		gui.textMain.bind("<KeyPress-quotedbl>", &delay);
		gui.textMain.bind("<KeyPress-quoteleft>", &delay);
		gui.textMain.bind("<KeyPress-quoteright>", &delay);
		gui.textMain.bind("<<Modified>>", &saveOnModified);
		if (!applicationInitialization) { // Passes check once the gui has been initialized.
			foreach (widget; tabs.getTextWidgetArray()) {
				widget.bind("<<Modified>>", &saveOnModified);
				widget.bind("<KeyPress-Tab>", &delay);
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

	/// Indents the text, works with both single lines and selection.
	public void indent(CommandArgs args) { // @suppress(dscanner.suspicious.unused_parameter)
		selectionRange = tabs.getTextWidgetArray()[noteBook.getCurrentTabId()].getTagRanges("sel");
		root.cancelAfter(root.after(&changeTitle, 1500)); // cancels the change title event which would cause indent to trigger again if called before the title event finished
		if (io.getOpeningFile) {
			io.setOpeningFile(false);
		}
		indentation.Indentation.indent(noteBook, tabs.getTextWidgetArray(), selectionRange);
	}

	/// Unindents the text, works with both single lines and selection.
	public void unindent(CommandArgs args) { // @suppress(dscanner.suspicious.unused_parameter)
		indentation.Indentation.unindent(noteBook, tabs.getTextWidgetArray());
	}

	/// Opens a file with the result from the dialog.
	public void openFile(CommandArgs args) { // @suppress(dscanner.suspicious.unused_parameter)
		io.openOpenFileDialog(args, noteBook, tabs.getTextWidgetArray());
		automaticHighlight(args);
		syntax.setHighlightOnLoad(true);
	}

	/// Opens a file in a new tab.
	public void openFileInNewTab(CommandArgs args) {
		tabs.createNewTab(args);
		io.openOpenFileDialog(args, noteBook, tabs.getTextWidgetArray());
		automaticHighlight(args);
		syntax.setHighlightOnLoad(true);
	}

	/// Saves the file sans dialog using the path from opening or saving the file previously.
	/// Opens the save dialog if there isn't a path associated with the file.
	public void saveFile(CommandArgs args) { 
		io.saveFile(args, noteBook, tabs.getTextWidgetArray());
		automaticHighlight(args);
	}

	/// Saves a file using the dialog.
	public void saveFileAs(CommandArgs args) {
		io.openSaveFileDialog(args, noteBook, tabs.getTextWidgetArray());
		automaticHighlight(args);
	}

	/// Saves the file every time the text widget's contents are modified if the preferences option is checked.
	/// Except for when a file is being opened.
	public void saveOnModified(CommandArgs args) {
		if (pref.getSaveOnModified()) {
			foreach (textWidget; tabs.getTextWidgetArray()) {
				if (textWidget.getModified()) { 
					if (!io.getOpeningFile && syntax.highlightOnLoad) {
						syntax.setHighlightOnLoad(false);
					} else if (!io.getOpeningFile) {
						// do nothing
					} else {
						io.saveFile(args, noteBook, tabs.getTextWidgetArray());
						// FIXME save on modified only works once you load the file
					}

					textWidget.setModified(false);
				} 
			}
		}
	}

	/// Opens the preferences window.
	public void openPreferences(CommandArgs args) {	
		pref.openPreferencesWindow(args, tabs.getTextWidgetArray());
	}

	/// Automatically highlights the defined syntax.
	/// That is when the file is being saved or loaded and the extension matches one of the supported ones.
	public void automaticHighlight(CommandArgs args) {
		syntax.highlight(args, noteBook, tabs.getTextWidgetArray(), pref.preferences.syntaxTheme, gui.terminalOutput);
		lineNumbersTextWidget.setForegroundColor(tabs.getTextWidgetArray()[noteBook.getCurrentTabId()].getForegroundColor());
		lineNumbersTextWidget.setBackgroundColor(tabs.getTextWidgetArray()[noteBook.getCurrentTabId()].getBackgroundColor());
	}

	/// Manually highlights the defined syntax bypassing the supported extensions check, results will vary.
	/// Can be used to redo the highlights after changes to file without saving or to apply the newly selected theme.
	public void manualHighlight(CommandArgs args) {
		syntax.highlight(args, noteBook, tabs.getTextWidgetArray(), pref.preferences.syntaxTheme, gui.terminalOutput, true);
		lineNumbersTextWidget.setForegroundColor(tabs.getTextWidgetArray()[noteBook.getCurrentTabId()].getForegroundColor());
		lineNumbersTextWidget.setBackgroundColor(tabs.getTextWidgetArray()[noteBook.getCurrentTabId()].getBackgroundColor());
	}

	/// Exits the application.
	public void exitApplication(CommandArgs args) { // @suppress(dscanner.suspicious.unused_parameter)
		this.exit();
		writeln("Application closed!");
	}
}

// Runs the application.
void main(string[] args) { // @suppress(dscanner.suspicious.unused_parameter)
	auto app = new Application();             
	app.run();                                  
}