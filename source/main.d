module main;

import tkd.tkdapplication;   
import std.stdio;    
import preferences, inputoutput, gui; // source imports

// NoteMaker application.
class Application : TkdApplication {

    // variables
	Window root;

    // initialize user interface
	override protected void initInterface() {

        // sets up root
		this.root = mainWindow()
            .setDefaultIcon([new EmbeddedPng!("NoteMaker.png")])
            .setGeometry(0, 0, 600, 50)
            .setMinSize(700, 800);

        // makes the code in "gui.d" usable in "main.d"
        auto gui = new Gui(root);

        // creates the noteBook and the default tab
		auto noteBook = new NoteBook();
		auto mainPane = gui.createMainPane();

        // shows the noteBook adds the default tab to it
		noteBook
			.addTab("Main File", mainPane)
			.pack(0, 0, GeometrySide.top, GeometryFill.both, AnchorPosition.center, true);

        // makes the code in other files usable in "main.d"
        auto pref = new Preferences(root, gui.textMain, gui.opacitySlider, gui.preferencesFile);
        auto io = new InputOutput(root, gui.textMain);

        // create the menu bar at the top
        auto menuBar = new MenuBar(root);

        // sets up the "File" menu
		auto fileMenu = new Menu(menuBar, "File", 0)
			.addEntry("Open File...", &io.openOpenFileDialog)
            .addEntry("Save As", &io.openSaveFileDialog)
			.addSeparator()
			.addEntry("Preferences", &pref.openPreferencesWindow)
            .addSeparator()
            .addEntry("Quit", &this.exitApplication);

        // runs every 3 seconds: resets the title 
        this.root.setIdleCommand(delegate(CommandArgs args) {
            root.setTitle("Note Maker");
            root.setIdleCommand(args.callback, 3000);
        });

        // sets opacity on application boot
        root.setOpacity(gui.opacitySlider.getValue());

        // sets up the keybindings
        root.bind("<Control-o>", &io.openOpenFileDialog); // Open
		root.bind("<Control-s>", &io.openSaveFileDialog); // Save
		root.bind("<Control-p>", &pref.openPreferencesWindow); // Preferences
        root.bind("<Control-q>", &this.exitApplication); // Quit
		
        // checks if the preferences file exists if false creates one and tells you about it
        if (!gui.preferencesFileExists) {
            auto dialog = new MessageDialog(this.root, "Preferences File")
                .setDetailMessage("Preferences file could not be found and has been created!")
                .show();
        }
	}

    // quits the application.
    public void exitApplication(CommandArgs args) {
		this.exit();
        writeln("Application closed!");
	}
}

// runs the application.
void main(string[] args) {
	auto app = new Application();                      
	app.run();                                  
}