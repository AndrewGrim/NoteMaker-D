module inputoutput;

import tkd.tkdapplication;      
import std.stdio;         
import std.file;
import std.string;
import std.path;

// saving and opening methods
class InputOutput {

	// variables
	Window root;
	Text textMain;
	string fileToOpen;
	string fileToSave;
	NoteBook noteBook;
	string[string] tabNameFilePath;

	// constructor
	this(Window root, Text textMain, NoteBook noteBook) {
		this.root = root;
		this.textMain = textMain;
		this.noteBook = noteBook;
	}

	// opens the openFile dialog allowing you to choose the file to load
	public void openOpenFileDialog(CommandArgs args, Text[] textWidgetArray) {
		
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
			textWidgetArray[noteBook.getCurrentTabId()].insertText(0, 0, fileContent);
			noteBook.setTabText(noteBook.getCurrentTabId(), baseName(fileToOpen));

			root.setTitle("File opened: " ~ fileToOpen);

			tabNameFilePath[baseName(fileToOpen)] = fileToOpen;
		}
	}	

	// opens the saveFile dialog allowing you to choose where to save
	public void openSaveFileDialog(CommandArgs args, Text[] textWidgetArray) {	

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
		}
	}

	// saves the file
	public void saveFile(CommandArgs args, Text[] textWidgetArray) {

		if (noteBook.getTabText(noteBook.getCurrentTabId()) == "Main File" || 
			noteBook.getTabText(noteBook.getCurrentTabId()) == "New File") {
			openSaveFileDialog(args, textWidgetArray);
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
			}
		}
	}
}