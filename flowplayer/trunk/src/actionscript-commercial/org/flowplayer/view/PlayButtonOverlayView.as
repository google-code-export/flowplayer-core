
/*
 *    Copyright (c) 2008, 2009 Flowplayer Oy
 *
 *    This file is part of Flowplayer.
 *
 *    Flowplayer is free software: you can redistribute it and/or modify
 *    it under the terms of the GNU General Public License as published by
 *    the Free Software Foundation, either version 3 of the License, or
 *    (at your option) any later version.
 *
 *    Flowplayer is distributed in the hope that it will be useful,
 *    but WITHOUT ANY WARRANTY; without even the implied warranty of
 *    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *    GNU General Public License for more details.
 *
 *    You should have received a copy of the GNU General Public License
 *    along with Flowplayer.  If not, see <http://www.gnu.org/licenses/>.
 */

package org.flowplayer.view {
	import org.flowplayer.controller.ResourceLoader;
    import org.flowplayer.model.Clip;
import org.flowplayer.model.ClipEvent;
	import org.flowplayer.model.ClipEventSupport;
	import org.flowplayer.model.DisplayPluginModel;
	import org.flowplayer.model.DisplayProperties;
	import org.flowplayer.model.PlayButtonOverlay;
	import org.flowplayer.model.Playlist;
	import org.flowplayer.model.Plugin;
	import org.flowplayer.model.PluginEventType;
	import org.flowplayer.model.PluginModel;
	import org.flowplayer.model.State;
	import org.flowplayer.util.Arrange;
	import org.flowplayer.view.AbstractSprite;
	
	import flash.display.DisplayObject;
	import flash.display.Sprite;
	import flash.events.MouseEvent;
	import flash.events.TimerEvent;
	import flash.utils.Timer;		

	/**
	 * @author api
	 */
	public class PlayButtonOverlayView extends AbstractSprite implements Plugin {
		
		private var _button:DisplayObject;
		private var _pluginRegistry:PluginRegistry;

		private var _player:Flowplayer;
		private var _showButtonInitially:Boolean;
		private var _tween:Animation;
		private var _resizeToTextWidth:Boolean;
		private var _screen:Screen;
		private var _playlist:Playlist;
		private var _origAlpha:Number;
		private var _play:PlayButtonOverlay;
        private var _rotation:RotatingAnimation;

		public function PlayButtonOverlayView(resizeToTextWidth:Boolean, play:PlayButtonOverlay, pluginRegistry:PluginRegistry) {
			_resizeToTextWidth = resizeToTextWidth;
			_pluginRegistry = pluginRegistry;
			_pluginRegistry.registerDisplayPlugin(play, this);
			_play = play;
			createChildren();
			buttonMode = true;
			
            startBuffering();
			
			addEventListener(MouseEvent.MOUSE_OVER, onMouseOver);
			addEventListener(MouseEvent.MOUSE_OUT, onMouseOut);
		}

        public function set playlist(playlist:Playlist):void {
            _playlist = playlist;
            addListeners(playlist);            
        }
		

		[External]
		public function set label(label:String):void {
			if (! _player) return;
			log.debug("set label '" + label + "'");
			if (label && (! _button || ! (_button is LabelPlayButton))) {
				log.debug("switching to label button ");
				switchButton(new LabelPlayButton(_player, label));
			}
			if (! label && (! _button || (_button is LabelPlayButton))) {
				switchButton(new PlayOverlay());
			}
			if (label) {
				LabelPlayButton(_button).setLabel(label, _resizeToTextWidth);
			}
			onResize();
		}
		
		override public function set alpha(value:Number):void {
			log.debug("setting alpha to " + value + " tween " + _tween);
			super.alpha = value;
			if (_button) {
				_button.alpha = value;
			}
			_rotation.alpha = value;
		}

		private function switchButton(newButton:DisplayObject):void {
			removeChildIfAdded(_button);
			_button = newButton;
			addButton();
		}

		private function onMouseOut(event:MouseEvent = null):void {
			if (!_button) return;
			_button.alpha = Math.max(0, model.alpha - 0.3);
		}

		private function onMouseOver(event:MouseEvent):void {
			if (!_button) return;
			_button.alpha = model.alpha;
		}

		public function onLoad(player:Flowplayer):void {
			log.debug("onLoad");
			// we need the player to be as the ErrorHandler before loading the image file
			_player = player;

			if (_play.label && _showButtonInitially) {
				showButton(null, _play.label);
			}
			
			CONFIG::commercialVersion {
				if (useCustomImage()) {
					loadImage(_play.url);
				} else {
					log.debug("dispatching complete");
					_play.dispatch(PluginEventType.LOAD);
			}
			}
			CONFIG::freeVersion {
				log.debug("dispatching complete");
				_play.dispatch(PluginEventType.LOAD);
			}
		}
		
		CONFIG::commercialVersion
		private function useCustomImage():Boolean {
			return _play.url && ! _play.label;
		}

		private function addListeners(eventSupport:ClipEventSupport):void {
			eventSupport.onConnect(showButton);
			eventSupport.onConnect(startBuffering);

            // onBegin is here because onBeforeBegin is not dispatched when playing after a timed out and invalid netConnection
            eventSupport.onBegin(hideButton);
            
            eventSupport.onBeforeBegin(hideButton);
			eventSupport.onBeforeBegin(startBuffering);
			
			eventSupport.onResume(hide);

			// onPause: call stopBuffering first and then showButton (stopBuffering hides the button)
			eventSupport.onPause(stopBuffering);
			eventSupport.onPause(showButton);

			eventSupport.onStop(stopBuffering);
			eventSupport.onStop(showButton, isParentClip);
			
			// onBeforeFinish: call stopBuffering first and then showButton (stopBuffering hides the button)
			eventSupport.onBeforeFinish(stopBuffering);
			eventSupport.onBeforeFinish(showReplayButton, isParentClipOrPostroll);
			
			eventSupport.onBufferEmpty(startBuffering);
			eventSupport.onBufferFull(stopBuffering);
			
			eventSupport.onBeforeSeek(startBuffering);
			eventSupport.onSeek(stopBuffering);
			
			eventSupport.onBufferStop(stopBuffering);
			eventSupport.onBufferStop(showButton);
		}

        private function isParentClip(clip:Clip):Boolean {
            return ! clip.isInStream;
        }

        private function isParentClipOrPostroll(clip:Clip):Boolean {
            return clip.isPostroll || ! clip.isInStream;
        }

		private function rotate(event:TimerEvent):void {
			_rotation.rotation += 10;
		}
		
		private function createChildren():void {			
			_rotation = new RotatingAnimation();
            addChild(_rotation);
			createButton();
		}
		
		CONFIG::commercialVersion
		private function createButton():void {
			if (! _play.label && ! _play.url) {
				createStandardPlayButton();
			}
		}

		CONFIG::freeVersion
		private function createButton():void {
			if (! _play.label) {
				createStandardPlayButton();
			}
		}
		
		private function createStandardPlayButton():void {
			_button = new PlayOverlay();
			addButton();
			onResize();
		}
		
		private function addButton():void {
			log.debug("addButton");
			if (model.visible) {
				addChild(_button);
			}
		}

		CONFIG::commercialVersion
		private function loadImage(url:String):void {
			log.debug("loading a custom button image from url " + url);
			_player.createLoader().load(url, onLoadComplete);
		}
		
		CONFIG::commercialVersion
		private function onLoadComplete(loader:ResourceLoader):void {
			_button = loader.getContent() as DisplayObject;
			_button.alpha = model.alpha;
			log.debug("loaded image " + _play.url);
			if (_showButtonInitially) {
				showButton();
			}
			onResize();
			_play.dispatch(PluginEventType.LOAD);
		}

		protected override function onResize():void {
			log.debug("onResise " + width);
			if (! _button) return;
			onMouseOut();
			if (_button is LabelPlayButton) {
				AbstractSprite(_button).setSize(width - 15, height - 15);
			} else {
				_button.height = height;
				_button.scaleX = _button.scaleY;
			}
			_rotation.setSize(width, height);
			
			Arrange.center(_button, width, height);
			log.debug("arranged to y " + _button.y + ", this height " + height + ", screen height " + (_screen ? _screen.height : 0));
		}

		private function hide(event:ClipEvent = null):void {
			log.debug("hide()");
			if (! this.parent) return;
			if (_player) {
				log.debug("fading out with speed " + _play.fadeSpeed + " current alpha is " + alpha);
//				_screen.hidePlay();
				_origAlpha = model.alpha;
				_tween = _player.animationEngine.fadeOut(_button, _play.fadeSpeed, onFadeOut, false);
			} else {
				onFadeOut();
			}
		}
		
		private function onFadeOut():void {
			restoreOriginalAlpha();
			if (_tween && _tween.canceled) {
				_tween = null;
				return;
			}
			_tween = null;
			log.debug("removing button");
			
			removeChildIfAdded(_button);
//			_screen.hidePlay();
		}
		
		private function show():void {
			if (_tween) {
				restoreOriginalAlpha();
				log.debug("canceling fadeOut tween");
				_tween.cancel();
			}
			
			if (_screen && this.parent == _screen) {
				_screen.arrangePlay();
				return;
			}
			
			if (_screen) {
				log.debug("calling screen.showPlay");
				_screen.showPlay();
			}
		}
		
		private function restoreOriginalAlpha():void {
			alpha = _origAlpha;
			var play:DisplayProperties = model;
			play.alpha = _origAlpha;
			_pluginRegistry.updateDisplayProperties(play);
		}

		public function showButton(event:ClipEvent = null, label:String = null):void {
			log.debug("showButton(), label " + label);
			
			// we only support labels if a custom button is not defined
			CONFIG::commercialVersion {
				if (! _play.url) {
					this.label = label || _play.label;
				}
			}
			CONFIG::freeVersion {
				this.label = label || _play.label;
			}
			
			if (! _button) return;
			if (_rotation.parent == this) return;
			
			if (event == null) {
				// not called based on event --> update display props
			
				var props:DisplayProperties = model;
				props.display = "block";
				_pluginRegistry.updateDisplayProperties(props);
			}
			
			addButton();
			show();
			onResize();
		}
		
		public function showReplayButton(event:ClipEvent = null):void {
            
			log.info("showReplayButton, playlist has more clips " + _playlist.hasNext(false));
			if (event.isDefaultPrevented() && _playlist.hasNext(false)) {
				// default prevented, will stop after current clip. Show replay button.
				log.debug("showing replay button");
				showButton(null, _play.replayLabel);
				return; 
			}
            if (_playlist.hasNext(false) && _playlist.nextClip.autoPlay) {
                return;
            }
			showButton(event, _playlist.hasNext(false) ? null:  _play.replayLabel);
		}
		
		public function hideButton(event:ClipEvent = null):void {
			log.debug("hideButton() " + _button);
			removeChildIfAdded(_button);
		}
		
		public function startBuffering(event:ClipEvent = null):void {
			log.debug("startBuffering()");
            if (event && event.isDefaultPrevented()) return;
			if (!_play.buffering) return;

//			if (_button && _button.parent == this) {
//				// already showing button, don't show buffering
//				return;
//			}
			addChild(_rotation);
			show();
			_rotation.start();
		}
		
		public function stopBuffering(event:ClipEvent = null):void {
			log.debug("stopBuffering()");
			_rotation.stop();
			removeChildIfAdded(_rotation);
			if (! _tween && _player.state == State.BUFFERING || _player.state == State.BUFFERING) {
				removeChildIfAdded(_button);
			}
		}

		private function removeChildIfAdded(child:DisplayObject):void {
			if (! child) return;
			if (child.parent != this) return;
			log.debug("removing child " + child);
			removeChild(child);
		}
		
		public function onConfig(configProps:PluginModel):void {
		}
		
		public function getDefaultConfig():Object {
			return null;
		}
		
		public function setScreen(screen:Screen, showInitially:Boolean = false):void {
			_screen = screen;
			_showButtonInitially = showInitially;
			if (showInitially) {
				showButton();
			}
			startBuffering();
		}
		
		private function get model():DisplayPluginModel {
			return DisplayPluginModel(_pluginRegistry.getPlugin("play"));
		}
	}
}
