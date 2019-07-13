module preferenceswindow;

import tkd.tkdapplication;      
import std.stdio;         
import std.file;
import std.conv;
import std.exception;

import readpreferences;

// preferences window
class PreferencesWindow {
		
	// variables
	Window root;
	Text textMain;
	Scale opacitySlider;
	readpreferences.Preferences preferences;
	Window preferencesWindow;
	Frame preferencesFrame;
	Button changeFont;
	Button changeForegroundColor;
	Button changeBackgroundColor;
	Button changeInsertColor;
	Button savePreferences;
	Button cancelPreferences;
	Button changeSelectionForegroundColor;
	Button changeSelectionBackgroundColor;
	Text[] textWidgetArray;
	Text[] textWidgetArraySide;
	CheckButton setSaveOnModified;
	Text lineNumbersTextWidget;


	// constructor
	this(Window root, Text textMain, readpreferences.Preferences preferences,
		Text[] textWidgetArray, Text[] textWidgetArraySide, Text lineNumbersTextWidget) {

		this.root = root;
		this.textMain = textMain;
		this.preferences = preferences;
		this.textWidgetArray = textWidgetArray;
		this.textWidgetArraySide = textWidgetArraySide;
		this.lineNumbersTextWidget = lineNumbersTextWidget;
	}

	// creates the preferences window and displays its contents
	public void openPreferencesWindow(CommandArgs args, Text[] getTextWidgetArray, Text[] getTextWidgetArraySide) {

		// sets up the window relative to root
		this.preferencesWindow = new Window("Preferences", false);
			preferencesWindow.setWindowPositon(root.getWidth() / 2 + root.getXPos() - 120, root.getHeight() / 2 + root.getYPos() - 140);
			preferencesWindow.focus();            

		// the frame that holds all the widgets within the window
		this.preferencesFrame = new Frame(preferencesWindow)
			.pack(40, 0);

		// creates the button for changing the font
		this.changeFont = new Button(preferencesFrame, "Change Font")
			.setCommand(&openFontDialog)
			.pack(0, 0, GeometrySide.top, GeometryFill.x);

		// creates the button for changing the foreground color
		this.changeForegroundColor = new Button(preferencesFrame, "Change Foreground Color")
			.setCommand(&openForegroundColorDialog)
			.pack(0, 0, GeometrySide.top, GeometryFill.x);

		// creates the button for changing the background color
		this.changeBackgroundColor = new Button(preferencesFrame, "Change Background Color")
			.setCommand(&openBackgroundColorDialog)
			.pack(0, 0, GeometrySide.top, GeometryFill.x);

		// creates the button for changing the insert color
		this.changeInsertColor = new Button(preferencesFrame, "Change Insert Color")
			.setCommand(&openInsertColorDialog)
			.pack(0, 0, GeometrySide.top, GeometryFill.x);

		// creates the button for changing the selection foreground color
		this.changeSelectionForegroundColor = new Button(preferencesFrame, "Change Selection Foreground Color")
			.setCommand(&openSelectionForegroundColorDialog)
			.pack(0, 0, GeometrySide.top, GeometryFill.x);

		// creates the button for changing the selection background color
		this.changeSelectionBackgroundColor = new Button(preferencesFrame, "Change Selection Background Color")
			.setCommand(&openSelectionBackgroundColorDialog)
			.pack(0, 0, GeometrySide.top, GeometryFill.x);

		this.setSaveOnModified = new CheckButton(preferencesFrame, "Set Save On Modified")
			.setCommand(delegate(CommandArgs args) {
				if (setSaveOnModified.isChecked()) {
					preferences.saveOnModified = true;
				} else {
					preferences.saveOnModified = false;
				}
			})
			.pack(0, 0, GeometrySide.top, GeometryFill.x);
			if (preferences.saveOnModified) {
				setSaveOnModified.check();
			}

		// creates the scale "opacitySlider" for changing the opacity/alpha setting
		this.opacitySlider = new Scale(preferencesFrame)
			.setFromValue(0.2)
			.setToValue(1.0)
			.pack(0, 0, GeometrySide.top, GeometryFill.x, AnchorPosition.center, false);
			opacitySlider.setCommand(&this.changeOpacity);
			// tries to read values from file
			try {
				opacitySlider.setValue(preferences.opacity);
			} catch (ErrnoException error) {
				writeln("Custom opacity couldn't be set!");
			} catch (ConvException convError) {
				writeln("Couldn't convert opacity string to float!");
			}

		this.savePreferences = new Button(preferencesFrame, "Save Preferences")
			.setCommand(&savePreferencesToFile)
			.pack(0, 0, GeometrySide.top, GeometryFill.x);

		// sets up the keybindings for the preferences window
		this.preferencesWindow.bind("<Escape>", &this.closePreferences); // Cancel Preferences
		this.preferencesWindow.bind("<Return>", &this.pressButton); // Clicks Button

		textWidgetArray = getTextWidgetArray;
		textWidgetArraySide = getTextWidgetArraySide;
	}

	public bool getSaveOnModified() {
		return preferences.saveOnModified;
	}

	// opens the font dialog allowing you to choose the options
	public void openFontDialog(CommandArgs args) {
		auto dialog = new FontDialog("Choose a font")
			.setCommand(delegate(CommandArgs args){
				foreach (widget; textWidgetArray) {
					widget.setFont(args.dialog.font);
				}

				foreach (widget; textWidgetArraySide) {
					widget.setFont(args.dialog.font);
				}

				lineNumbersTextWidget.setFont(args.dialog.font);
			})
			.show();

			savePreferencesToFile(args);
	}

	// opens the color dialog allowing you to choose the foreground color
	public void openForegroundColorDialog(CommandArgs args) {
		auto dialog = new ColorDialog("Choose a color")
			.setInitialColor(Color.black)
			.show();

		foreach (widget; textWidgetArray) {
			widget.setForegroundColor(dialog.getResult);
		}

		foreach (widget; textWidgetArraySide) {
			widget.setForegroundColor(dialog.getResult);
		}

		lineNumbersTextWidget.setForegroundColor(dialog.getResult);

		savePreferencesToFile(args);
	}

	// opens the color dialog allowing you to choose the background color
	public void openBackgroundColorDialog(CommandArgs args) {
		auto dialog = new ColorDialog("Choose a color")
			.setInitialColor(Color.white)
			.show();

		foreach (widget; textWidgetArray) {
			widget.setBackgroundColor(dialog.getResult);
		}

		foreach (widget; textWidgetArraySide) {
			widget.setBackgroundColor(dialog.getResult);
		}

		lineNumbersTextWidget.setBackgroundColor(dialog.getResult);

		savePreferencesToFile(args);
	}

	// opens the color dialog allowing you to choose the insert color
	public void openInsertColorDialog(CommandArgs args) {
		auto dialog = new ColorDialog("Choose a color")
			.setInitialColor(Color.black)
			.show();

		foreach (widget; textWidgetArray) {
			widget.setInsertColor(dialog.getResult);
		}

		foreach (widget; textWidgetArraySide) {
			widget.setInsertColor(dialog.getResult);
		}

		lineNumbersTextWidget.setInsertColor(dialog.getResult);

		savePreferencesToFile(args);
	}

	// opens the color dialog allowing you to choose the selection foreground color
	public void openSelectionForegroundColorDialog(CommandArgs args) {
		auto dialog = new ColorDialog("Choose a color")
			.setInitialColor(Color.white)
			.show();

		foreach (widget; textWidgetArray) {
			widget.setSelectionForegroundColor(dialog.getResult);
		}

		foreach (widget; textWidgetArraySide) {
			widget.setSelectionForegroundColor(dialog.getResult);
		}

		lineNumbersTextWidget.setSelectionForegroundColor(dialog.getResult);


		savePreferencesToFile(args);
	}

	// opens the color dialog allowing you to choose the selection background color
	public void openSelectionBackgroundColorDialog(CommandArgs args) {
		auto dialog = new ColorDialog("Choose a color")
			.setInitialColor(Color.gray)
			.show();

		foreach (widget; textWidgetArray) {
			widget.setSelectionBackgroundColor(dialog.getResult);
		}

		foreach (widget; textWidgetArraySide) {
			widget.setSelectionBackgroundColor(dialog.getResult);
		}

		lineNumbersTextWidget.setSelectionBackgroundColor(dialog.getResult);

		savePreferencesToFile(args);
	}

	// sets the text widget options to the ones chosen in preferences
	// FIXME seems redundant
	public void applyPreferencesToWidgets() {
		foreach (widget; textWidgetArray) {
			widget.setFont(textMain.getFont());
			widget.setForegroundColor(textMain.getForegroundColor());
			widget.setBackgroundColor(textMain.getBackgroundColor());
			widget.setInsertColor(textMain.getInsertColor());
			widget.setSelectionForegroundColor(textMain.getSelectionForegroundColor());
			widget.setSelectionBackgroundColor(textMain.getSelectionBackgroundColor());
		}

		foreach (widget; textWidgetArraySide) {
			widget.setFont(textMain.getFont());
			widget.setForegroundColor(textMain.getForegroundColor());
			widget.setBackgroundColor(textMain.getBackgroundColor());
			widget.setInsertColor(textMain.getInsertColor());
			widget.setSelectionForegroundColor(textMain.getSelectionForegroundColor());
			widget.setSelectionBackgroundColor(textMain.getSelectionBackgroundColor());
		}

		lineNumbersTextWidget.setFont(textMain.getFont());
		lineNumbersTextWidget.setForegroundColor(textMain.getForegroundColor());
		lineNumbersTextWidget.setBackgroundColor(textMain.getBackgroundColor());
		lineNumbersTextWidget.setInsertColor(textMain.getInsertColor());
		lineNumbersTextWidget.setSelectionForegroundColor(textMain.getSelectionForegroundColor());
		lineNumbersTextWidget.setSelectionBackgroundColor(textMain.getSelectionBackgroundColor());
	}

	// saves the current widget values to the "preferences.txt" file
	public void savePreferencesToFile(CommandArgs args) {
		auto f = File(preferences.preferencesFile, "w");
		f.write("[FONT]\n" ~ textMain.getFont() ~ "\n");
		f.write("[FOREGROUND COLOR]\n" ~ textMain.getForegroundColor() ~ "\n");
		f.write("[BACKGROUND COLOR]\n" ~ textMain.getBackgroundColor() ~ "\n");
		f.write("[INSERT CURSOR COLOR]\n" ~ textMain.getInsertColor() ~ "\n");
		f.write("[OPACITY / TRANSPARENCY]\n" ~ opacitySlider.getValue().to!string ~ "\n");
		f.write("[SELECTION FOREGROUND COLOR]\n" ~ textMain.getSelectionForegroundColor() ~ "\n");
		f.write("[SELECTION BACKGROUND COLOR]\n" ~ textMain.getSelectionBackgroundColor() ~ "\n");
		f.write("[SAVE ON MODIFIED]\n" ~ preferences.saveOnModified.to!string);
		f.close();  

		applyPreferencesToWidgets();

		writeln("Preferences saved!");
		root.setTitle("Preferences saved!");
		root.generateEvent("<<ResetTitle>>");

		closePreferences(args);
	}

	// closes the preferences window
	public void closePreferences(CommandArgs args) {
		this.preferencesWindow.destroy();

		writeln("Preferences window closed!");
	}

	// allows you to use the "Return" key to push buttons within the preferences window
	// you can also use "Space" which is the default
	public void pressButton(CommandArgs args) {
		if (changeFont.inState(["focus"])) {
			openFontDialog(args);
		} else if (changeForegroundColor.inState(["focus"])) {
			openForegroundColorDialog(args);
		} else if (changeBackgroundColor.inState(["focus"])) {
			openBackgroundColorDialog(args);
		} else if (changeInsertColor.inState(["focus"])) {
			openInsertColorDialog(args);
		}
	}

	// changes the opacity based off of the scale widget's value
	public void changeOpacity(CommandArgs args) {
		root.setOpacity(this.opacitySlider.getValue());
		writeln("alpha: ", this.opacitySlider.getValue());
	}
}