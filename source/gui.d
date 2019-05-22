module gui;

import tkd.tkdapplication;      
import std.stdio;         
import std.conv;
import std.file;
import std.string;
import std.exception;

// gui setup
class Gui {

    // variables
    Window root;
    Text textMain;
    Scale opacitySlider;
    string preferencesFile;
    bool preferencesFileExists;
    string[5] preferencesArray;
    string font, foreground, background, insert;
    string opacity = "1.0";

    // constructor
    this(Window root) {
        this.root = root;
    }

    // creates the main pane for the "noteBook"
    public Frame createMainPane() {
        
        // the main frame that gets returned to be used by the "noteBook"
        auto frameMain = new Frame(root);

            // the frame containing all the widgets
            auto container = new Frame(frameMain)
                .pack(0, 0, GeometrySide.top, GeometryFill.both, AnchorPosition.center, true);

                // tries to read options from the "preferences.txt" file, if it fails the file is created with default values
                try {
                    preferencesFile = getcwd() ~ "/preferences.txt";
                    
                    auto f = File(preferencesFile, "r");

                    preferencesFileExists = true;

                    int iteration;

                    // reading from file and adding each line into the "preferencesArray"
                    while (!f.eof()) {
                        string line = chomp(f.readln());
                        preferencesArray[iteration] = line;
                        iteration++;
                    }

                    // spliting array values into aptly named variables
                    font = preferencesArray[0];
                    foreground = preferencesArray[1];
                    background = preferencesArray[2];
                    insert = preferencesArray[3];
                    opacity = preferencesArray[4];

                } catch (ErrnoException error) {
                    // when the preferences files is not found it is created with default values
                    preferencesFileExists = false;

                    auto f = File(preferencesFile, "w");
                    f.write("Helvetica\n#000000\n#ffffff\n#000000\n1.0");
                    f.close();

                    writeln("Failed to read preferences file! Preferences file created!");
                }

                // creates the "textMain" widget and sets the options if the "preferences.txt" file exists
                this.textMain = new Text(container)
                    .setHeight(5)
                    .setWidth(40)
                    .pack(0, 0, GeometrySide.left, GeometryFill.both, AnchorPosition.center, true);
                    // tries to read in the values from file
                    try {
                        textMain
                            .setFont(font)
                            .setForegroundColor(foreground)
                            .setBackgroundColor(background)
                            .setInsertColor(insert);
                    } catch (ErrnoException error) {
                        writeln("Custom text widget options couldn't be set!");
                    }

                // creates the vertical "yscroll" widget for use with "textMain"
                auto yscroll = new YScrollBar(container)
                    .attachWidget(textMain)
                    .pack(0, 0, GeometrySide.right, GeometryFill.both, AnchorPosition.center, false);

                // creates the scale "opacitySlider" for changing the opacity/alpha setting
                this.opacitySlider = new Scale()
                    .setFromValue(0.2)
                    .setToValue(1.0)
                    .pack(0, 0, GeometrySide.bottom, GeometryFill.x, AnchorPosition.center, false);
                    // tries to read values from file
                    try {
                        opacitySlider.setValue(opacity.to!float);
                    } catch (ErrnoException error) {
                        writeln("Custom opacity couldn't be set!");
                    } catch (ConvException convError) {
                        writeln("Couldn't convert opacity string to float!");
                    }

        return frameMain;
    }
}