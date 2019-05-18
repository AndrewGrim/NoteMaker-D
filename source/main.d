module main;

import tkd.tkdapplication;      
import std.stdio;         
import std.conv;
import std.file;
import std.string;
import std.exception;
import preferences;

/**
 * NoteMaker application.
 */
class Application : TkdApplication {

	public Window root;
	public string fileToOpen;
    public string fileToSave;
    public Text textMain;
    public Scale opacitySlider;
    public Window preferencesWindow;
    public string preferencesFile;
    public string[10] preferencesArray; // should probably have strings named appropriately according to the options
    public bool preferencesFileExists;

    public void openOpenFileDialog(CommandArgs args) {
		
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

    public void openSaveFileDialog(CommandArgs args) {

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

    public void changeOpacity(CommandArgs args) {
        root.setOpacity(this.opacitySlider.getValue());
        writeln("alpha: ", this.opacitySlider.getValue());
    }

    public Frame createMainPane() {

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

                
                this.opacitySlider = new Scale()
                    .setCommand(&this.changeOpacity)
                    .setFromValue(0.2)
                    .setToValue(1.0)
                    .pack(0, 0, GeometrySide.bottom, GeometryFill.x, AnchorPosition.center, false);
                    try {
                        opacitySlider.setValue(preferencesArray[3].to!float);
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

    public void exitApplication(CommandArgs args) {
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
			root.setOpacity(this.opacitySlider.getValue());
            root.setIdleCommand(args.callback, 3000);
        });

		auto noteBook = new NoteBook();
		auto mainPane = this.createMainPane();

		noteBook
			.addTab("Main File", mainPane)
			.pack(0, 0, GeometrySide.top, GeometryFill.both, AnchorPosition.center, true);

        Preferences pref = new Preferences(root, textMain, opacitySlider, preferencesFile);

        auto menuBar = new MenuBar(root);

		auto fileMenu = new Menu(menuBar, "File", 0)
			.addEntry("Open File...", &this.openOpenFileDialog)
            .addEntry("Save As", &this.openSaveFileDialog)
			.addSeparator()
			.addEntry("Preferences", &pref.openPreferencesWindow)
            .addSeparator()
            .addEntry("Exit", &this.exitApplication);

        root.bind("<Control-o>", &this.openOpenFileDialog); // Open
		root.bind("<Control-s>", &this.openSaveFileDialog); // Save
		root.bind("<Control-p>", &pref.openPreferencesWindow); // Preferences
		
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
