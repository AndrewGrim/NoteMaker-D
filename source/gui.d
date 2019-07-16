module gui;

import tkd.tkdapplication;      
import std.stdio;         
import std.conv;
import std.file;
import std.string;
import std.exception;

import readpreferences;

// gui setup
class Gui {

	// variables
	Window root;
	Text textMain;
	Text[] textWidgetArray;
	Text terminalOutput;
	Entry terminalInput;
	readpreferences.Preferences preferences;

	// constructor
	this(Window root) {
		this.root = root;
	}

	// creates the main pane for the "noteBook"
	public Frame createMainPane() {
		
		// the main frame that gets returned to be used by the "noteBook"
		auto frameMain = new Frame();

				// the frame containing all the widgets
				auto container = new Frame(frameMain)
					.pack(0, 0, GeometrySide.top, GeometryFill.both, AnchorPosition.center, true);

					// tries to read options from the "preferences.txt" file, if it fails the file is created with default values
					try {
						preferences = readpreferences.readPreferencesFile();

					} catch (ErrnoException error) {
						writeln("error: ", error);
						// when the preferences files is not found it is created with default values
						preferences.preferencesFileExists = false;

						auto f = File(preferences.preferencesFile, "w");
						f.write("[FONT]\nArial 12\n",
						"[FOREGROUND COLOR]\n#ffffff\n",
						"[BACKGROUND COLOR]\n#000000\n",
						"[INSERT CURSOR COLOR]\n#00ff00\n",
						"[OPACITY / TRANSPARENCY]\n1.0\n",
						"[SELECTION FOREGROUND COLOR]\n#000000\n",
						"[SELECTION BACKGROUND COLOR]\n#b8baba\n",
						"[SAVE ON MODIFIED]\nfalse");
						f.close();

						writeln("Failed to read preferences file! Preferences file created!");
					}

					// creates the "textMain" widget and sets the options if the "preferences.txt" file exists
					this.textMain = new Text(container)
						.focus()
						.setWidth(1) // to prevent scrollbars from dissappearing
						.setHeight(1)
						.setWrapMode("none")
						.pack(0, 0, GeometrySide.left, GeometryFill.both, AnchorPosition.center, true);
						// tries to read in the values from file
						try {
							textMain
								.setFont(preferences.font)
								.setForegroundColor(preferences.foreground)
								.setBackgroundColor(preferences.background)
								.setInsertColor(preferences.insert)
								.setSelectionForegroundColor(preferences.selectionForeground)
								.setSelectionBackgroundColor(preferences.selectionBackground);
						} catch (ErrnoException error) {
							writeln("Custom text widget options couldn't be set!");
						}
					
					// adds the text widget to the array to keep track of it
					textWidgetArray ~= textMain;

					// creates the vertical "yscroll" widget for use with "textMain"
					auto yscroll = new YScrollBar(container)
						.attachWidget(textMain)
						.pack(0, 0, GeometrySide.right, GeometryFill.both, AnchorPosition.center, false);

					textMain.attachYScrollBar(yscroll);

					auto xscroll = new XScrollBar(frameMain)
						.attachWidget(textMain)
						.pack(0, 0, GeometrySide.bottom, GeometryFill.both, AnchorPosition.center, false);

					textMain.attachXScrollBar(xscroll);
					root.generateEvent("<<TextWidgetCreated>>");

		return frameMain;
	}

	// creates the main pane for the "noteBook"
	public Frame createTerminalPane() {
		
		// the main frame that gets returned to be used by the "noteBook"
		auto frameTerminal = new Frame();

				// the frame containing all the widgets
				auto containerTerminalOutput = new Frame(frameTerminal)
					.pack(0, 0, GeometrySide.top, GeometryFill.both, AnchorPosition.center, true);

					this.terminalOutput = new Text(containerTerminalOutput)
						.setFont(textMain.getFont())
						.setForegroundColor(textMain.getForegroundColor())
						.setBackgroundColor(textMain.getBackgroundColor())
						.setInsertColor(textMain.getInsertColor())
						.setSelectionBackgroundColor(textMain.getSelectionBackgroundColor())
						.setSelectionForegroundColor(textMain.getSelectionForegroundColor())
						//.setWrapMode("none") // default is word
						.setWidth(1) // to prevent scrollbars from dissappearing
						.setHeight(1)
						.pack(0, 0, GeometrySide.left, GeometryFill.both, AnchorPosition.center, true);
					

					auto yscrollTerminal = new YScrollBar(containerTerminalOutput)
						.attachWidget(terminalOutput)
						.pack(0, 0, GeometrySide.right, GeometryFill.both, AnchorPosition.center, false);

					this.terminalOutput.attachYScrollBar(yscrollTerminal);

				auto containerTerminalInput = new Frame(frameTerminal)
					.pack(0, 0, GeometrySide.bottom, GeometryFill.both, AnchorPosition.center, false);

					this.terminalInput = new Entry(containerTerminalInput)
						.pack(0, 0, GeometrySide.top, GeometryFill.both, AnchorPosition.center, false);

		return frameTerminal;
	}
}