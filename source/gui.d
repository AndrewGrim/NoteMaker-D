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
	Scale opacitySlider;
	Text[] textWidgetArray;
	Text[] textWidgetArraySide;
	Text textSide;
	Frame[] frameWidgetArray;
	Frame[] frameWidgetArraySide;
	readpreferences.Preferences preferences;

	// constructor
	this(Window root) {
		this.root = root;
	}

	// creates the main pane for the "noteBook"
	public Frame createMainPane() {
		
		// the main frame that gets returned to be used by the "noteBook"
		auto frameMain = new Frame();

		frameWidgetArray ~= frameMain;

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

					this.textMain.attachYScrollBar(yscroll);
					root.generateEvent("<<TextWidgetCreated>>");

		// creates the scale "opacitySlider" for changing the opacity/alpha setting
		this.opacitySlider = new Scale()
			.setFromValue(0.2)
			.setToValue(1.0)
			.pack(0, 0, GeometrySide.bottom, GeometryFill.x, AnchorPosition.center, false);
			// tries to read values from file
			try {
				opacitySlider.setValue(preferences.opacity);
			} catch (ErrnoException error) {
				writeln("Custom opacity couldn't be set!");
			} catch (ConvException convError) {
				writeln("Couldn't convert opacity string to float!");
			}

		return frameMain;
	}

	// creates the main pane for the "noteBook"
	public Frame createSidePane() {
		
		// the main frame that gets returned to be used by the "noteBook"
		auto frameSide = new Frame();

		frameWidgetArraySide ~= frameSide;

				// the frame containing all the widgets
				auto containerSide = new Frame(frameSide)
					.pack(0, 0, GeometrySide.top, GeometryFill.both, AnchorPosition.center, true);


					this.textSide = new Text(containerSide)
						.setFont(textMain.getFont())
						.setForegroundColor(textMain.getForegroundColor())
						.setBackgroundColor(textMain.getBackgroundColor())
						.setInsertColor(textMain.getInsertColor())
						.setSelectionBackgroundColor(textMain.getSelectionBackgroundColor())
						.setSelectionForegroundColor(textMain.getSelectionForegroundColor())
						.pack(0, 0, GeometrySide.left, GeometryFill.both, AnchorPosition.center, true);
					
					// adds the text widget to the array to keep track of it
					textWidgetArraySide ~= textSide;

					// creates the vertical "yscroll" widget for use with "textMain"
					auto yscrollSide = new YScrollBar(containerSide)
						.attachWidget(textSide)
						.pack(0, 0, GeometrySide.right, GeometryFill.both, AnchorPosition.center, false);

					this.textSide.attachYScrollBar(yscrollSide);
					//root.generateEvent("<<TextWidgetCreated>>");//!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!

		return frameSide;
	}
}