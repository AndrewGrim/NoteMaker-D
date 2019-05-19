module preferences;

import tkd.tkdapplication;      
import std.stdio;         
import std.file;

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

    // constructor
    this(Window root, Text textMain, Scale opacitySlider, string preferencesFile) {
        this.root = root;
        this.textMain = textMain;
        this.opacitySlider = opacitySlider;
        this.preferencesFile = preferencesFile;

        // sets up the command for the scale widget
        opacitySlider.setCommand(&this.changeOpacity);
    }

    // creates the preferences window and displays its
    public void openPreferencesWindow(CommandArgs args) {

        // sets up the window relative to root
		this.preferencesWindow = new Window("Preferences", false)
			.setGeometry(250, 125, root.getXPos() + root.getXPos() / 2 - 50, root.getWidth() / 2 + 50)
            .focus();            

        // the frame that holds all the widgets within the window
		this.preferencesFrame = new Frame(preferencesWindow)
			.pack();

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

        // creates the button for saving the preferences
		this.savePreferences = new Button(preferencesFrame, "Save")
            .setCommand(&savePreferencesToFile)
            .pack(0, 0, GeometrySide.left, GeometryFill.x);

        // creates the button for closing the preferences window
		this.cancelPreferences = new Button(preferencesFrame, "Cancel")
            .setCommand(&closePreferences)
            .pack(0, 0, GeometrySide.right, GeometryFill.x);

        // sets up the keybindings for the preferences window
        this.preferencesWindow.bind("<Control-s>", &this.savePreferencesToFile); // Save Preferences
        this.preferencesWindow.bind("<Escape>", &this.closePreferences); // Cancel Preferences
        this.preferencesWindow.bind("<Return>", &this.pressButton); // Clicks Button
	}

    // opens the font dialog allowing you to choose the options
	public void openFontDialog(CommandArgs args) {
		auto dialog = new FontDialog("Choose a font")
			.setCommand(delegate(CommandArgs args){
				this.textMain.setFont(args.dialog.font);
			})
			.show();

            closePreferences(args);
	}

    // opens the color dialog allowing you to choose the foreground color
	public void openForegroundColorDialog(CommandArgs args) {
		auto dialog = new ColorDialog("Choose a color")
			.setInitialColor(Color.black)
			.show();

		this.textMain.setForegroundColor(dialog.getResult());

        closePreferences(args);
	}

    // opens the color dialog allowing you to choose the background color
	public void openBackgroundColorDialog(CommandArgs args) {
		auto dialog = new ColorDialog("Choose a color")
			.setInitialColor(Color.white)
			.show();

		this.textMain.setBackgroundColor(dialog.getResult());

        closePreferences(args);
	}

    // opens the color dialog allowing you to choose the insert color
	public void openInsertColorDialog(CommandArgs args) {
		auto dialog = new ColorDialog("Choose a color")
			.setInitialColor(Color.black)
			.show();

		this.textMain.setInsertColor(dialog.getResult());

        closePreferences(args);
	}

    // saves the current widget values to the "preferences.txt" fiel
    public void savePreferencesToFile(CommandArgs args) {
        auto f = File(preferencesFile, "w");
        f.write(textMain.getFont() ~ "\n");
        f.write(textMain.getForegroundColor() ~ "\n");
        f.write(textMain.getBackgroundColor() ~ "\n");
        f.write(textMain.getInsertColor() ~ "\n");
        f.write(opacitySlider.getValue());
        f.close();  

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
        } else if (savePreferences.inState(["focus"])) {
            savePreferencesToFile(args);
        } else if (cancelPreferences.inState(["focus"])) {
            closePreferences(args);
        }
    }

    // changes the opacity based off of the scale widget's value
    public void changeOpacity(CommandArgs args) {
        root.setOpacity(this.opacitySlider.getValue());
        writeln("alpha: ", this.opacitySlider.getValue());
    }
}