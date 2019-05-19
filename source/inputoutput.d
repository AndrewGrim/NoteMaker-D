module inputoutput;

import tkd.tkdapplication;      
import std.stdio;         
import std.file;
import std.string;

// saving and opening methods
class InputOutput {

    // variables
    Window root;
    Text textMain;
    string fileToOpen;
    string fileToSave;

    // constructor
    this(Window root, Text textMain) {
        this.root = root;
        this.textMain = textMain;
    }

    // opens the openFile dialog allowing you to choose the file to load
    public void openOpenFileDialog(CommandArgs args) {
		
		auto openFile = new OpenFileDialog("Open a file")
			.setMultiSelection(false)
			.setDefaultExtension(".txt")
			.addFileType("{{All files} {*}}")
			.addFileType("{{Text files} {.txt}}")
			.setInitialDirectory("~")
			.setInitialFile("file.txt")
			.show();

        fileToOpen = openFile.getResult();
        writeln(fileToOpen);

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

            this.textMain.clear();
            this.textMain.insertText(0, 0, fileContent);

            root.setTitle("File opened: " ~ fileToOpen);
        }
	}	

    // opens the saveFile dialog allowing you to choose where to save
    public void openSaveFileDialog(CommandArgs args) {

		auto saveFile = new SaveFileDialog()
			.setConfirmOverwrite(true)
			.setDefaultExtension(".dmo")
			.addFileType("{{All files} {*}}")
			.setInitialDirectory("~")
			.setInitialFile("note.txt")
			.show();

        fileToSave = saveFile.getResult();
        writeln(fileToSave);

        if (saveFile.getResult() == "") {

            writeln("Save cancelled!");

        } else {

            auto f = File(fileToSave, "w");

            f.write(this.textMain.getText());

            f.close();

            root.setTitle("File saved: " ~ fileToSave);
        }
	}
}