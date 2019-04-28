module main;
import tkd.tkdapplication;      
import std.stdio;         
import std.conv;

class Application : TkdApplication {

	private Window root;
	private Text textBody;

	override protected void initInterface() {

		this.root = mainWindow()
			.setTitle("Text Editor")
			.setOpacity(0.75);

		auto frameMain = new Frame(root)    
			.pack();
            
        this.textBody = new Text(frameMain)
            .setHeight(50)
            .setWidth(120)
			.appendText("aaaaaaaaaaaaAAAAAAAAAAAAAAA")
			.setFont("Helvetica", 12)
			.setForegroundColor("#00ff00")
			.setBackgroundColor("#000000")
            .pack();


	}	 	
}

void main(string[] args) {
	auto app = new Application();                        
	app.run();                                     
}
