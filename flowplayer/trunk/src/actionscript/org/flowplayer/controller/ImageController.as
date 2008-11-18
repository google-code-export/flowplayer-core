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

		public function ImageController(volumeController:VolumeController, playlist:Playlist) {
			super(volumeController, playlist);
			_loader = new ClipImageLoader(null, onLoadComplete);
		}
		
		override protected function doLoad(event:ClipEvent, clip:Clip, pauseAfterStart:Boolean = false):void {
//			_durationlessClipPaused = false;
			log.info("Starting to load " + clip);
			_loader.loadClip(clip);
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
				dispatchPlayEvent(event);
			}
		}
		
		private function onLoadComplete(event:Event):void {
			log.info("image loaded");
			clip.setContent(ResourceLoader(event.target).getContent() as DisplayObject);
			clip.originalHeight = _loader.getContent().height;
			clip.originalWidth = _loader.getContent().width;
			clip.dispatch(ClipEventType.BUFFER_FULL);
			if (clip.duration == 0) {
				clip.dispatch(ClipEventType.FINISH);
			}
		}
	}
}
