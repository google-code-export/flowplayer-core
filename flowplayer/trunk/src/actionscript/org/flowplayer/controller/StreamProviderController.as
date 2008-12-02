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
	import org.flowplayer.model.ClipType;	
	import org.flowplayer.config.Config;
	import org.flowplayer.controller.AbstractDurationTrackingController;
	import org.flowplayer.controller.MediaController;
	import org.flowplayer.controller.StreamProvider;
	import org.flowplayer.model.Clip;
	import org.flowplayer.model.ClipEvent;
	import org.flowplayer.model.ClipEventType;
	import org.flowplayer.model.Playlist;
	import org.flowplayer.util.Log;

	import flash.display.DisplayObject;		

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

		public function StreamProviderController(controllerFactory:MediaControllerFactory, volumeController:VolumeController, config:Config, playlist:Playlist) {
			super(volumeController, playlist);
			_controllerFactory = controllerFactory;
			_config = config;
			playlist.onBegin(onBegin, function(clip:Clip):Boolean { 				return clip.type == ClipType.VIDEO || clip.type == ClipType.AUDIO; 			}, true);
		}

		private function onBegin(event:ClipEvent):void {
			var clip:Clip = event.target as Clip;
			log.debug("onBegin, initializing content for clip " + clip);
			var video:DisplayObject = clip.getContent();
			if (video) {
				getProvider(clip).attachStream(video);
			} else {
				video = getProvider(clip).getVideo(clip);
				if (video) { 
					getProvider(clip).attachStream(video);
					if (!video) throw new Error("No video object available for clip " + clip);
					clip.setContent(video);
				}
			}
		}

		protected override function doLoad(event:ClipEvent, clip:Clip, pauseAfterStart:Boolean = false):void {
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

		public function onCuePoint(infoObject:Object):void {
		}

		override protected function onDurationReached():void {
			// pause silently
			log.debug("pausing silently");
			getProvider().pause(null);
		}

		public function onMetaData(infoObject:Object):void {
			log.info("onMetaData:");
			if (getProvider(clip).stopping) return;
			if (clip.metaData) {
				clip.dispatch(ClipEventType.START);
				return;
			}

			log.debug("onMetaData, data for clip " + clip + ":");
			var metaData:Object = new Object();
			for (var key:String in infoObject) {
				log.debug(key + ": " + infoObject[key]);
				metaData[key] = infoObject[key];
			}
			clip.metaData = metaData;
			
			if (metaData.cuePoints) {
				log.debug("clip has embedded cuepoints");
				clip.addCuepoints(_config.createCuepoints(metaData.cuePoints, "embedded"));
			}
			
			clip.dispatch(ClipEventType.START);
		}

		public function onXMPData(infoObject:Object):void {
		} 

		public function onBWDone():void { 
		}

		public function onCaption(cps:String,spk:Number):void { 
		}

		public function onCaptionInfo(obj:Object):void { 
		}

		public function onFCSubscribe(obj:Object):void { 
		}		

		public function onLastSecond(infoObject:Object):void {
			log.debug("onLastSecond", infoObject);
		}

		public function onPlayStatus(infoObject:Object):void {
			log.debug("onPlayStatus", infoObject);
		}

		public function onImageData(obj:Object):void { 
		}
		public function RtmpSampleAccess(obj:Object):void { 
		}

		public function onTextData(obj:Object):void { 
		}

		public function getProvider(clipParam:Clip = null):StreamProvider {
			if (!(clipParam || clip)) return null;
			var provider:StreamProvider = _controllerFactory.getProvider(clipParam || clip);
			provider.netStreamClient = this;
			provider.playlist = playlist;
			return provider;
		}
	}
}
