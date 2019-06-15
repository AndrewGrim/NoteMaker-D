module preferences;

import tkd.tkdapplication;      
import std.stdio;         
import std.file;
import std.conv;

// preferences window
class Preferences {
		
	// variables
	Window root;
	Text textMain;
	Scale opacitySlider;
	string preferencesFile;
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
	bool saveOnModified;


	// constructor
	this(Window root, Text textMain, Scale opacitySlider, string preferencesFile,
		Text[] textWidgetArray, Text[] textWidgetArraySide, bool saveOnModified) {

		this.root = root;
		this.textMain = textMain;
		this.opacitySlider = opacitySlider;
		this.preferencesFile = preferencesFile;
		this.textWidgetArray = textWidgetArray;
		this.textWidgetArraySide = textWidgetArraySide;
		this.saveOnModified = saveOnModified;

		// sets up the command for the scale widget
		opacitySlider.setCommand(&this.changeOpacity);
	}

	// creates the preferences window and displays its contents
	public void openPreferencesWindow(CommandArgs args, Text[] updateArray, Text[] updateArraySide) {

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
					saveOnModified = true;
				} else {
					saveOnModified = false;
				}
			})
			.pack(0, 0, GeometrySide.top, GeometryFill.x);
			if (saveOnModified) {
				setSaveOnModified.check();
			}

		this.savePreferences = new Button(preferencesFrame, "Save Preferences")
			.setCommand(&savePreferencesToFile)
			.pack(0, 0, GeometrySide.top, GeometryFill.x);

		// sets up the keybindings for the preferences window
		this.preferencesWindow.bind("<Escape>", &this.closePreferences); // Cancel Preferences
		this.preferencesWindow.bind("<Return>", &this.pressButton); // Clicks Button

		textWidgetArray = updateArray;
		textWidgetArraySide = updateArraySide;
	}

	public bool getSaveOnModified() {
		return saveOnModified;
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

		savePreferencesToFile(args);
	}

	// sets the text widget options to the ones chosen in preferences
	// seems redundant!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
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
	}

	// saves the current widget values to the "preferences.txt" file
	public void savePreferencesToFile(CommandArgs args) {
		auto f = File(preferencesFile, "w");
		f.write(textMain.getFont() ~ "\n");
		f.write(textMain.getForegroundColor() ~ "\n");
		f.write(textMain.getBackgroundColor() ~ "\n");
		f.write(textMain.getInsertColor() ~ "\n");
		f.write(opacitySlider.getValue().to!string ~ "\n");
		f.write(textMain.getSelectionForegroundColor() ~ "\n");
		f.write(textMain.getSelectionBackgroundColor() ~ "\n");
		f.write(saveOnModified);
		f.close();  

		applyPreferencesToWidgets();

		writeln("Preferences saved!");
		root.setTitle("Preferences saved!");

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