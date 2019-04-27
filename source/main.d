module main;
import tkd.tkdapplication;      
import std.datetime;
import std.stdio;         
import std.conv;
import std.random;

class Application : TkdApplication {

	private Window root;
	private Text textBody;

	override protected void initInterface() {

		this.root = mainWindow()
			.setTitle("Text Editor");

		auto frameMain = new Frame(root)    
			.pack();
            
        this.textBody = new Text(frameMain)
            .setHeight(50)
            .setWidth(120)
			//.setBackgroundColor("#F0F")
            .pack();


	}	 	
}

void main(string[] args) {
	auto app = new Application();                        
	app.run();                                     
}
