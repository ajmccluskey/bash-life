bash-life
=========

Conway's game of life implemented in Bash script

This is a very simple implementation that has only been tested on OSX.  It performs terribly, but I'm not sure how much of that is me, and how much is Bash being slow.  It's probably me. For now, just make sure your terminal window is small when you start it, as it auto-detects your terminal's dimensions at startup and uses that as the board size.  Somewhere around 80x30 isn't too painful.

There are a few starting patterns you can try out; just change the `set_current_state...` function after `init_game_state` at the bottom of the script to some other function, or write your own.

Some possible enhancements, off the top of my head, would be:

* Add an option to wrap the screen, so that patterns moving off screen reappear on the opposite side
* Add command line option choosing start pattern
* Add some simple way to choose a start pattern without modifying the code and specifying it as a big list
* Clean up drawing code
 	+ Rather than using `clear` and drawing anew, draw on the same screen to prevent scrolling
	+ Hide the cursor
* Add some way to exit cleanly
* Check/add compatibility with other environments

License
-------
This code is licensed under the [MIT license](http://opensource.org/licenses/mit-license.php).