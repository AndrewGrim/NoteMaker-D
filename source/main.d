module main;
import tkd.tkdapplication;      
import std.stdio;         
import std.conv;
import std.file;
import std.string;
import std.exception;

/**
 * NoteMaker application.
 */
class Application : TkdApplication {

	private Window root;
	private string fileToOpen;
    private string fileToSave;
    private Text textMain;
    private Text textSide;
    private Scale scale;
    private Window preferencesWindow;
    private string preferencesFile;
    private string[10] preferencesArray; // should probably have strings named appropriately according to the options
    private bool preferencesFileExists;
    private Button changeFont;
    private Button changeForegroundColor;
    private Button changeBackgroundColor;
    private Button savePreferences;
    private Button cancelPreferences;

    private void openOpenFileDialog(CommandArgs args) {
		
		auto openFile = new OpenFileDialog("Open a file")
			.setMultiSelection(false)
			.setDefaultExtension(".txt")
			.addFileType("{{All files} {*}}")
			.addFileType("{{Text files} {.txt}}")
			.setInitialDirectory("~")
			.setInitialFile("file.txt")
			.show();

        fileToOpen = openFile.getResult();
        writeln(fileToOpen);

        if (openFile.getResult() == "") {

            writeln("Open cancelled!");

        } else {

            auto f = File(fileToOpen, "r");
            
            string fileContent;

            while (!f.eof()) { 
                string line = chomp(f.readln()); 
                fileContent ~= line ~ "\n"; 
                }

            f.close();

            this.textMain.clear();
            this.textMain.insertText(0, 0, fileContent);

            root.setTitle("File opened: " ~ fileToOpen);
        }
	}	

    private void openSaveFileDialog(CommandArgs args) {

		auto saveFile = new SaveFileDialog()
			.setConfirmOverwrite(true)
			.setDefaultExtension(".dmo")
			.addFileType("{{All files} {*}}")
			.setInitialDirectory("~")
			.setInitialFile("note.txt")
			.show();

        fileToSave = saveFile.getResult();
        writeln(fileToSave);

        if (saveFile.getResult() == "") {

            writeln("Save cancelled!");

        } else {

            auto f = File(fileToSave, "w");

            f.write(this.textMain.getText());

            f.close();

            root.setTitle("File saved: " ~ fileToSave);
        }
	} 	

	private void openForegroundColorDialog(CommandArgs args) {
		auto dialog = new ColorDialog("Choose a color")
			.setInitialColor(Color.black)
			.show();

		this.textMain.setForegroundColor(dialog.getResult());
		this.textMain.setInsertColor(dialog.getResult());

        closePreferences(args);
	}

	private void openBackgroundColorDialog(CommandArgs args) {
		auto dialog = new ColorDialog("Choose a color")
			.setInitialColor(Color.white)
			.show();

		this.textMain.setBackgroundColor(dialog.getResult());

        closePreferences(args);
	}

	private void openFontDialog(CommandArgs args) {
		auto dialog = new FontDialog("Choose a font")
			.setCommand(delegate(CommandArgs args){
				this.textMain.setFont(args.dialog.font);
			})
			.show();

            closePreferences(args);
	}

	private void openPreferencesWindow(CommandArgs args) {

		this.preferencesWindow = new Window("Preferences", false)
			.setGeometry(180, 100, root.getXPos() + root.getXPos() / 2, 400)
            .focus();             //.setState(["focus"])

		auto preferencesFrame = new Frame(preferencesWindow)
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
            .setCommand(&savePreferencesToFile)
            .pack(0, 0, GeometrySide.left, GeometryFill.x);

		this.cancelPreferences = new Button(preferencesFrame, "Cancel")
            .setCommand(&closePreferences)
            .pack(0, 0, GeometrySide.right, GeometryFill.x);
        
        this.preferencesWindow.bind("<Control-s>", &this.savePreferencesToFile); // Save Preferences
        this.preferencesWindow.bind("<Escape>", &this.closePreferences); // Cancel Preferences
        this.preferencesWindow.bind("<Return>", &this.pressButton); // Clicks Button
	}

    private void pressButton(CommandArgs args) {
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

    private void savePreferencesToFile(CommandArgs args) {
        auto f = File(preferencesFile, "w");
        f.write(textMain.getFont() ~ "\n");
        f.write(textMain.getForegroundColor() ~ "\n");
        f.write(textMain.getBackgroundColor() ~ "\n");
        f.write(scale.getValue());
        f.close();  
        writeln("Preferences file saved!");
    }

    private void closePreferences(CommandArgs args) {
        this.preferencesWindow.destroy();

        writeln("Preferences window closed!");
    }

    private void changeOpacity(CommandArgs args) {
        root.setOpacity(this.scale.getValue());
        writeln("alpha: ", this.scale.getValue());
    }

    private Frame createMainPane() {

        auto frameMain = new Frame(root);

            auto container = new Frame(frameMain)
                .pack(10, 0, GeometrySide.top, GeometryFill.both, AnchorPosition.center, true);

                try {
                    preferencesFile = getcwd() ~ "/preferences.txt";
                    
                    auto f = File(preferencesFile, "r");

                    preferencesFileExists = true;

                    int iteration;

                    while (!f.eof()) {
                        string line = chomp(f.readln());
                        preferencesArray[iteration] = line;
                        iteration++;
                        //preferencesArray ~= line;
                    }

                } catch (ErrnoException error) {
                    preferencesFileExists = false;

                    auto f = File(preferencesFile, "w");
                    f.write("Helvetica\n#000\n#FFF\n1.0");
                    f.close();

                    writeln("Failed to read preferences file! Preferences file created!");
                }

                this.textMain = new Text(container)
                    .setHeight(5)
                    .setWidth(40)
                    .pack(0, 0, GeometrySide.left, GeometryFill.both, AnchorPosition.center, true);
                    try {
                        textMain
                            .setFont(preferencesArray[0])
                            .setForegroundColor(preferencesArray[1])
                            .setBackgroundColor(preferencesArray[2])
                            .setInsertColor(preferencesArray[1]);
                    } catch (ErrnoException error) {
                        writeln("Custom text widget options couldn't be set!");
                    }

                auto yscroll = new YScrollBar(container)
                    .attachWidget(textMain)
                    .pack(0, 0, GeometrySide.right, GeometryFill.both, AnchorPosition.center, false);

                
                this.scale = new Scale()
                    .setCommand(&this.changeOpacity)
                    .setFromValue(0.2)
                    .setToValue(1.0)
                    .pack(0, 0, GeometrySide.bottom, GeometryFill.x, AnchorPosition.center, false);
                    try {
                        scale.setValue(preferencesArray[3].to!float);
                    } catch (ErrnoException error) {
                        writeln("Custom opacity couldn't be set!");
                    } catch (ConvException convError) {
                        writeln("Couldn't convert opacity string to float!");
                    }
                
                /*
                // for another day and probably not in the main frame
                this.textSide = new Text(container)
                    .setHeight(5)
                    .setWidth(40)
                    .appendText("This is a test for all the fonts!\naaaaaaaaaaaAAAAAAAAAAA")
                    .setForegroundColor("#00ff00")
                    .setFont("Helvetica")
                    .setBackgroundColor("#000000")
                    .pack(0, 0, GeometrySide.right, GeometryFill.both, AnchorPosition.center, true);
                */

        return frameMain;
    }

    /**
     * Sets up the keybindings.
     */
    private void setUpKeyBindings() {
        root.bind("<Control-o>", &this.openOpenFileDialog); // Open
		root.bind("<Control-s>", &this.openSaveFileDialog); // Save
		root.bind("<Control-p>", &this.openPreferencesWindow); // Preferences
	}

    private void exitApplication(CommandArgs args) {
		this.exit();
	}

    /**
     * Initialize user interface.
     */
	override protected void initInterface() {

		this.root = mainWindow()
            .setDefaultIcon([new EmbeddedPng!("NoteMaker.png")])
            .setGeometry(0, 0, 600, 50)
            .setMinSize(700, 800);

        this.root.setIdleCommand(delegate(CommandArgs args) {
            root.setTitle("Note Maker");
			root.setOpacity(this.scale.getValue());
            root.setIdleCommand(args.callback, 3000);
        });

		auto menuBar = new MenuBar(root);

		auto fileMenu = new Menu(menuBar, "File", 0)
			.addEntry("Open File...", &this.openOpenFileDialog)
            .addEntry("Save As", &this.openSaveFileDialog)
			.addSeparator()
			.addEntry("Preferences", &this.openPreferencesWindow)
            .addSeparator()
            .addEntry("Exit", &this.exitApplication);

		auto noteBook   = new NoteBook();
		auto mainPane = this.createMainPane();

		noteBook
			.addTab("Main File", mainPane)
			.pack(0, 0, GeometrySide.top, GeometryFill.both, AnchorPosition.center, true);

        //Text[5] textlist;
        //textlist[0] = textMain;
        //textlist[0].setBackgroundColor("#FFF");

		this.setUpKeyBindings();

        if (!preferencesFileExists) {
            auto dialog = new MessageDialog(this.mainWindow, "Preferences File")
                .setDetailMessage("Preferences file could not be found and has been created!")
                .show();
        }
	}
}

void main(string[] args) {
	auto app = new Application();                        
	app.run();                                     
}
