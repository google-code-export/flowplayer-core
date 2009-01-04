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

package org.flowplayer.controller {
	import org.flowplayer.model.Playlist;	
	
	import flash.display.DisplayObject;
	import flash.events.Event;
	import flash.events.EventDispatcher;
	
	import org.flowplayer.controller.AbstractDurationTrackingController;
	import org.flowplayer.controller.MediaController;
	import org.flowplayer.model.Clip;
	import org.flowplayer.model.ClipEvent;
	import org.flowplayer.model.ClipEventType;
	import org.flowplayer.util.Log;	

	/**
	 * @author api
	 */
	internal class ImageController extends AbstractDurationTrackingController implements MediaController {

		private var _loader:ClipImageLoader;
//		private var _durationlessClipPaused:Boolean;

		public function ImageController(loader:ResourceLoader, volumeController:VolumeController, playlist:Playlist) {
			super(volumeController, playlist);
			_loader = new ClipImageLoader(loader, null);
		}

		override protected function get allowRandomSeek():Boolean {
			return true;
		}
		
		override protected function doLoad(event:ClipEvent, clip:Clip, pauseAfterStart:Boolean = false):void {
//			_durationlessClipPaused = false;
			log.info("Starting to load " + clip);
			_loader.loadClip(clip, onLoadComplete);
			dispatchPlayEvent(event);
		}
		
		override protected function doPause(event:ClipEvent):void {
			dispatchPlayEvent(event);
		}
		
		override protected function doResume(event:ClipEvent):void {
			dispatchPlayEvent(event);
		}
		
		override protected function doStop(event:ClipEvent, closeStream:Boolean):void {
			dispatchPlayEvent(event);
		}
		
		override protected function doSeekTo(event:ClipEvent, seconds:Number):void {
			if (event) {
				dispatchPlayEvent(new ClipEvent(ClipEventType.SEEK, seconds));
			}
		}
		
		private function onLoadComplete(loader:ClipImageLoader):void {
			clip.setContent(loader.getContent() as DisplayObject);
			clip.originalHeight = loader.getContent().height;
			clip.originalWidth = loader.getContent().width;
			log.info("image loaded " + clip + ", content " + loader.getContent() + ", width " + clip.originalWidth + ", height " + clip.originalHeight);
			clip.dispatch(ClipEventType.BUFFER_FULL);
			if (clip.duration == 0) {
				clip.dispatchBeforeEvent(new ClipEvent(ClipEventType.FINISH));
			}
		}
	}
}
