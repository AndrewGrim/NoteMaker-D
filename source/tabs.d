module tabs;

import tkd.tkdapplication;
import std.stdio;
import std.conv;
import std.file;
import std.string;
import std.exception;

// creating tabs etc.
class Tabs {

    //variables
    Window root;
    NoteBook noteBook;
	Text[] textWidgetArray;
	string preferencesFile;
    bool preferencesFileExists;
    string[] preferencesArray;
    string font, foreground, background, insert;
    string opacity = "1.0";
	int[] lastClosedTab;

    //constructor
    this(Window root, NoteBook noteBook, Text[] textWidgetArray) {
        this.root = root;
        this.noteBook = noteBook;
		this.textWidgetArray = textWidgetArray;
    }

	// creates a new tab and adds it to the "noteBook"
    public void createNewTab(CommandArgs args) {
        
        // the main frame that gets returned to be used by the "noteBook"
		auto frameMain = new Frame(root);

            // the frame containing all the widgets
            auto container = new Frame(frameMain)
                .pack(0, 0, GeometrySide.top, GeometryFill.both, AnchorPosition.center, true);

				// tries to read options from the "preferences.txt" file, if it fails the file is created with default values
				try {
                    preferencesFile = getcwd() ~ "/preferences.txt";
                    
                    auto f = File(preferencesFile, "r");

                    preferencesFileExists = true;

                    // reading from file and adding each line into the "preferencesArray"
                    while (!f.eof()) {
                        string line = chomp(f.readln());
						preferencesArray ~= line;
                    }

                    // spliting array values into aptly named variables
                    font = preferencesArray[0];
                    foreground = preferencesArray[1];
                    background = preferencesArray[2];
                    insert = preferencesArray[3];
                    opacity = preferencesArray[4];

                } catch (ErrnoException error) {
                    // when the preferences files is not found it is created with default values
                    preferencesFileExists = false;

                    auto f = File(preferencesFile, "w");
                    f.write("Helvetica\n#000000\n#ffffff\n#000000\n1.0");
                    f.close();

                    writeln("Failed to read preferences file! Preferences file created!");
                }

                // creates the "textWidget"
                auto textWidget = new Text(container)
                    .setHeight(5)
                    .setWidth(40)
                    .pack(0, 0, GeometrySide.left, GeometryFill.both, AnchorPosition.center, true);
					// tries to read in the values from file
                    try {
                        textWidget
                            .setFont(font)
                            .setForegroundColor(foreground)
                            .setBackgroundColor(background)
                            .setInsertColor(insert);
                    } catch (ErrnoException error) {
                        writeln("Custom text widget options couldn't be set!");
                    }

                // creates the vertical "yscrollWidget" for use with "textWidget"
                auto yscrollWidget = new YScrollBar(container)
                    .attachWidget(textWidget)
                    .pack(0, 0, GeometrySide.right, GeometryFill.both, AnchorPosition.center, false);

				textWidget.attachYScrollBar(yscrollWidget);

        noteBook.addTab("New File", frameMain);
		noteBook.selectTab(noteBook.getNumberOfTabs() - 1);

		textWidgetArray ~= textWidget;
		textWidget.focus();
    }

	// updates the array to include all the currently existing Text widgets
	public Text[] updateArray() {
		return textWidgetArray;
	}

	// closes the tab by hiding it to keep the index consistent
	public void closeTab(CommandArgs args) {
		lastClosedTab ~= noteBook.getCurrentTabId();
		noteBook.hideTab("current");
		textWidgetArray[noteBook.getCurrentTabId()].focus();
	}

	// selects the next tab
	public void nextTab(CommandArgs args) {

		int iteration = 2;

		if (noteBook.getTabState(noteBook.getCurrentTabId() + 1) == "hidden") {
			while (true) {
				if (noteBook.getTabState(noteBook.getCurrentTabId() + iteration) == "hidden") {
					writeln("Tab still hidden!");
					iteration++;
				} else {
					writeln("Normal tab!");
					break;
				}
			}
			noteBook.selectTab(noteBook.getCurrentTabId() + iteration);
			textWidgetArray[noteBook.getCurrentTabId()].focus();
		} else {
			noteBook.selectTab(noteBook.getCurrentTabId() + 1);
			textWidgetArray[noteBook.getCurrentTabId()].focus();
		}
	}

	// selects the previous tab
	public void previousTab(CommandArgs args) {

		int iteration = 2;

		if (noteBook.getTabState(noteBook.getCurrentTabId() - 1) == "hidden") {
			while (true) {
				if (noteBook.getTabState(noteBook.getCurrentTabId() - iteration) == "hidden") {
					writeln("Tab still hidden!");
					iteration++;
				} else {
					writeln("Normal tab!");
					break;
				}
			}
			noteBook.selectTab(noteBook.getCurrentTabId() - iteration);
			textWidgetArray[noteBook.getCurrentTabId()].focus();
		} else {
			noteBook.selectTab(noteBook.getCurrentTabId() - 1);
			textWidgetArray[noteBook.getCurrentTabId()].focus();
		}
	}

	// reopens the last closed tab
	public void reopenClosedTab(CommandArgs args) {
		for (int index = 1; index <= lastClosedTab.length; index++) { 
			if (noteBook.getTabState(lastClosedTab[$ - index]) == "hidden") {
				noteBook.selectTab(lastClosedTab[$ - index]);
				textWidgetArray[noteBook.getCurrentTabId()].focus();
				break;
			} 
		}
	}
}