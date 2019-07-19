module indentation;

import tkd.tkdapplication;  
import std.stdio;
import std.string;
import std.conv;

class Indentation {

	public static void indent(NoteBook noteBook, Text[] textWidgetArray) {
		Text textWidget = textWidgetArray[noteBook.getCurrentTabId()];
		string insertLine = ((textWidget.getInsertCursorIndex().split("."))[0]) ~ ".0";

		string[] selectionRange = textWidget.getTagRanges("sel");
		if (!selectionRange.empty) {
			string start = selectionRange[0];
			string end = selectionRange[1];
			if (start.split(".")[0].to!int != end.split(".")[0].to!int) {
				int startLine = start.split(".")[0].to!int;
				int endLine = end.split(".")[0].to!int;
				for (int line = startLine; line <= endLine; line++) {
					string tabLine = line.to!string ~ ".0";
					textWidget.insertText(tabLine, "\t");
				}
			} else {
				textWidget.insertText(insertLine, "\t");
			}
		} else {
			textWidget.insertText(insertLine, "\t");
		}
	}

	public static void unindent(NoteBook noteBook, Text[] textWidgetArray) {
		Text textWidget = textWidgetArray[noteBook.getCurrentTabId()];
		string insertLine = ((textWidget.getInsertCursorIndex().split("."))[0]) ~ ".0";
		string insertLineEnd = (textWidget.getInsertCursorIndex().split(".")[0]) ~ ".end";
		string indexOfTab; // could cause some shit
		string endIndexOfTab;
		if (textWidget.find("\t", insertLine, insertLineEnd).length != 0) {
			indexOfTab = textWidget.find("\t", insertLine, insertLineEnd);
			endIndexOfTab = indexOfTab.split(".")[0] ~ "." ~ ((indexOfTab.split(".")[1].to!int) + 1).to!string;
		} else {
			writeln("tab character not found in line!");
		}

		string[] selectionRange = textWidget.getTagRanges("sel");
		if (!selectionRange.empty) {
			string start = selectionRange[0];
			string end = selectionRange[1];
			if (start.split(".")[0].to!int != end.split(".")[0].to!int) {
				int startLine = start.split(".")[0].to!int;
				int endLine = end.split(".")[0].to!int;
				for (int line = startLine; line <= endLine; line++) {
					string tabLine = line.to!string ~ ".0";
					string tabLineEnd = line.to!string ~ ".end";
					if (textWidget.find("\t", tabLine, tabLineEnd).length != 0) {
						string indexOfTabInLine = textWidget.find("\t", tabLine, tabLineEnd);
						string endIndexOfTabInLine = indexOfTabInLine.split(".")[0] ~ "." ~ ((indexOfTabInLine.split(".")[1].to!int) + 1).to!string;
						textWidget.deleteText(indexOfTabInLine, endIndexOfTabInLine);
					}
				}
			} else {
				textWidget.deleteText(indexOfTab, endIndexOfTab);
			}
		} else {
			if (indexOfTab.length != 0) {
				textWidget.deleteText(indexOfTab, endIndexOfTab);
			}
		}
	}
}