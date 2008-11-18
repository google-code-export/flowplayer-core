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
	import flash.display.Sprite;
	import flash.media.Video;
	
	import org.flowplayer.model.Clip;
	import org.flowplayer.model.ClipEvent;
	import org.flowplayer.model.ClipEventSupport;
	import org.flowplayer.model.ClipType;
	import org.flowplayer.model.Playlist;	

	/**
	 * @author api
	 */
	internal class VideoDisplay extends AbstractSprite {

		private var video:Video;
		private var _overlay:Sprite;

		public function VideoDisplay(clip:Clip) {
			addOrRemoveListeners(clip, clip.getPlaylist());
			createOverlay();
		}
		
		private function createOverlay():void {
			// we need to have an invisible layer on top of the video, otherwise the ContextMenu does not work??
			_overlay = new Sprite();
			addChild(_overlay);
			_overlay.graphics.beginFill(0, 0);
			_overlay.graphics.drawRect(0, 0, 10, 10);
			_overlay.graphics.endFill();
		}

		override protected function onResize():void {
			_overlay.width = width;
			_overlay.height = height;
		}

		private function addOrRemoveListeners(clip:Clip, eventSupport:ClipEventSupport, add:Boolean = true):void {
			if (add) {
				eventSupport.onPlaylistReplace(onPlaylistCahnged);
				clip.onStart(onLoaded);
			} else {
				eventSupport.unbind(onLoaded);
			}
		}

		private function onPlaylistCahnged(event:ClipEvent):void {
			addOrRemoveListeners(null, ClipEventSupport(event.info), false);
		}

		private function onLoaded(event:ClipEvent):void {
			if (video)
				removeChild(video);
			video = Clip(event.target).getContent() as Video;
			video.width = this.width;
			video.height = this.height;
			addChild(video);
			swapChildren(_overlay, video);
		}
		
	}
}
