module main;

import tkd.tkdapplication;   
import std.stdio;    
import preferences, inputoutput, gui, tabs; // source imports
import std.conv;

// NoteMaker application.
class Application : TkdApplication {

    // variables
	Window root;
	Gui gui;
	Preferences pref;
	InputOutput io;
	Tabs tabs;

    // initialize user interface
	override public void initInterface() {

        // sets up root
		this.root = mainWindow()
            .setDefaultIcon([new EmbeddedPng!("NoteMaker.png")])
            .setGeometry(0, 0, 600, 50)
            .setMinSize(700, 800);

        // makes the code in "gui.d" usable in "main.d"
        gui = new Gui(root);

        // creates the noteBook and the default tab
		auto noteBook = new NoteBook();
		auto mainPane = gui.createMainPane();

        // shows the noteBook adds the default tab to it
		noteBook
			.addTab("Main File", mainPane)
			.enableKeyboardTraversal()
			.pack(0, 0, GeometrySide.top, GeometryFill.both, AnchorPosition.center, true);

        // makes the code in other files usable in "main.d"
		io = new InputOutput(root, gui.textMain, noteBook);
		tabs = new Tabs(root, noteBook, gui.textWidgetArray);
		pref = new Preferences(root, gui.textMain, gui.opacitySlider, gui.preferencesFile, noteBook, gui.textWidgetArray);

        // create the menu bar at the top
        auto menuBar = new MenuBar(root);

        // sets up the "File" menu
		auto fileMenu = new Menu(menuBar, "File", 0)
			.addEntry("Open File...", &openFile, "Ctrl+O")
            .addEntry("Save As", &saveFile, "Ctrl+S")
			.addSeparator()
            .addEntry("New Tab", &tabs.createNewTab, "Ctrl+N")
			.addEntry("Remove Tab", &tabs.removeTab, "Ctrl+W")
            .addSeparator()
			.addEntry("Preferences", &openPreferences, "Ctrl+P")
			.addEntry("Next Tab", &nextTab, "Ctrl+Tab")
			.addEntry("Previous Tab", &previousTab, "Ctrl+Shift+Tab")
            .addSeparator()
            .addEntry("Quit", &this.exitApplication);

        // runs every 3 seconds: resets the title 
        this.root.setIdleCommand(delegate(CommandArgs args) {
            root.setTitle("Note Maker");
			root.setOpacity(gui.opacitySlider.getValue());
            root.setIdleCommand(args.callback, 3000);
        });

        // sets opacity on application boot
        root.setOpacity(gui.opacitySlider.getValue());

        // sets up the keybindings
        root.bind("<Control-o>", &openFile); // Open
		root.bind("<Control-s>", &saveFile); // Save
		root.bind("<Control-n>", &tabs.createNewTab); // New Tab
        root.bind("<Control-w>", &tabs.removeTab); // Close Tab
		root.bind("<Control-p>", &openPreferences); // Preferences
        root.bind("<Control-q>", &this.exitApplication); // Quit
		
        // checks if the preferences file exists if false creates one and tells you about it
        if (!gui.preferencesFileExists) {
            auto dialog = new MessageDialog(this.root, "Preferences File")
                .setDetailMessage("Preferences file could not be found and has been created!")
                .show();
        }
	}

	// opens a file according to the dialog
	public void openFile(CommandArgs args) {
		io.openOpenFileDialog(args, tabs.updateArray());
	}

	// saves a file according to the dialog
	public void saveFile(CommandArgs args) {
		io.openSaveFileDialog(args, tabs.updateArray());
	}

	// opens the preferences window
	public void openPreferences(CommandArgs args) {
		pref.openPreferencesWindow(args, tabs.updateArray());
	}

	// selects the next tab unless its state is "hidden"
	public void nextTab(CommandArgs args) {
		tabs.nextTab(args);
	}

	// selects the previous tab unless its state is "hidden"
	public void previousTab(CommandArgs args) {
		tabs.previousTab(args);
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