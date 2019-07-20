module readpreferences;

import std.stdio;
import std.string;
import std.file;
import std.conv;

// struct for holding preferences that are meant to be read from file
struct Preferences {
	string preferencesFile;
	bool preferencesFileExists;
	string font;
	string foreground;
	string background;
	string insert;
	float opacity;
	string selectionForeground;
	string selectionBackground;
	bool saveOnModified;
	string shell;
	string syntaxTheme;
	int width;
	int height;

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

// function for reading the preferences from file
// returns the struct containing the data
Preferences readPreferencesFile() {

	Preferences preferences;

	preferences.preferencesFile = getcwd() ~ "/preferences.config";
					
	auto f = File(preferences.preferencesFile, "r");

	preferences.preferencesFileExists = true;

	while (!f.eof) {
		string line = chomp(f.readln());
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