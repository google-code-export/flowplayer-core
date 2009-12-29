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

package org.flowplayer.controller {
	import org.flowplayer.config.Config;
	import org.flowplayer.controller.AbstractDurationTrackingController;
	import org.flowplayer.controller.MediaController;
	import org.flowplayer.controller.StreamProvider;
	import org.flowplayer.model.Clip;
	import org.flowplayer.model.ClipEvent;
	import org.flowplayer.model.ClipEventType;
	import org.flowplayer.model.ClipType;
	import org.flowplayer.model.Playlist;
	import org.flowplayer.util.Log;
	
	import flash.display.DisplayObject;
	import flash.media.Video;		

	/**
	 * Video controller is responsible for loading and showing video.
	 * It's also responsible for scaling and resizing the video screen.
	 * It receives the cuePoints and metaData from the loaded video data.
	 * 
	 * @author anssi
	 */
	internal class StreamProviderController extends AbstractDurationTrackingController implements MediaController {
		private var _config:Config;
		private var _controllerFactory:MediaControllerFactory;
//		private var _metadataDispatched:Boolean;

		public function StreamProviderController(controllerFactory:MediaControllerFactory, volumeController:VolumeController, config:Config, playlist:Playlist) {
			super(volumeController, playlist);
			_controllerFactory = controllerFactory;
			_config = config;
			var filter:Function = function(clip:Clip):Boolean { 
				return clip.type == ClipType.VIDEO || clip.type == ClipType.AUDIO; 
			};
			playlist.onBegin(onBegin, filter, true);
			playlist.onBufferFull(onBegin, filter, true);
			playlist.onStart(onBegin, filter, true);
		}

		private function onBegin(event:ClipEvent):void {
			var clip:Clip = event.target as Clip;
			log.info("onBegin, initializing content for clip " + clip);
			var video:DisplayObject = clip.getContent();
			if (video && video is Video) {
				getProvider(clip).attachStream(video);
			} else {
				video = getProvider(clip).getVideo(clip);
				if (video && video is Video) { 
					getProvider(clip).attachStream(video);
					if (!video) throw new Error("No video object available for clip " + clip);
					clip.setContent(video);
				}
			}
		}

		protected override function doLoad(event:ClipEvent, clip:Clip, pauseAfterStart:Boolean = false):void {
//			_metadataDispatched = false;
			getProvider().load(event, clip, pauseAfterStart);
		}

		protected override function doPause(event:ClipEvent):void {
			getProvider().pause(event);
		}

		protected override function doResume(event:ClipEvent):void {
			getProvider().resume(event);
		}

		protected override function doStop(event:ClipEvent, closeStream:Boolean):void {
			getProvider().stop(event, closeStream);
		}

		protected override function doStopBuffering():void {
			getProvider().stopBuffering();
		}

		protected override function doSeekTo(event:ClipEvent, seconds:Number):void {
			durationTracker.time = seconds;
			getProvider().seek(event, seconds);
		}

        override protected function doSwitchStream(event:ClipEvent):void {
          
            var provider:StreamProvider = getProvider();
            var clip:Clip = event.target as Clip;
         	var currentTime:Number = provider.netStream.time;
         
            switch (provider.type) {
        		case ProviderTypes.HTTP: 
        	    	provider.load(event, clip);
        	    	
        	    break;
        	 	case ProviderTypes.PSEUDO:     	 			
        	 		clip.onMetaData(function(event:ClipEvent):void {
        	 			provider.seek(event,currentTime);
        	 		});
        	 		provider.load(event, clip);	
        	 	break;
        	 	case ProviderTypes.RTMP:
        	 		provider.netStream.close();
					provider.netStream.play(clip.url);
					provider.netStream.seek(currentTime);
        	 	break;
        	}
            
            
        }

		public override function get time():Number {
			return getProvider().time;
		}

		protected override function get bufferStart():Number {
			return getProvider().bufferStart;
		}

		protected override function get bufferEnd():Number {
			return getProvider().bufferEnd;
		}

		protected override function get fileSize():Number {
			return getProvider().fileSize;
		}

		protected override function get allowRandomSeek():Boolean {
			return getProvider().allowRandomSeek;
		}

		override protected function onDurationReached():void {
			// pause silently
			log.debug("pausing silently");
			getProvider().pause(null);
		}

		public function getProvider(clipParam:Clip = null):StreamProvider {
			if (!(clipParam || clip)) return null;
			var provider:StreamProvider = _controllerFactory.getProvider(clipParam || clip);
			provider.playlist = playlist;
			return provider;
		}
    }
}
