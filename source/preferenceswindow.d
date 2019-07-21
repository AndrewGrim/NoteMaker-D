module preferenceswindow;

import tkd.tkdapplication;      
import std.stdio;         
import std.file;
import std.conv;
import std.exception;

import readpreferences;

/// Preferences window and associated methods.
class PreferencesWindow {
		
	/// Variable used to access the main window.
	Window root;

	/// Variable used to acces the origina Text widget. Used for preferences.
	Text textMain;

	/// Opacity slider widget used to control the transparency.
	Scale opacitySlider;

	/// Struct meant to hold the preferences read from file.
	readpreferences.Preferences preferences;

	/// The window containing all the widgets for changing the settings.
	Window preferencesWindow;

	/// The main frame used to hold the widgets within the preferences window.
	Frame preferencesFrame;

	/// Button which invokes the font dialog to change the font.
	Button changeFont;

	/// Button which opens the color dialog to the change the foreground color.
	Button changeForegroundColor;

	/// Button which opens the color dialog to the change the background color.
	Button changeBackgroundColor;

	/// Button which opens the color dialog to the change the insert cursor color.
	Button changeInsertColor;

	/// Button which saves the preferences to file and updates the struct.
	Button savePreferences;

	/// Button which opens the color dialog to the change the selection foreground color.
	Button changeSelectionForegroundColor;

	/// Button which opens the color dialog to the change the selection background color. 
	Button changeSelectionBackgroundColor;

	/// Array which holds all the Text widget except for the terminal and line numbers.
	Text[] textWidgetArray;

	/// CheckButton used to control the saveOnModified setting.
	CheckButton setSaveOnModified;

	/// The Text widget containing the line numbers.
	Text lineNumbersTextWidget;

	/// The Text widget containing the terminal output.
	Text terminalOutput;

	/// The Entry box with the shell path or the "default" setting.
	Entry shellPath;

	/// ComboBox used to pick the syntax color theme used by the application. Requires the highligh to be redone.
	ComboBox syntaxTheme;


	/// Constructor.
	this(Window root, Text textMain, readpreferences.Preferences preferences,
		Text[] textWidgetArray, Text terminalOutput, Text lineNumbersTextWidget) {

		this.root = root;
		this.textMain = textMain;
		this.preferences = preferences;
		this.textWidgetArray = textWidgetArray;
		this.terminalOutput = terminalOutput;
		this.lineNumbersTextWidget = lineNumbersTextWidget;
	}

	/// Creates the preferences window and displays its contents.
	public void openPreferencesWindow(CommandArgs args, Text[] getTextWidgetArray) { // @suppress(dscanner.suspicious.unused_parameter)

		// Sets up the window relative to root.
		this.preferencesWindow = new Window("Preferences", false);
			preferencesWindow.setWindowPositon(root.getWidth() / 2 + root.getXPos() - 120,
											   root.getHeight() / 2 + root.getYPos() - 140);

		this.preferencesFrame = new Frame(preferencesWindow)
			.pack(40, 0);

		this.changeFont = new Button(preferencesFrame, "Change Font")
			.setCommand(&openFontDialog)
			.pack(0, 0, GeometrySide.top, GeometryFill.x);

		this.changeForegroundColor = new Button(preferencesFrame, "Change Foreground Color")
			.setCommand(&openForegroundColorDialog)
			.pack(0, 0, GeometrySide.top, GeometryFill.x);

		this.changeBackgroundColor = new Button(preferencesFrame, "Change Background Color")
			.setCommand(&openBackgroundColorDialog)
			.pack(0, 0, GeometrySide.top, GeometryFill.x);

		this.changeInsertColor = new Button(preferencesFrame, "Change Insert Color")
			.setCommand(&openInsertColorDialog)
			.pack(0, 0, GeometrySide.top, GeometryFill.x);

		this.changeSelectionForegroundColor = new Button(preferencesFrame, "Change Selection Foreground Color")
			.setCommand(&openSelectionForegroundColorDialog)
			.pack(0, 0, GeometrySide.top, GeometryFill.x);

		this.changeSelectionBackgroundColor = new Button(preferencesFrame, "Change Selection Background Color")
			.setCommand(&openSelectionBackgroundColorDialog)
			.pack(0, 0, GeometrySide.top, GeometryFill.x);

		this.setSaveOnModified = new CheckButton(preferencesFrame, "Set Save On Modified")
			.setCommand(delegate(CommandArgs args) { // @suppress(dscanner.suspicious.unused_parameter)
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
		
		Label shellLabel = new Label(preferencesFrame, "Terminal Shell:");
			shellLabel.pack(0, 0, GeometrySide.top, GeometryFill.x, AnchorPosition.center, false); 

		this.shellPath = new Entry(preferencesFrame)
			.setValue(preferences.shell)
			.pack(0, 0, GeometrySide.top, GeometryFill.x, AnchorPosition.center, false);

		Label syntaxLabel = new Label(preferencesFrame, "Syntax Theme:");
			syntaxLabel.pack(0, 0, GeometrySide.top, GeometryFill.x, AnchorPosition.center, false);

		this.syntaxTheme = new ComboBox(preferencesFrame)
			.setValue(preferences.syntaxTheme)
			.setData(["Default", "Gruvbox"])
			.pack(0, 0, GeometrySide.top, GeometryFill.x, AnchorPosition.center, false);

		this.savePreferences = new Button(preferencesFrame, "Save Preferences")
			.setCommand(&savePreferencesToFile)
			.pack(0, 0, GeometrySide.top, GeometryFill.x);

		this.preferencesWindow.bind("<Escape>", &this.closePreferences); 		// Cancel Preferences.

		textWidgetArray = getTextWidgetArray; // Updates the textWidgetArray.
	}

	public bool getSaveOnModified() {
		return preferences.saveOnModified;
	}

	/// Opens the font dialog allowing you to choose the options for the font.
	public void openFontDialog(CommandArgs args) {
		FontDialog dialog = new FontDialog("Choose a font");
			dialog.setCommand(delegate(CommandArgs args){
				foreach (widget; textWidgetArray) {
					widget.setFont(args.dialog.font);
				}

				terminalOutput.setFont(args.dialog.font);
				lineNumbersTextWidget.setFont(args.dialog.font);
			})
			.show();

			savePreferencesToFile(args);
	}

	/// Opens the color dialog allowing you to choose the foreground color.
	public void openForegroundColorDialog(CommandArgs args) {
		auto dialog = new ColorDialog("Choose a color")
			.setInitialColor(Color.black)
			.show();

		foreach (widget; textWidgetArray) {
			widget.setForegroundColor(dialog.getResult);
		}

		terminalOutput.setForegroundColor(dialog.getResult);
		lineNumbersTextWidget.setForegroundColor(dialog.getResult);

		savePreferencesToFile(args);
	}

	/// Opens the color dialog allowing you to choose the background color.
	public void openBackgroundColorDialog(CommandArgs args) {
		auto dialog = new ColorDialog("Choose a color")
			.setInitialColor(Color.white)
			.show();

		foreach (widget; textWidgetArray) {
			widget.setBackgroundColor(dialog.getResult);
		}

		terminalOutput.setBackgroundColor(dialog.getResult);
		lineNumbersTextWidget.setBackgroundColor(dialog.getResult);

		savePreferencesToFile(args);
	}

	/// Opens the color dialog allowing you to choose the insert color.
	public void openInsertColorDialog(CommandArgs args) {
		auto dialog = new ColorDialog("Choose a color")
			.setInitialColor(Color.black)
			.show();

		foreach (widget; textWidgetArray) {
			widget.setInsertColor(dialog.getResult);
		}

		terminalOutput.setInsertColor(dialog.getResult);
		lineNumbersTextWidget.setInsertColor(dialog.getResult);

		savePreferencesToFile(args);
	}

	/// Opens the color dialog allowing you to choose the selection foreground color.
	public void openSelectionForegroundColorDialog(CommandArgs args) {
		auto dialog = new ColorDialog("Choose a color")
			.setInitialColor(Color.white)
			.show();

		foreach (widget; textWidgetArray) {
			widget.setSelectionForegroundColor(dialog.getResult);
		}

		terminalOutput.setSelectionForegroundColor(dialog.getResult);
		lineNumbersTextWidget.setSelectionForegroundColor(dialog.getResult);


		savePreferencesToFile(args);
	}

	/// Opens the color dialog allowing you to choose the selection background color.
	public void openSelectionBackgroundColorDialog(CommandArgs args) {
		auto dialog = new ColorDialog("Choose a color")
			.setInitialColor(Color.gray)
			.show();

		foreach (widget; textWidgetArray) {
			widget.setSelectionBackgroundColor(dialog.getResult);
		}

		terminalOutput.setSelectionBackgroundColor(dialog.getResult);
		lineNumbersTextWidget.setSelectionBackgroundColor(dialog.getResult);

		savePreferencesToFile(args);
	}

	/// Saves the current widget values to the "preferences.config" file and updates the struct.
	public void savePreferencesToFile(CommandArgs args) {
		auto f = File(preferences.preferencesFile, "w");
		f.write("[FONT]\n" ~ textMain.getFont() ~ "\n");
		f.write("[FOREGROUND COLOR]\n" ~ textMain.getForegroundColor() ~ "\n");
		f.write("[BACKGROUND COLOR]\n" ~ textMain.getBackgroundColor() ~ "\n");
		f.write("[INSERT CURSOR COLOR]\n" ~ textMain.getInsertColor() ~ "\n");
		f.write("[OPACITY / TRANSPARENCY]\n" ~ opacitySlider.getValue().to!string ~ "\n");
		f.write("[SELECTION FOREGROUND COLOR]\n" ~ textMain.getSelectionForegroundColor() ~ "\n");
		f.write("[SELECTION BACKGROUND COLOR]\n" ~ textMain.getSelectionBackgroundColor() ~ "\n");
		f.write("[SAVE ON MODIFIED]\n" ~ preferences.saveOnModified.to!string ~ "\n");
		f.write("[SHELL]\n" ~ shellPath.getValue() ~ "\n");
		f.write("[SYNTAX THEME]\n" ~ syntaxTheme.getValue() ~ "\n");
		f.write("[WIDTH]\n" ~ preferences.width.to!string ~ "\n");
		f.write("[HEIGHT]\n" ~ preferences.height.to!string);
		f.close();  

		preferences.shell = shellPath.getValue();
		preferences.syntaxTheme = syntaxTheme.getValue();
		preferences.opacity = opacitySlider.getValue();

		writeln("Preferences saved!");
		root.setTitle("Preferences saved!");
		root.generateEvent("<<ResetTitle>>");

		closePreferences(args);
	}

	/// Closes the preferences window when you press "Escape".
	public void closePreferences(CommandArgs args) { // @suppress(dscanner.suspicious.unused_parameter)
		preferencesWindow.destroy();

		writeln("Preferences window closed!");
	}

	/// Changes the opacity based off of the scale widget's value.
	public void changeOpacity(CommandArgs args) { // @suppress(dscanner.suspicious.unused_parameter)
		root.setOpacity(this.opacitySlider.getValue());
		writeln("alpha: ", this.opacitySlider.getValue());
	}
}