module gui;

import tkd.tkdapplication;      
import std.stdio;         
import std.conv;
import std.file;
import std.string;
import std.exception;

import readpreferences;

/// Gui setup on initialization.
class Gui {

	/// Variable used to access the main window.
	Window root;

	/// Variable for the original Text widget. Used for preferences etc.
	Text textMain;

	/// Array used to store all the Text widgets for future use.
	Text[] textWidgetArray;

	/// Text widget used for displaying terminal output.
	Text terminalOutput;

	/// Entry box used for issuing terminall commands.
	Entry terminalInput;

	/// Struct used to hold preferences.
	readpreferences.Preferences preferences;

	/// Constructor.
	this(Window root) {
		this.root = root;
	}

	/// Creates the main pane for the "noteBook". Return frameMain.
	public Frame createMainPane() {
		
		/// The main frame that gets returned to be used by the "noteBook".
		Frame frameMain = new Frame();

				/// The frame containing all the other widgets.
				Frame container = new Frame(frameMain)
					.pack(0, 0, GeometrySide.top, GeometryFill.both, AnchorPosition.center, true);

					/// Tries to read options from the "preferences.txt" file, if it fails the file is created with default values.
					try {
						preferences = readpreferences.readPreferencesFile();

					} catch (ErrnoException error) {
						writeln("error: ", error);

						// when the preferences files is not found it is created with default values
						preferences.preferencesFileExists = false;

						File f = File(preferences.preferencesFile, "w");
						f.write("[FONT]\nArial 12\n",
						"[FOREGROUND COLOR]\n#ffffff\n",
						"[BACKGROUND COLOR]\n#000000\n",
						"[INSERT CURSOR COLOR]\n#00ff00\n",
						"[OPACITY / TRANSPARENCY]\n1.0\n",
						"[SELECTION FOREGROUND COLOR]\n#000000\n",
						"[SELECTION BACKGROUND COLOR]\n#b8baba\n",
						"[SAVE ON MODIFIED]\nfalse\n",
						"[SHELL]\ndefault\n",
						"[SYNTAX THEME]\ndefault\n",
						"[WIDTH]\n800\n",
						"[HEIGHT]\n600");
						f.close();

						writeln("Failed to read preferences file! Preferences file created!");
					}

					this.textMain = new Text(container)
						.focus()
						.setWidth(1) // to prevent scrollbars from dissappearing
						.setHeight(1) // to prevent scrollbars from dissappearing
						.setWrapMode("none")
						.pack(0, 0, GeometrySide.left, GeometryFill.both, AnchorPosition.center, true);
						// Tries to read in the values from file.
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
					
					// Adds the text widget to the array to keep track of it.
					textWidgetArray ~= textMain;

					YScrollBar yscroll = new YScrollBar(container)
						.attachWidget(textMain)
						.pack(0, 0, GeometrySide.right, GeometryFill.both, AnchorPosition.center, false);

					textMain.attachYScrollBar(yscroll);

					XScrollBar xscroll = new XScrollBar(frameMain)
						.attachWidget(textMain)
						.pack(0, 0, GeometrySide.bottom, GeometryFill.both, AnchorPosition.center, false);

					textMain.attachXScrollBar(xscroll);

					// Fires of the event "TextWidgetCreated" so that keybindings will apply to the widget.
					root.generateEvent("<<TextWidgetCreated>>");

		return frameMain;
	}

	/// Creates the terminal pane for the "noteBookTerminal". Returns frameTerminal.
	public Frame createTerminalPane() {
		
		// The main frame that gets returned to be used by the "noteBookTerminal".
		Frame frameTerminal = new Frame();

				// The frame containing all the other widgets.
				Frame containerTerminalOutput = new Frame(frameTerminal)
					.pack(0, 0, GeometrySide.top, GeometryFill.both, AnchorPosition.center, true);

					this.terminalOutput = new Text(containerTerminalOutput)
						.setFont(textMain.getFont())
						.setForegroundColor(textMain.getForegroundColor())
						.setBackgroundColor(textMain.getBackgroundColor())
						.setInsertColor(textMain.getInsertColor())
						.setSelectionBackgroundColor(textMain.getSelectionBackgroundColor())
						.setSelectionForegroundColor(textMain.getSelectionForegroundColor())
						.setWidth(1) // to prevent scrollbars from dissappearing
						.setHeight(1) // to prevent scrollbars from dissappearing
						.setReadOnly()
						.pack(0, 0, GeometrySide.left, GeometryFill.both, AnchorPosition.center, true);
					

					YScrollBar yscrollTerminal = new YScrollBar(containerTerminalOutput)
						.attachWidget(terminalOutput)
						.pack(0, 0, GeometrySide.right, GeometryFill.both, AnchorPosition.center, false);

					terminalOutput.attachYScrollBar(yscrollTerminal);

				Frame containerTerminalInput = new Frame(frameTerminal)
					.pack(0, 0, GeometrySide.bottom, GeometryFill.both, AnchorPosition.center, false);

					this.terminalInput = new Entry(containerTerminalInput)
						.pack(0, 0, GeometrySide.top, GeometryFill.both, AnchorPosition.center, false);

		return frameTerminal;
	}
}