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
	NoteBook noteBookTerminal;
	Text[] textWidgetArray;
	int[] lastClosedTab;

	//constructor
	this(Window root, NoteBook noteBook, NoteBook noteBookTerminal, Text[] textWidgetArray) {
		this.root = root;
		this.noteBook = noteBook;
		this.noteBookTerminal = noteBookTerminal;
		this.textWidgetArray = textWidgetArray;
	}

	// creates a new tab and adds it to the "noteBook"
	public void createNewTab(CommandArgs args) {
		// the main frame that gets returned to be used by the "noteBook"
		auto frameMain = new Frame(root);

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
					.setWrapMode("none")
					.setWidth(1) // to prevent scrollbars from dissappearing
					.setHeight(1)
					.pack(0, 0, GeometrySide.left, GeometryFill.both, AnchorPosition.center, true);

				// creates the vertical "yscrollWidget" for use with "textWidget"
				auto yscrollWidget = new YScrollBar(container)
					.attachWidget(textWidget)
					.pack(0, 0, GeometrySide.right, GeometryFill.both, AnchorPosition.center, false);

				textWidget.attachYScrollBar(yscrollWidget);

				auto xscrollWidget = new XScrollBar(frameMain)
					.attachWidget(textWidget)
					.pack(0, 0, GeometrySide.bottom, GeometryFill.both, AnchorPosition.center, false);

				textWidget.attachXScrollBar(xscrollWidget);

		noteBook.addTab("New File", frameMain);
		noteBook.selectTab(noteBook.getNumberOfTabs() - 1);
		
		textWidget.focus();

		textWidgetArray ~= textWidget;
		
		root.generateEvent("<<TextWidgetCreated>>");
	}

	// updates the array to include all the currently existing Text widgets
	public Text[] getTextWidgetArray() {
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