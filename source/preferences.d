module preferences;

import tkd.tkdapplication;      
import std.stdio;         
import std.conv;
import std.file;
import std.string;
import std.exception;
import main;

class Preferences {
        
    public Window preferencesWindow;
    public Frame preferencesFrame;
    public Button changeFont;
    public Button changeForegroundColor;
    public Button changeBackgroundColor;
    public Button savePreferences;
    public Button cancelPreferences;
    Window root;
    Text textMain;
    Scale opacitySlider;
    string preferencesFile;

    this(Window root, Text textMain, Scale opacitySlider, string preferencesFile) {
        this.root = root;
        this.textMain = textMain;
        this.opacitySlider = opacitySlider;
        this.preferencesFile = preferencesFile;
    }

    public void openPreferencesWindow(CommandArgs args) {

		this.preferencesWindow = new Window("Preferences", false)
			.setGeometry(180, 100, root.getXPos() + root.getXPos() / 2, 400)
            .focus();            

		this.preferencesFrame = new Frame(preferencesWindow)
			.pack();

		this.changeFont = new Button(preferencesFrame, "Change Font")
			.setCommand(&openFontDialog)
			.pack(0, 0, GeometrySide.top, GeometryFill.x);

		this.changeForegroundColor = new Button(preferencesFrame, "Change Foreground Color")
			.setCommand(&openForegroundColorDialog)
			.pack(0, 0, GeometrySide.top, GeometryFill.x);

		this.changeBackgroundColor = new Button(preferencesFrame, "Change Background Color")
			.setCommand(&openBackgroundColorDialog)
			.pack(0, 0, GeometrySide.top, GeometryFill.x);

		this.savePreferences = new Button(preferencesFrame, "Save")
            //.setCommand(&savePreferencesToFile)
            .pack(0, 0, GeometrySide.left, GeometryFill.x);

		this.cancelPreferences = new Button(preferencesFrame, "Cancel")
            .setCommand(&closePreferences)
            .pack(0, 0, GeometrySide.right, GeometryFill.x);

        this.preferencesWindow.bind("<Control-s>", &this.savePreferencesToFile); // Save Preferences
        this.preferencesWindow.bind("<Escape>", &this.closePreferences); // Cancel Preferences
        this.preferencesWindow.bind("<Return>", &this.pressButton); // Clicks Button
	}

	public void openFontDialog(CommandArgs args) {
		auto dialog = new FontDialog("Choose a font")
			.setCommand(delegate(CommandArgs args){
				this.textMain.setFont(args.dialog.font);
			})
			.show();

            closePreferences(args);
	}

	public void openForegroundColorDialog(CommandArgs args) {
		auto dialog = new ColorDialog("Choose a color")
			.setInitialColor(Color.black)
			.show();

		this.textMain.setForegroundColor(dialog.getResult());
		this.textMain.setInsertColor(dialog.getResult());

        closePreferences(args);
	}

	public void openBackgroundColorDialog(CommandArgs args) {
		auto dialog = new ColorDialog("Choose a color")
			.setInitialColor(Color.white)
			.show();

		this.textMain.setBackgroundColor(dialog.getResult());

        closePreferences(args);
	}

    public void savePreferencesToFile(CommandArgs args) {
        auto f = File(preferencesFile, "w");
        f.write(textMain.getFont() ~ "\n");
        f.write(textMain.getForegroundColor() ~ "\n");
        f.write(textMain.getBackgroundColor() ~ "\n");
        f.write(opacitySlider.getValue());
        f.close();  
        writeln("Preferences file saved!");
    }

    public void closePreferences(CommandArgs args) {
        this.preferencesWindow.destroy();

        writeln("Preferences window closed!");
    }

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
}

