module main;
import tkd.tkdapplication;      
import std.stdio;         
import std.conv;
import std.file;
import std.string;

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
	}

	private void openBackgroundColorDialog(CommandArgs args) {
		auto dialog = new ColorDialog("Choose a color")
			.setInitialColor(Color.white)
			.show();

		this.textMain.setBackgroundColor(dialog.getResult());
	}

	private void openPreferencesWindow(CommandArgs args) {

		auto preferencesWindow = new Window("Preferences", false)
			.setGeometry(180, 60, root.getXPos() + root.getXPos() / 2, 400);

		auto preferencesFrame = new Frame(preferencesWindow)
			.pack();

		auto changeForegroundColor = new Button(preferencesFrame, "Change Foreground Color")
			.setCommand(&openForegroundColorDialog)
			.pack();

		auto changeBackgroundColor = new Button(preferencesFrame, "Change Background Color")
			.setCommand(&openBackgroundColorDialog)
			.pack();

		// save the preferences to a file, to be read from for the defaults and preferences
	}

    private void changeOpacity(CommandArgs args) {
        root.setOpacity(this.scale.getValue());
    }

    private Frame createMainPane() {

        auto frameMain = new Frame(root);

            auto container = new Frame(frameMain)
                .pack(10, 0, GeometrySide.top, GeometryFill.both, AnchorPosition.center, true);

                this.textMain = new Text(container)
                    .setHeight(5)
                    .setWidth(40)
                    .setFont("Helvetica")
                    .setForegroundColor("#00ff00")
                    .setBackgroundColor("#000000")
                    .setInsertColor("#00ff00")
                    .pack(0, 0, GeometrySide.left, GeometryFill.both, AnchorPosition.center, true);

                auto yscroll = new YScrollBar(container)
                    .attachWidget(textMain)
                    .pack(0, 0, GeometrySide.right, GeometryFill.y, AnchorPosition.center, false);

                this.scale = new Scale()
                	.setCommand(&this.changeOpacity)
                    .setValue(0.69)
                	.setFromValue(0.2)
                	.setToValue(1.0)
                	.pack(0, 0, GeometrySide.bottom, GeometryFill.x, AnchorPosition.center, false);
                
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
			.addEntry("Open", &this.openOpenFileDialog)
            .addEntry("Save", &this.openSaveFileDialog)
			.addSeparator()
			.addEntry("Preferences", &this.openPreferencesWindow);

		auto noteBook   = new NoteBook();
		auto mainPane = this.createMainPane();

		noteBook
			.addTab("Main File", mainPane)
			.pack(0, 0, GeometrySide.top, GeometryFill.both, AnchorPosition.center, true);

		//auto sizeGrip = new SizeGrip(root)
		//	.pack(0, 0, GeometrySide.bottom, GeometryFill.none, AnchorPosition.southEast);

        //Text[5] textlist;
        //textlist[0] = textMain;
        //textlist[0].setBackgroundColor("#FFF");

		this.setUpKeyBindings();
	}
}

void main(string[] args) {
	auto app = new Application();                        
	app.run();                                     
}
