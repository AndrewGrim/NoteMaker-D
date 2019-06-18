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
	NoteBook noteBookSide;
	Text[] textWidgetArray;
	Text[] textWidgetArraySide;
	int[] lastClosedTab;
	int[] lastClosedTabSide;
	Frame[] frameWidgetArray;
	Frame[] frameWidgetArraySide;
	bool isSideSelected;

	//constructor
	this(Window root, NoteBook noteBook, NoteBook noteBookSide, Text[] textWidgetArray, Text[] textWidgetArraySide,
		Frame[] frameWidgetArray, Frame[] frameWidgetArraySide) {
		this.root = root;
		this.noteBook = noteBook;
		this.noteBookSide = noteBookSide;
		this.textWidgetArray = textWidgetArray;
		this.textWidgetArraySide = textWidgetArraySide;
		this.frameWidgetArray = frameWidgetArray;
		this.frameWidgetArraySide = frameWidgetArraySide;
	}

	// creates a new tab and adds it to the "noteBook"
	public void createNewTab(CommandArgs args) {

		checkCurrentNoteBook();

		// the main frame that gets returned to be used by the "noteBook"
		auto frameMain = new Frame(root);

		if (isSideSelected) {
			frameWidgetArraySide ~= frameMain;	
		} else {
			frameWidgetArray ~= frameMain;
		}
			

			// the frame containing all the widgets
			auto container = new Frame(frameMain)
				.pack(0, 0, GeometrySide.top, GeometryFill.both, AnchorPosition.center, true);

				Text textMain = textWidgetArray[0];

				// creates the "textWidget"
				auto textWidget = new Text(container)
					.setFont(textMain.getFont())
					.setForegroundColor(textMain.getForegroundColor())
					.setBackgroundColor(textMain.getBackgroundColor())
					.setInsertColor(textMain.getInsertColor())
					.setSelectionForegroundColor(textMain.getSelectionForegroundColor())
					.setSelectionBackgroundColor(textMain.getSelectionBackgroundColor())
					.pack(0, 0, GeometrySide.left, GeometryFill.both, AnchorPosition.center, true);

				// creates the vertical "yscrollWidget" for use with "textWidget"
				auto yscrollWidget = new YScrollBar(container)
					.attachWidget(textWidget)
					.pack(0, 0, GeometrySide.right, GeometryFill.both, AnchorPosition.center, false);

				textWidget.attachYScrollBar(yscrollWidget);

		textWidget.focus();
		if (isSideSelected) {
			noteBookSide.addTab("New File", frameMain);
			noteBookSide.selectTab(noteBook.getNumberOfTabs() - 1);
		} else {
			noteBook.addTab("New File", frameMain);
			noteBook.selectTab(noteBook.getNumberOfTabs() - 1);
		}
		textWidget.focus();

		if (isSideSelected) {
			textWidgetArraySide ~= textWidget;
		} else {
			textWidgetArray ~= textWidget;
		}
		isSideSelected = false;
		root.generateEvent("<<TextWidgetCreated>>");
	}

	// checks which notebook is currently selected by checking if one of its frames has the "hover" state
	public string checkCurrentNoteBook() {
		if (!isSideSelected) {
			foreach (frame; frameWidgetArraySide) {
				if (frame.inState(["hover"])) {
					isSideSelected = true;
					break;
				} 
			}
		} else {
			isSideSelected = false;
		}

		if (isSideSelected) {
			return "side";
		} else {
			return "main";
		}
	}

	// updates the array to include all the currently existing Text widgets
	public Text[] getTextWidgetArray() {
		return textWidgetArray;
	}

	// updates the array to include all the currently existing Text widgets
	public Text[] getTextWidgetArraySide() {
		return textWidgetArraySide;
	}

	// updates the array to include all the currently existing Frame widgets
	public Frame[] getFrameArray() {
		return frameWidgetArray;
	}

	// updates the array to include all the currently existing Frame widgets
	public Frame[] getFrameArraySide() {
		return frameWidgetArraySide;
	}

	// closes the tab by hiding it to keep the index consistent
	public void closeTab(CommandArgs args) {
		// sometimes when you close a tab in side, the focus is shifted over to main!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
		checkCurrentNoteBook();

		if (isSideSelected) {
			lastClosedTabSide ~= noteBookSide.getCurrentTabId();
			noteBookSide.hideTab("current");
			textWidgetArraySide[noteBookSide.getCurrentTabId()].focus();
		} else {
			lastClosedTab ~= noteBook.getCurrentTabId();
			noteBook.hideTab("current");
			textWidgetArray[noteBook.getCurrentTabId()].focus();
		}
		isSideSelected = false;
	}

	// selects the next tab
	public void nextTab(CommandArgs args) {
		checkCurrentNoteBook();

		int iteration = 2;

		if (isSideSelected) {
			if (noteBookSide.getTabState(noteBookSide.getCurrentTabId() + 1) == "hidden") {
				while (true) {
					if (noteBookSide.getTabState(noteBookSide.getCurrentTabId() + iteration) == "hidden") {
						writeln("Tab still hidden!");
						iteration++;
					} else {
						writeln("Normal tab!");
						break;
					}
				}
				noteBookSide.selectTab(noteBookSide.getCurrentTabId() + iteration);
				textWidgetArraySide[noteBook.getCurrentTabId()].focus();
			} else {
				noteBookSide.selectTab(noteBookSide.getCurrentTabId() + 1);
				textWidgetArraySide[noteBookSide.getCurrentTabId()].focus();
			}
		} else {
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
		isSideSelected = false;
	}

	// selects the previous tab
	public void previousTab(CommandArgs args) {
		checkCurrentNoteBook();

		int iteration = 2;

		if (isSideSelected) {
			if (noteBookSide.getTabState(noteBookSide.getCurrentTabId() - 1) == "hidden") {
				while (true) {
					if (noteBookSide.getTabState(noteBookSide.getCurrentTabId() - iteration) == "hidden") {
						writeln("Tab still hidden!");
						iteration++;
					} else {
						writeln("Normal tab!");
						break;
					}
				}
				noteBookSide.selectTab(noteBookSide.getCurrentTabId() - iteration);
				textWidgetArraySide[noteBook.getCurrentTabId()].focus();
			} else {
				noteBookSide.selectTab(noteBookSide.getCurrentTabId() - 1);
				textWidgetArraySide[noteBookSide.getCurrentTabId()].focus();
			}
		} else {
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
		isSideSelected = false;
	}

	// reopens the last closed tab
	public void reopenClosedTab(CommandArgs args) {
		checkCurrentNoteBook();

		for (int index = 1; index <= lastClosedTab.length; index++) { 
			if (noteBook.getTabState(lastClosedTab[$ - index]) == "hidden") {
				noteBook.selectTab(lastClosedTab[$ - index]);
				textWidgetArray[noteBook.getCurrentTabId()].focus();
				break;
			} 
		}
		isSideSelected = false;
	}
}