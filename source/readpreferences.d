module readpreferences;

import std.stdio;
import std.string;
import std.file;
import std.conv;

/// Struct for holding preferences that are meant to be read from file.
struct Preferences {

	/// The file path to the preferences file.
	string preferencesFile;

	/// Checks if the preferences file exists. Used to create a new default file if it doesn't.
	bool preferencesFileExists;

	/// The font used by the program. Examples: "Arial 12", "MS ComicSans 14 bold italic underline overstrike".
	string font;

	/// The color of the text. Example: "#ff00ff".
	string foreground;

	/// The color of the background. Example: "#ff00ff".
	string background;

	/// The color of the insert cursor. Example: "#ff00ff".
	string insert;

	/// The decimal number representing the transparency of the program. Example: "0.75".
	float opacity;

	/// The color of the selected text. Example: "#ff00ff".
	string selectionForeground;

	/// The color of the selected texts background. Example: "#ff00ff".
	string selectionBackground;

	/// Whether to save when the modified flags is triggered or not.
	bool saveOnModified;

	/// The path to the user specified shell. 
	/// Otherwise "default" which check the environment variable for user's preferred shell.
	/// If such doesn't exist fallsback to nativeShell() which is "cmd.exe" on Windows and "/bin/sh" on Linux. 
	string shell;

	/// The current syntax color theme. Currently only two are supported. My own one and Gruvbox.
	string syntaxTheme;

	/// The width of the main window. Used to remember the windows size upon closing.
	int width;

	/// The height of the main window. Used to remember the windows size upon closing.
	int height;

	/// Prints all the struct members to the terminal.
	void printPreferences() {
		writeln("font: ", font);
		writeln("foreground: ", foreground);
		writeln("background: ", background);
		writeln("insert: ", insert);
		writeln("opacity: ", opacity);
		writeln("selectionForeground: ", selectionForeground);
		writeln("selectionBackground: ", selectionBackground);
		writeln("saveOnModified: ", saveOnModified);
		writeln("shell: ", shell);
		writeln("syntaxTheme: ", syntaxTheme);
		writeln("width: ", width);
		writeln("height: ", height);
	}
}

/// Function for reading the preferences from file.
/// Returns the struct containing the data.
Preferences readPreferencesFile() {

	Preferences preferences;

	preferences.preferencesFile = getcwd() ~ "/preferences.config";
					
	File f = File(preferences.preferencesFile, "r");

	preferences.preferencesFileExists = true;

	while (!f.eof) {
		const string line = chomp(f.readln());
		switch (line) {
			case "[FONT]":
				preferences.font = chomp(f.readln());
				break;
			case "[FOREGROUND COLOR]":
				preferences.foreground = chomp(f.readln());
				break;
			case "[BACKGROUND COLOR]":
				preferences.background = chomp(f.readln());
				break;
			case "[INSERT CURSOR COLOR]":
				preferences.insert = chomp(f.readln());
				break;
			case "[OPACITY / TRANSPARENCY]":
				preferences.opacity = chomp(f.readln()).to!float;
				break;
			case "[SELECTION FOREGROUND COLOR]":
				preferences.selectionForeground = chomp(f.readln());
				break;
			case "[SELECTION BACKGROUND COLOR]":
				preferences.selectionBackground = chomp(f.readln());
				break;
			case "[SAVE ON MODIFIED]":
				preferences.saveOnModified = chomp(f.readln()).to!bool;
				break;
			case "[SHELL]":
				preferences.shell = chomp(f.readln());
				break;
			case "[SYNTAX THEME]":
				preferences.syntaxTheme = chomp(f.readln());
				break;
			case "[WIDTH]":
				preferences.width = chomp(f.readln()).to!int;
				break;
			case "[HEIGHT]":
				preferences.height = chomp(f.readln()).to!int;
				break;
			default:
				break;
		}
	
	}

	return preferences;
}