/*    
 *    Copyright 2008 Flowplayer Oy
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
	import org.flowplayer.controller.MediaController;
	import org.flowplayer.flow_internal;
	import org.flowplayer.model.Clip;
	import org.flowplayer.model.ClipEvent;
	import org.flowplayer.model.ClipEventSupport;
	import org.flowplayer.model.ClipType;
	import org.flowplayer.model.MediaSize;
	import org.flowplayer.model.PlayButtonOverlay;
	import org.flowplayer.model.Playlist;
	import org.flowplayer.util.Arrange;
	import org.flowplayer.util.Log;
	
	import flash.display.DisplayObject;
	import flash.geom.Rectangle;
	import flash.utils.Dictionary;	
	
	use namespace flow_internal;

	internal class Screen extends AbstractSprite {

		private var _displayFactory:MediaDisplayFactory;
		private var _displays:Dictionary;
		private var _resizer:ClipResizer;
		private var _playList:Playlist;
		private var _prevClip:Clip;
		private var _fullscreenManaer:FullscreenManager;
		private var _animatioEngine:AnimationEngine;
		private var _play:PlayButtonOverlay;

		public function Screen(playList:Playlist, animationEngine:AnimationEngine, play:PlayButtonOverlay) {
			_displayFactory = new MediaDisplayFactory(playList);
			_resizer = new ClipResizer(playList, this);
			createDisplays(playList);
			addListeners(playList);
			_playList = playList;
			_animatioEngine = animationEngine;
			_play = play;
		}

		private function createDisplays(playList:Playlist):void {
			_displays = new Dictionary();
			var clips:Array = playList.clips;
			for (var i:Number = 0; i < clips.length; i++) {
				var clip:Clip = clips[i];
				createDisplay(clip);
			}
		}

		public function set fullscreenManager(manager:FullscreenManager):void {
			_fullscreenManaer = manager;
		}

		protected override function onResize():void {
			log.debug("arrange");
			_resizer.setMaxSize(width, height);
			// we need to resize the previous clip because it might be the stopped image that we are currently showing
			resizeClip(_playList.previousClip);
			resizeClip(_playList.current);
			arrangePlay();
		}
		
		private function arrangePlay():void {
			if (playView) {
				log.debug("arranging play " + _play.dimensions);
				log.debug("my width is " + width);
				playView.setSize(_play.dimensions.width.toPx(this.width), _play.dimensions.height.toPx(this.height));
				Arrange.center(playView, width, height);
				if (playView.parent == this) {
					setChildIndex(playView, numChildren-1);
				}
			}
		}

		private function get playView():AbstractSprite {
			if (! _play) return null;
			return _play.getDisplayObject() as AbstractSprite;
		}

		private function resizeClip(clip:Clip):void {
			if (! clip) return;
			if (! clip.getContent()) {
				log.warn("clip does not have content, cannot resize. Clip " + clip);
			}
			if (clip && clip.getContent()) {
				var nonHwScaled:MediaSize = clip.scaling == MediaSize.ORIGINAL ? MediaSize.FITTED_PRESERVING_ASPECT_RATIO : clip.scaling; 
				_resizer.resizeClipTo(clip, _fullscreenManaer.isFullscreen && clip.accelerated ? MediaSize.ORIGINAL : nonHwScaled);
			}
		}

		// resized is called when the clip has been resized
		internal function resized(clip:Clip):void {
			var disp:DisplayObject = _displays[clip];
			disp.width = clip.width;
			disp.height = clip.height;
			if (clip.accelerated && _fullscreenManaer.isFullscreen) {
				log.debug("in hardware accelerated fullscreen, will not center the clip");
				disp.x = 0;
				disp.y = 0;
				return;
			}
			Arrange.center(disp, width, height);
			log.debug("screen arranged to " + Arrange.describeBounds(this));
			log.info("display of clip " +clip+ " arranged to  " + Arrange.describeBounds(disp));
		}

		public function getDisplayBounds():Rectangle {
			var clip:Clip = _playList.current;
			var disp:DisplayObject = _displays[clip];
			if (! disp) {
				return fallbackDisplayBounds();
			}
			if (! disp.visible && _prevClip) {
				clip = _prevClip;
				disp = _displays[clip];
			}
			if (! (disp && disp.visible)) {
				return fallbackDisplayBounds();
			}
			if (clip.width > 0) {
				var result:Rectangle = new Rectangle(disp.x, disp.y, clip.width, clip.height);
				log.debug("disp size is " + result.width + " x " + result.height);
				return result;
			} else {
				return fallbackDisplayBounds();
			}
		}
		
		private function fallbackDisplayBounds():Rectangle {
			return new Rectangle(0, 0, stage.stageWidth, stage.stageHeight);
		}

		private function createDisplay(clip:Clip):void {
			var display:DisplayObject = _displayFactory.createMediaDisplay(clip);
			display.width = this.width;
			display.height = this.height;
			display.visible = false;
			addChild(display);
			_displays[clip] = display;
		}

		public function set mediaController(controller:MediaController):void {
		}
		
		private function showDisplay(event:ClipEvent):void {
			log.info("showDisplay()");
			var clipNow:Clip = event.target as Clip;
//			if (clipNow.originalWidth <= 0) {
//				log.debug("no dimensions metadata yet, will not display");
//				return; 
//			}
			if (_prevClip && _prevClip != clipNow) {
				log.debug("hiding previous display");
				setDisplayVisible(_prevClip, false);
				setDisplayVisible(clipNow, true);
			} else {
				if (! _prevClip) {
					setDisplayVisible(clipNow, true);
				}
			}
			_prevClip = clipNow;
			log.info("showDisplay done");
		}

		private function setDisplayVisible(clipNow:Clip, visible:Boolean):void {
			var disp:DisplayObject = _displays[clipNow];
			log.debug("display " + disp + ", will be made " + (visible ? "visible" : "hidden"));
			disp.visible = true;
			if (visible) {
				disp.alpha = 0;
				_animatioEngine.animateProperty(disp, "alpha", 1, clipNow.fadeInSpeed);
//				new FadeInTween(disp, clipNow.fadeInSpeed).start();
				Arrange.center(disp, width, height);
			} else if (disp.visible) {
				_animatioEngine.animateProperty(disp, "alpha", 0, clipNow.fadeOutSpeed);
//				new FadeOutTween(disp, clipNow.fadeOutSpeed).start();
				return;
			}
		}
		
		private function onPlaylistChanged(event:ClipEvent):void {
			log.info("onPlaylistChanged()");
			_prevClip = null;
			removeDisplays(ClipEventSupport(event.info).clips);
			createDisplays(Playlist(event.target));
		}
		
		private function removeDisplays(clips:Array):void {
			for (var i:Number = 0; i < clips.length; i++) {
				removeChild(_displays[clips[i]]);
			}
		}

		private function addListeners(eventSupport:ClipEventSupport):void {
			eventSupport.onPlaylistReplace(onPlaylistChanged);
			
			eventSupport.onBufferFull(showImageDisplay);

			eventSupport.onStart(showDisplayIfNotBufferingOnSplash);
			eventSupport.onMetaData(showDisplayIfNotBufferingOnSplash);
		}

		private function showDisplayIfNotBufferingOnSplash(event:ClipEvent):void {
			var clip:Clip = event.target as Clip;
			log.debug("previous clip " + _prevClip + " clip " + clip);
			if (! clip.autoPlay && clip.autoBuffering && _prevClip && _prevClip.type == ClipType.IMAGE) {
				log.debug("autoBuffering next clip on a splash image, will not show next display");
				clip.onResume(onFirstFrameResume);
				// we are autoBuffering on splash, don't switch display
				return;
			}
			showDisplay(event);
		}
		
		private function onFirstFrameResume(event:ClipEvent):void {
			var clip:Clip = event.target as Clip;
			clip.unbind(onFirstFrameResume);			
			showDisplay(event);
		}

		private function showImageDisplay(event:ClipEvent):void {
			var clipNow:Clip = event.target as Clip;
			if (clipNow.type == ClipType.IMAGE) {
				showDisplay(event);
			}
		}
		
		internal function hidePlay():void {
			if (playView.parent == this) {
				removeChild(playView);
			}
		}
		
		internal function showPlay():void {
			log.debug("showPlay");
			addChild(playView);
			playView.visible = true;
			playView.alpha = _play.alpha;
			arrangePlay();
			log.debug("play bounds: " + Arrange.describeBounds(playView));
			log.debug("play parent: " + playView.parent);
		}	}		
}
