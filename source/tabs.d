module tabs;

import tkd.tkdapplication;
import std.stdio;
import std.conv;
import std.file;
import std.string;
import std.exception;

/// Class for creating, closing and otherwise controlling tabs.
class Tabs {

	/// Variable used to acces the main window.
	Window root;

	/// Variable used to access the main NoteBook widget.
	NoteBook noteBook;

	/// Variable used to access the terminal NoteBook widget.
	NoteBook noteBookTerminal;

	/// Array that holds all the existing Text widgets apart from the terminal and line numbers.
	Text[] textWidgetArray;

	/// Array for keeping track which tab was closed most recently. Used for reopening them in that order.
	int[] lastClosedTab;

	/// Constructor.
	this(Window root, NoteBook noteBook, NoteBook noteBookTerminal, Text[] textWidgetArray) {
		this.root = root;
		this.noteBook = noteBook;
		this.noteBookTerminal = noteBookTerminal;
		this.textWidgetArray = textWidgetArray;
	}

	/// Creates a new tab and adds it to the main "noteBook" widget.
	public void createNewTab(CommandArgs args) { // @suppress(dscanner.suspicious.unused_parameter)
		// The main frame that gets returned to be used by the "noteBook".
		Frame frameMain = new Frame(root);

			// The frame containing all the widgets.
			Frame container = new Frame(frameMain)
				.pack(0, 0, GeometrySide.top, GeometryFill.both, AnchorPosition.center, true);

				Text textMain = textWidgetArray[0];

				Text textWidget = new Text(container)
					.setFont(textMain.getFont())
					.setForegroundColor(textMain.getForegroundColor())
					.setBackgroundColor(textMain.getBackgroundColor())
					.setInsertColor(textMain.getInsertColor())
					.setSelectionForegroundColor(textMain.getSelectionForegroundColor())
					.setSelectionBackgroundColor(textMain.getSelectionBackgroundColor())
					.setWrapMode("none")
					.setWidth(1) // to prevent scrollbars from dissappearing
					.setHeight(1) // to prevent scrollbars from dissappearing
					.pack(0, 0, GeometrySide.left, GeometryFill.both, AnchorPosition.center, true);

				YScrollBar yscrollWidget = new YScrollBar(container)
					.attachWidget(textWidget)
					.pack(0, 0, GeometrySide.right, GeometryFill.both, AnchorPosition.center, false);

				textWidget.attachYScrollBar(yscrollWidget);

				XScrollBar xscrollWidget = new XScrollBar(frameMain)
					.attachWidget(textWidget)
					.pack(0, 0, GeometrySide.bottom, GeometryFill.both, AnchorPosition.center, false);

				textWidget.attachXScrollBar(xscrollWidget);

		noteBook.addTab("New File", frameMain);
		noteBook.selectTab(noteBook.getNumberOfTabs() - 1);
		
		textWidget.focus();

		textWidgetArray ~= textWidget;
		
		root.generateEvent("<<TextWidgetCreated>>");
	}

	public Text[] getTextWidgetArray() {
		return textWidgetArray;
	}

	/// Closes the tab by hiding it to keep the index consistent.
	public void closeTab(CommandArgs args) { // @suppress(dscanner.suspicious.unused_parameter)
		if (noteBook.getCurrentTabId() != 0) { // Prevents you from closing the original tab.
			lastClosedTab ~= noteBook.getCurrentTabId();
			noteBook.hideTab("current");
			textWidgetArray[noteBook.getCurrentTabId()].focus();
		}
	}

	/// Selects the next tab and focuses on the Text widget within so you can start typing.
	public void nextTab(CommandArgs args) { // @suppress(dscanner.suspicious.unused_parameter)
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

	/// Selects the previous tab and focuses on the Text widget within so you can start typing.
	public void previousTab(CommandArgs args) { // @suppress(dscanner.suspicious.unused_parameter)
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

	/// Reopens the last closed tab.
	public void reopenClosedTab(CommandArgs args) { // @suppress(dscanner.suspicious.unused_parameter)
		for (int index = 1; index <= lastClosedTab.length; index++) { 
			if (noteBook.getTabState(lastClosedTab[$ - index]) == "hidden") {
				noteBook.selectTab(lastClosedTab[$ - index]);
				textWidgetArray[noteBook.getCurrentTabId()].focus();
				break;
			} 
		}
	}
}