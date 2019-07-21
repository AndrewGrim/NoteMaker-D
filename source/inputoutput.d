module inputoutput;

import tkd.tkdapplication;      
import std.stdio;         
import std.file;
import std.string;
import std.path;
import std.exception;
import std.conv;

/// Class for opening and saving files.
class InputOutput {

	/// Variable used to access the main window.
	Window root;

	/// The full path to the file thats going to be opened.
	string fileToOpen;

	/// The full path to the file thats going to be saved.
	string fileToSave;

	/// Associative array storing the full file path value under the fileName + extension key.
	string[string] tabNameFilePath;

	/// Variables to check if a file is being opened.
	bool openingFile;

	/// The Text widget containing the line numbers.
	Text lineNumbersTextWidget;

	/// Constructor.
	this(Window root, Text lineNumbersTextWidget) {
		this.root = root;
		this.lineNumbersTextWidget = lineNumbersTextWidget;
	}

	public bool getOpeningFile() {
		return openingFile;
	}

	public void setOpeningFile(bool state) {
		openingFile = state;
	}

	/// Opens the openFile dialog allowing you to choose the file to load.
	public void openOpenFileDialog(CommandArgs args, NoteBook noteBook, Text[] textWidgetArray) { // @suppress(dscanner.suspicious.unused_parameter)
		Text textWidget = textWidgetArray[noteBook.getCurrentTabId()];

		OpenFileDialog openFile = new OpenFileDialog("Open a file")
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

			File f = File(fileToOpen, "r");
			
			string fileContent;

			while (!f.eof()) { 
				string line = chomp(f.readln()); 
				fileContent ~= line ~ "\n"; 
				}

			f.close();

			int removeLines = 1;
			if (fileContent.endsWith("\n\n")) {
				removeLines = 2;
			}

			textWidget.setReadOnly(false);
			textWidget.clear();
			textWidget.insertText(0, 0, fileContent, "tabWidth");
			
			noteBook.setTabText(noteBook.getCurrentTabId(), baseName(fileToOpen));
			root.setTitle("File opened: " ~ fileToOpen);
			tabNameFilePath[baseName(fileToOpen)] = fileToOpen;

			// The block below sets the line numbers based on file contents.
			string numOfLines = (((textWidget.getNumberOfLines().split(".")[0]).to!int) - removeLines).to!string;
			textWidget.deleteText(numOfLines ~ ".0", "end");

			string lineNumbers;
			for (int i = 1; i < numOfLines.to!int; i++) {
				if (i == (numOfLines.to!int - 1)) {
					lineNumbers ~= i.to!string;
				} else {
					lineNumbers ~= i.to!string ~ "\n";
				}
			}
			
			if ((numOfLines.length).to!int < 3) {
				lineNumbersTextWidget.setWidth(3);
			} else {
				lineNumbersTextWidget.setWidth((numOfLines.length).to!int);
			}
			lineNumbersTextWidget.setFont(textWidget.getFont());
			lineNumbersTextWidget.setForegroundColor(textWidget.getForegroundColor());
			lineNumbersTextWidget.setBackgroundColor(textWidget.getBackgroundColor()); 
			lineNumbersTextWidget.clear();
			lineNumbersTextWidget.appendText(lineNumbers, "alignCenter");
			lineNumbersTextWidget.setReadOnly();

			openingFile = true;
			root.generateEvent("<<ResetTitle>>");
		}
	}	

	/// Opens the saveFile dialog allowing you to choose where to save.
	public void openSaveFileDialog(CommandArgs args, NoteBook noteBook, Text[] textWidgetArray) { // @suppress(dscanner.suspicious.unused_parameter)	
		Text textWidget = textWidgetArray[noteBook.getCurrentTabId()];

		SaveFileDialog saveFile = new SaveFileDialog()
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

			File f = File(fileToSave, "w");

			f.write(textWidget.getText());

			f.close();

			noteBook.setTabText(noteBook.getCurrentTabId(), baseName(fileToSave));
			root.setTitle("File saved: " ~ fileToSave);
			tabNameFilePath[baseName(fileToSave)] = fileToSave;

			textWidget.addTag("tabWidth", "1.0", "end");
			root.generateEvent("<<ResetTitle>>");
		}
	}

	/// Saves the file to the path stored from loading or saving the file previously.
	/// If the path doesn't exist calls openSaveFileDialog().
	public void saveFile(CommandArgs args, NoteBook noteBook, Text[] textWidgetArray) {
		Text textWidget = textWidgetArray[noteBook.getCurrentTabId()];

		if (noteBook.getTabText(noteBook.getCurrentTabId()) == "Main File" || 
			noteBook.getTabText(noteBook.getCurrentTabId()) == "New File") {
			openSaveFileDialog(args, noteBook, textWidgetArray);
		} else {
			fileToSave = tabNameFilePath.get(noteBook.getTabText(noteBook.getCurrentTabId()), "Record does not exist!");
			if (fileToSave == "Record does not exist!") {
				writeln("Save cancelled! Path could not be found!");
			} else {
				writeln("saving: ", fileToSave);
		
				File f = File(fileToSave, "w");

				f.write(textWidget.getText());

				f.close();

				noteBook.setTabText(noteBook.getCurrentTabId(), baseName(fileToSave));
				root.setTitle("File saved: " ~ fileToSave);

				textWidget.addTag("tabWidth", "1.0", "end");
				root.generateEvent("<<ResetTitle>>");
			}
		}
	}
}