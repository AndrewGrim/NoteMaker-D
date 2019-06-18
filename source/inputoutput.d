module inputoutput;

import tkd.tkdapplication;      
import std.stdio;         
import std.file;
import std.string;
import std.path;
import std.exception;
import std.conv;

// saving and opening methods
class InputOutput {

	// variables
	Window root;
	string fileToOpen;
	string fileToSave;
	string[string] tabNameFilePath;
	bool openingFile;

	// constructor
	this(Window root) {
		this.root = root;
	}

	public bool getOpeningFile() {
		return openingFile;
	}

	public void setOpeningFile(bool state) {
		openingFile = state;
	}

	// opens the openFile dialog allowing you to choose the file to load
	public void openOpenFileDialog(CommandArgs args, NoteBook noteBook, Text[] textWidgetArray) {
		
		auto openFile = new OpenFileDialog("Open a file")
			.setMultiSelection(false)
			.setDefaultExtension(".txt")
			.addFileType("{{All files} {*}}")
			.addFileType("{{Text files} {.txt}}")
			.setInitialDirectory("~")
			.setInitialFile("file.txt")
			.show();

		fileToOpen = openFile.getResult();
		writeln("opening: ", fileToOpen);

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

			textWidgetArray[noteBook.getCurrentTabId()].clear();
			textWidgetArray[noteBook.getCurrentTabId()].insertText(0, 0, fileContent, "tabWidth");
			
			noteBook.setTabText(noteBook.getCurrentTabId(), baseName(fileToOpen));
			root.setTitle("File opened: " ~ fileToOpen);
			tabNameFilePath[baseName(fileToOpen)] = fileToOpen;

			string numOfLines = textWidgetArray[noteBook.getCurrentTabId()].getNumberOfLines();
			string[] linesConv = numOfLines.split(".");
			textWidgetArray[noteBook.getCurrentTabId()].deleteText((linesConv[0].to!int - 2).to!string ~ ".0", "end");

			openingFile = true;
		}
	}	

	// opens the saveFile dialog allowing you to choose where to save
	public void openSaveFileDialog(CommandArgs args, NoteBook noteBook, Text[] textWidgetArray) {	

		auto saveFile = new SaveFileDialog()
			.setConfirmOverwrite(true)
			.setDefaultExtension(".dmo")
			.addFileType("{{All files} {*}}")
			.setInitialDirectory("~")
			.setInitialFile("note.txt")
			.show();

		fileToSave = saveFile.getResult();
		writeln("saving as: ", fileToSave);

		if (saveFile.getResult() == "") {

			writeln("Save cancelled!");

		} else {

			auto f = File(fileToSave, "w");

			f.write(textWidgetArray[noteBook.getCurrentTabId()].getText());

			f.close();

			noteBook.setTabText(noteBook.getCurrentTabId(), baseName(fileToSave));
			root.setTitle("File saved: " ~ fileToSave);
			tabNameFilePath[baseName(fileToSave)] = fileToSave;

			textWidgetArray[noteBook.getCurrentTabId()].addTag("tabWidth", "1.0", "end");
		}
	}

	// saves the file
	public void saveFile(CommandArgs args, NoteBook noteBook, Text[] textWidgetArray) {

		if (noteBook.getTabText(noteBook.getCurrentTabId()) == "Main File" || 
			noteBook.getTabText(noteBook.getCurrentTabId()) == "New File") {
			openSaveFileDialog(args, noteBook, textWidgetArray);
		} else {
			fileToSave = tabNameFilePath.get(noteBook.getTabText(noteBook.getCurrentTabId()), "Record does not exist!");
			if (fileToSave == "Record does not exist!") {
				writeln("Save cancelled! Path could not be found!");
			} else {
				writeln("saving: ", fileToSave);
		
				auto f = File(fileToSave, "w");

				f.write(textWidgetArray[noteBook.getCurrentTabId()].getText());

				f.close();

				noteBook.setTabText(noteBook.getCurrentTabId(), baseName(fileToSave));
				root.setTitle("File saved: " ~ fileToSave);

				textWidgetArray[noteBook.getCurrentTabId()].addTag("tabWidth", "1.0", "end");
			}
		}
	}
}