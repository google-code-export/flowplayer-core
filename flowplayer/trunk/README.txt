Version history:

RC4
---
- Now shows a "Play again" button at the end of the video/playlist
- Commercial version shows a Flowplayer logo if invalidKey was supplied, but the otherwise the player works
- setting play: null in configuration will disable the play button overlay
- setting opacity for "play" also sets it for the buffering animation
- Fixed firing of cuepoints too early. Cuepoint firing is now based on stream time and does not rely on timers
- added onXMPData event listener
- Should not stop playback too early before the clip is really completed
- The START event is now delayed so that the metadata is available when the event is fired, METADATA event was removed,
  new event BEGIN that is dispatched when the playback has been successfully started. Metadata is not normally
  available when BEGIN is fired. 

RC3
---
- stopBuffering() now dispatches the onStop event first if the player is playing/paused/buffering at the time of calling it
- fixed detection of images based on file extensions
- fixed some issues with having images in the playlist
- made it possible to autoBuffer next video while showing an image (image without a duration)

RC2
---
- fixed: setting the screen height in configuration did not have any effect

RC1
-----
- better error message if plugin loading fails, shows the URL used
- validates our redesigned multidomain license key correctly
- fix to prevent the play button going visible when the onBufferEmpty event occurs
- the commercial swf now correctly loads the controls using version information
- fixed: the play button overlay became invisible with long fadeOutSpeeds

beta6
-----
- removed the onFirstFramePause event
- playing a clip for the second time caused a doubled sound
- pausing on first frame did not work on some FLV files

beta5
-----
- logo only uses percentage scaling if it's a SWF file (there is ".swf" in it's url)
- context menu now correctly builds up from string entries in configuration
-always closes the previous connection before starting a new clip

beta4
-----
- now it's possible to load a plugin into the panel without specifying any position/dimensions
 information, the plugin is placed to left: "50%", top: "50%" and using the plugin DisplayObject's width & height
- The Flowplayer API was not fully initialized when onLoad was invoked on Flash plugins

beta3
-----
- tweaking logo placement
- "play" did not show up after repeated pause/resume
- player now loads the latest controls SWF version, right now the latest SWF is called 'flowplayer.controls-3.0.0-beta2.swf'

beta2
-----
- fixed support for RTMP stream groups
- changed to loop through available fonts in order to find a suitable font also in IE
- Preloader was broken on IE: When the player SWf was in browser's cache it did not initialize properly
- Context menu now correctly handles menu items that are configured by their string labels only (not using json objects)
- fixed custom logo positioning (was moved to the left edge of screen in fullscreen)
- "play" now always follows the position and size of the screen
- video was stretched below the controls in fullscreen when autoHide: 'never'
- logo now takes 6.5% of the screen height, width is scaled so that the aspect ratio is preserved

beta1
-----
- First public beta release
