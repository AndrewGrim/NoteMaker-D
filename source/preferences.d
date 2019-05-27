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
	NoteBook noteBook;
	Text[] textWidgetArray;

    // constructor
    this(Window root, Text textMain, Scale opacitySlider, string preferencesFile,
		 NoteBook noteBook, Text[] textWidgetArray) {

        this.root = root;
        this.textMain = textMain;
        this.opacitySlider = opacitySlider;
        this.preferencesFile = preferencesFile;
		this.noteBook = noteBook;
		this.textWidgetArray = textWidgetArray;

        // sets up the command for the scale widget
        opacitySlider.setCommand(&this.changeOpacity);
    }

    // creates the preferences window and displays its contents
    public void openPreferencesWindow(CommandArgs args, Text[] updateArray) {

        // sets up the window relative to root
		this.preferencesWindow = new Window("Preferences", false);
			preferencesWindow.setWindowPositon(root.getXPos() + root.getXPos() / 2 - 50, root.getWidth() / 2 + 50);
            preferencesWindow.focus();            

        // the frame that holds all the widgets within the window
		this.preferencesFrame = new Frame(preferencesWindow)
			.pack(10, 10);

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

		this.savePreferences = new Button(preferencesFrame, "Save Preferences")
			.setCommand(&savePreferencesToFile)
			.pack(0, 0, GeometrySide.top, GeometryFill.x);

        // sets up the keybindings for the preferences window
        this.preferencesWindow.bind("<Escape>", &this.closePreferences); // Cancel Preferences
        this.preferencesWindow.bind("<Return>", &this.pressButton); // Clicks Button

		textWidgetArray = updateArray;
	}

    // opens the font dialog allowing you to choose the options
	public void openFontDialog(CommandArgs args) {
		auto dialog = new FontDialog("Choose a font")
			.setCommand(delegate(CommandArgs args){
			for (int index; index < textWidgetArray.length; index++) {
			textWidgetArray[index].setFont(args.dialog.font);
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

		for (int index; index < textWidgetArray.length; index++) {
			textWidgetArray[index].setForegroundColor(dialog.getResult);
		}

		savePreferencesToFile(args);
	}

    // opens the color dialog allowing you to choose the background color
	public void openBackgroundColorDialog(CommandArgs args) {
		auto dialog = new ColorDialog("Choose a color")
			.setInitialColor(Color.white)
			.show();

		for (int index; index < textWidgetArray.length; index++) {
			textWidgetArray[index].setBackgroundColor(dialog.getResult);
		}

		savePreferencesToFile(args);
	}

    // opens the color dialog allowing you to choose the insert color
	public void openInsertColorDialog(CommandArgs args) {
		auto dialog = new ColorDialog("Choose a color")
			.setInitialColor(Color.black)
			.show();

		for (int index; index < textWidgetArray.length; index++) {
			textWidgetArray[index].setInsertColor(dialog.getResult);
		}

		savePreferencesToFile(args);
	}

    // saves the current widget values to the "preferences.txt" file
    public void savePreferencesToFile(CommandArgs args) {
        auto f = File(preferencesFile, "w");
        f.write(textMain.getFont() ~ "\n");
        f.write(textMain.getForegroundColor() ~ "\n");
        f.write(textMain.getBackgroundColor() ~ "\n");
        f.write(textMain.getInsertColor() ~ "\n");
        f.write(opacitySlider.getValue());
        f.close();  

		for (int index; index < textWidgetArray.length; index++) {
			textWidgetArray[index].setFont(textMain.getFont());
			textWidgetArray[index].setForegroundColor(textMain.getForegroundColor());
			textWidgetArray[index].setBackgroundColor(textMain.getBackgroundColor());
			textWidgetArray[index].setInsertColor(textMain.getInsertColor());
		}

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