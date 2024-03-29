module indentation;

import tkd.tkdapplication;  
import std.stdio;
import std.string;
import std.conv;

/// Class for adding and removing indentation from text.
class Indentation {

	/// Indent the selected text unless selection is empty, in which case indent at insert cursor.
	public static void indent(NoteBook noteBook, Text[] textWidgetArray, string[] selectionRange) {
		Text textWidget = textWidgetArray[noteBook.getCurrentTabId()];
		string insertLine = ((textWidget.getInsertCursorIndex().split("."))[0]) ~ ".0";

		if (!selectionRange.empty) {
			// selection not empty
			string start = selectionRange[0];
			string end = selectionRange[1];
			if (start.split(".")[0].to!int != end.split(".")[0].to!int) {
				// selection spans multiple lines
				const int startLine = start.split(".")[0].to!int;
				const int endLine = end.split(".")[0].to!int;
				for (int line = startLine; line <= endLine; line++) {
					string tabLine = line.to!string ~ ".0";
					textWidget.setReadOnly(false);
					textWidget.insertText(tabLine, "\t");
				}
			} else {
				// selection spans only one line
				textWidget.setReadOnly(false);
				textWidget.insertText(insertLine, "\t");
			}
		} else {
			// nothing is selected
			textWidget.setReadOnly(false);
			const string cursorPos = textWidget.getInsertCursorIndex();
			textWidget.insertText(cursorPos, "\t");
		}
		textWidget.focus();
	}

	/// Unindent the selected text unless selection is empty, in which case unindent at insert cursor.
	public static void unindent(NoteBook noteBook, Text[] textWidgetArray) {
		Text textWidget = textWidgetArray[noteBook.getCurrentTabId()];
		string insertLine = ((textWidget.getInsertCursorIndex().split("."))[0]) ~ ".0";
		string insertLineEnd = (textWidget.getInsertCursorIndex().split(".")[0]) ~ ".end";
		string indexOfTab;
		string endIndexOfTab;
		if (textWidget.find("\t", insertLine, insertLineEnd).length != 0) {
			indexOfTab = textWidget.find("\t", insertLine, insertLineEnd);
			endIndexOfTab = indexOfTab.split(".")[0] ~ "." ~ ((indexOfTab.split(".")[1].to!int) + 1).to!string;
		} else {
			writeln("tab character not found in line!");
		}

		string[] selectionRange = textWidget.getTagRanges("sel");
		if (!selectionRange.empty) {
			// selection not empty
			string start = selectionRange[0];
			string end = selectionRange[1];
			if (start.split(".")[0].to!int != end.split(".")[0].to!int) {
				// selection spans multiple lines
				const int startLine = start.split(".")[0].to!int;
				const int endLine = end.split(".")[0].to!int;
				for (int line = startLine; line <= endLine; line++) {
					string tabLine = line.to!string ~ ".0";
					string tabLineEnd = line.to!string ~ ".end";
					if (textWidget.find("\t", tabLine, tabLineEnd).length != 0) {
						string indexOfTabInLine = textWidget.find("\t", tabLine, tabLineEnd);
						string endIndexOfTabInLine = indexOfTabInLine.split(".")[0] ~ "." ~ ((indexOfTabInLine.split(".")[1].to!int) + 1).to!string; // @suppress(dscanner.style.long_line)
						textWidget.setReadOnly(false);
						textWidget.deleteText(indexOfTabInLine, endIndexOfTabInLine);
					}
				}
			} else {
				// selection spans only one line
				textWidget.setReadOnly(false);
				textWidget.deleteText(indexOfTab, endIndexOfTab);
			}
		} else {
			// nothing is selected
			if (indexOfTab.length != 0) {
				textWidget.setReadOnly(false);
				textWidget.deleteText(indexOfTab, endIndexOfTab);
			}
		}
	}
}