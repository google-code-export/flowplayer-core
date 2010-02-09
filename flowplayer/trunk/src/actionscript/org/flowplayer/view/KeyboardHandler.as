/*    
 *    Author: Anssi Piirainen, <api@iki.fi>
 *
 *    Copyright (c) 2009 Flowplayer Oy
 *
 *    This file is part of Flowplayer.
 *
 *    Flowplayer is licensed under the GPL v3 license with an
 *    Additional Term, see http://flowplayer.org/license_gpl.html
 */
package org.flowplayer.view {
    import flash.display.Stage;
    import flash.events.KeyboardEvent;

    import flash.ui.Keyboard;

    import flash.utils.Dictionary;

    import org.flowplayer.model.Clip;
    import org.flowplayer.model.PlayerEvent;
    import org.flowplayer.model.Status;
    import org.flowplayer.util.Log;

    public class KeyboardHandler {
        private var log:Log = new Log(this);
        private var _player:Flowplayer;
        private var _handlers:Dictionary = new Dictionary();

        public function KeyboardHandler(stage:Stage, player:Flowplayer, launcher:Launcher) {
            _player = player;

            _handlers[Keyboard.SPACE] =
            function():void {
                player.toggle();
            };

            /*
             * Volume control
             */
            var volumeUp:Function = function():void {
                var volume:Number = _player.volume;
                volume += 10;
                log.debug("setting volume to " + volume);
                _player.volume = volume > 100 ? 100 : volume;
            };
            _handlers[Keyboard.UP] = volumeUp;
            _handlers[75] = volumeUp;

            var volumeDown:Function = function():void {
                log.debug("down");
                var volume:Number = _player.volume;
                volume -= 10;
                log.debug("setting volume to " + volume);
                _player.volume = volume < 0 ? 0 : volume;
            };
            _handlers[Keyboard.DOWN] = volumeDown;
            _handlers[74] = volumeDown;

            _handlers[77] = function():void {
                _player.muted = ! _player.muted; 
            };

            /*
             * Jump seeking
             */
            var jumpseek:Function = function(forwards:Boolean = true):void {
//                if (! _player.isPlaying()) return;
                var status:Status = _player.status;
                if (! status) return;
                var time:Number = status.time;
                var clip:Clip = _player.playlist.current;
                if (! clip) return;

                var targetTime:Number = time + (forwards ? 0.1 : -0.1) * clip.duration;
                if (targetTime < 0) {
                    targetTime = 0;
                }
                if (targetTime > (status.allowRandomSeek ? clip.duration : (status.bufferEnd - clip.bufferLength))) {
                    targetTime = status.allowRandomSeek ? clip.duration : (status.bufferEnd - clip.bufferLength - 5);
                }
                _player.seek(targetTime);
            };
            _handlers[Keyboard.RIGHT] = function():void { jumpseek(); };
            _handlers[76] = _handlers[Keyboard.RIGHT];
            _handlers[Keyboard.LEFT] = function():void { jumpseek(false); };
            _handlers[72] = _handlers[Keyboard.LEFT];


            stage.addEventListener(KeyboardEvent.KEY_DOWN,
                    function(event:KeyboardEvent):void {
                        log.debug("keyDown: " + event.keyCode);
                        if (launcher.enteringFullscreen) return;
						if ( ! _player.isKeyboardShortcutsEnabled() ) return;
                        if (player.dispatchBeforeEvent(PlayerEvent.keyPress(event.keyCode))) {
                            player.dispatchEvent(PlayerEvent.keyPress(event.keyCode));
                            if (_handlers[event.keyCode] != null) {
                                _handlers[event.keyCode]();
                            }
                        }
                    });
        }
    }
}