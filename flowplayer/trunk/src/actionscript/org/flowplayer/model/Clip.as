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

package org.flowplayer.model {
    import org.flowplayer.controller.ClipURLResolver;
    import org.flowplayer.controller.ConnectionProvider;
import org.flowplayer.flow_internal;
	import org.flowplayer.model.ClipEvent;
	import org.flowplayer.util.ArrayUtil;
	import org.flowplayer.util.Log;
	import org.flowplayer.util.URLUtil;
	
	import flash.display.DisplayObject;
	import flash.media.Video;
	import flash.utils.Dictionary;		
	
	use namespace flow_internal;		

	/**
	 * @inheritDoc
	 */
	public class Clip extends ClipEventDispatcher {
		private var _playlist:Playlist;
		private var _cuepoints:Dictionary;
		private var _cuepointsInNegative:Array;
//		private var _previousPositives:Array;
		private var _baseUrl:String;
		private var _url:String;
        private var _resolvedUrl:String;
		private var _type:ClipType;
		private var _start:Number;
		private var _duration:Number;
		private var _metaData:Object;
		private var _autoPlay:Boolean = true;
		private var _autoPlayNext:Boolean = false;
		private var _autoBuffering:Boolean;
		private var _scaling:MediaSize;
		private var _accelerated:Boolean;
		private var _smoothing:Boolean;
		private var _content:DisplayObject;
		private var _originalWidth:int;
		private var _originalHeight:int;
		private var _bufferLength:int;
		private var _played:Boolean;
		private var _provider:String;
		private var _customProperties:Object;
		private var _fadeInSpeed:int;
		private var _fadeOutSpeed:int;
		private var _live:Boolean;		
		private var _linkUrl:String;
		private var _linkWindow:String;
		private var _image:Boolean;
		private var _cuepointMultiplier:Number;
        private var _urlResolvers:Array;
        private var _connectionProvider:String;

        public function Clip() {
			_cuepoints = new Dictionary();
			_cuepointsInNegative = new Array();
			_start = 0;
			_bufferLength = 3;
			_scaling = MediaSize.FILLED_TO_AVAILABLE_SPACE;
			_provider = "http";
			_smoothing = true;
			_fadeInSpeed = 1000;
			_fadeOutSpeed = 1000;
			_linkWindow = "_self";
			_image = true;
			_cuepointMultiplier = 1000;
		}

		public static function create(url:String, baseUrl:String = null):Clip {
			return init(new Clip(), url, baseUrl);
		}

		private static function init(clip:Clip, url:String, baseUrl:String = null):Clip {
			clip._url = url;
			clip._baseUrl = baseUrl;
			clip._autoPlay = true;
			return clip;
		}

		public function getPlaylist():Playlist {
			return _playlist;
		}

		public function setPlaylist(playlist:Playlist):void {
			_playlist = playlist;
		}
				
		[Value]
		public function get index():int {
			return _playlist.indexOf(this);
		}
		
		[Value]
		public function get isCommon():Boolean {
            if (! _playlist) return false;
			return this == _playlist.commonClip;
		}

		public function addCuepoints(cuepoints:Array):void {
			for (var i:Number = 0; i < cuepoints.length; i++) {
				addCuepoint(cuepoints[i]);
			}
		}

		public function addCuepoint(cue:Cuepoint):void {
			if (! cue) return;
			if (cue.time >= 0) {
				log.info(this + ": adding cuepoint to time " + cue.time)
				if (!_cuepoints[cue.time]) {
					_cuepoints[cue.time] = new Array();
				}
				// do not add if this same cuepoint *instance* is already there
				if ((_cuepoints[cue.time] as Array).indexOf(cue) >= 0) return;
				
				(_cuepoints[cue.time] as Array).push(cue);
			} else {
				log.info("storing negative cuepoint " + (this == commonClip ? "to common clip" : ""));
                _cuepointsInNegative.push(cue);
//				if (duration > 0) {
//					convertToPositive(cue);
//				} else {
//                    log.info("duration not available yet, storing negative cuepoint to be used when duration is set")
//					_cuepointsInNegative.push(cue);
//				}
			}
		}
		
		private function removeCuepoint(cue:Cuepoint):void {
			var points:Array = _cuepoints[cue.time];
			if (! points) return;
			var index:int = points.indexOf(cue);
			if (index >= 0) {
				log.debug("removing previous negative cuepoint at timeline time " + cue.time);
				points.splice(index, 1);
			}
		}

		public function getCuepoints(time:int, dur:Number = -1):Array {
			var result:Array = new Array();
			result = ArrayUtil.concat(result, _cuepoints[time]);
            result = ArrayUtil.concat(result, getNegativeCuepoints(time, this == commonClip ? dur : this.duration));
            if (this == commonClip) return result;

			result = ArrayUtil.concat(result, commonClip.getCuepoints(time, this.duration));
            if (result.length > 0) {
                log.info("found " + result.length + " cuepoints for time " + time);
            }
			return result;
		}

		private function getNegativeCuepoints(time:int, dur:Number):Array {
            if (dur <= 0) return [];
            var result:Array = new Array();
            for (var i:int = 0; i < _cuepointsInNegative.length; i++) {
                var positive:Cuepoint = convertToPositive(_cuepointsInNegative[i], dur);
                if (positive.time == time) {
                    log.info("found negative cuepoint corresponding to time " + time);
                    result.push(positive);
                }
            }
            return result;
        }
//
//		private function setNegativeCuepointTimes(duration:int):void {
//			log.debug("setNegativeCuepointTimes, transferring " + _cuepointsInNegative.length + " to timeline duration " + duration);
//			_previousPositives.forEach(
//				function(cue:*, index:int, array:Array):void {
//					removeCuepoint(cue as Cuepoint);
//				});
//			_previousPositives = new Array();
//
//			_cuepointsInNegative.forEach(
//				function(cue:*, index:int, array:Array):void {
//					convertToPositive(cue);
//				});
//		}
		
		private function convertToPositive(cue:Cuepoint, dur:Number):Cuepoint {
			var positive:Cuepoint = cue.clone() as Cuepoint; 
			positive.time = Math.round((dur * 1000 - Math.abs(Cuepoint(cue).time))/100) * 100;
			return positive;
		}

		[Value]
		public function get baseUrl():String {
			return _baseUrl;
		}

		public function set baseUrl(baseURL:String):void {
			this._baseUrl = baseURL;
		}

        [Value]
        public function get url():String {
            return _resolvedUrl || _url;
        }

        [Value]
        public function get originalUrl():String {
            return _url;
        }

		public function set url(url:String):void {
			if (_url != url) {
				_metaData = null;
				_content = null;
			}
			this._url = url;
		}

        public function set resolvedUrl(val:String):void {
            _resolvedUrl = val;
        }

		[Value]
		public function get completeUrl():String {
			return URLUtil.completeURL(_baseUrl, url);
		}
		
		public function get type():ClipType {
			if (! _type && _url) {
				_type = ClipType.fromFileExtension(url);
			}
			if (! _type) {
				return ClipType.VIDEO;
			}
			return _type;
		}
		
		[Value(name="type")]
		public function get typeStr():String {
			return type ? type.type : ClipType.VIDEO.type;
		}

		public function setType(type:String):void {
			this._type = ClipType.resolveType(type);
		}
		
		public function set type(type:ClipType):void {
			_type = type;
		}

		[Value]
		public function get start():Number {
			return _start;
		}
		
		public function set start(start:Number):void {
			this._start = start;
		}
		
		public function set duration(value:Number):void {
			this._duration = value;
			log.info("clip duration set to " + value);
//			if (! isCommon) {
//				if (duration >= 0) {
//					setNegativeCuepointTimes(value);
//				}
//				addCommonClipNegativeCuepoints();
//			}
		}
		
//		private function addCommonClipNegativeCuepoints():void {
//			if (commonClip) {
//				log.debug("adding negative cuepoints from commponClip");
//				addCuepoints(commonClip.cuepointsInNegative);
//			} else {
//				log.error("there is no commonClip");
//			}
//		}

		public function get durationFromMetadata():Number {
			if (_metaData)
				return _metaData.duration;
			return 0;
		}
		
		public function set durationFromMetadata(value:Number):void {
			if (! _metaData) {
				_metaData = new Object();
			}
			_metaData.duration = value;
		}

		[Value]
		public function get duration():Number {
			if (_duration > 0) {
				return _duration;
			}
			var metadataDur:Number = durationFromMetadata;
			if (_start > 0 && metadataDur > _start) {
				return metadataDur - _start;
			}
			return metadataDur || 0;
		}

		[Value]
		public function get metaData():Object {
			return _metaData;
		}
		
		public function set metaData(metaData:Object):void {
			this._metaData = metaData;
//			if (! (_duration >= 0) && metaData && metaData.duration) {
//				setNegativeCuepointTimes(metaData.duration);
//				addCommonClipNegativeCuepoints();
//			}
		}
		
		[Value]
		public function get autoPlay():Boolean {
			return _autoPlay;
		}
		
		public function set autoPlay(autoPlay:Boolean):void {
			this._autoPlay = autoPlay;
		}
		
		[Value]
		public function get autoBuffering():Boolean {
			return _autoBuffering;
		}
		
		public function set autoBuffering(autoBuffering:Boolean):void {
			this._autoBuffering = autoBuffering; 
		}
		
		public function setContent(content:DisplayObject):void {
			if (_content && _content is Video && ! content) {
				log.debug("clearing video content");
				Video(_content).clear();
			}
			this._content = content;
		}
		
		public function getContent():DisplayObject {
			return _content;
		}

		public function setScaling(scaling:String):void {
			this._scaling = MediaSize.forName(scaling);
		}
		
		public function set scaling(scaling:MediaSize):void {
			this._scaling = scaling;
		}
		
		public function get scaling():MediaSize {
			return this._scaling;
		}

		[Value(name="scaling")]
		public function get scalingStr():String {
			return this._scaling.value;
		}

		public function toString():String {
			return "[Clip] '" + (provider == "http" ? completeUrl : url) + "'";
		}

		public function set originalWidth(width:int):void {
			this._originalWidth = width;
		}
		
		public function get originalWidth():int {
			if (_type == ClipType.VIDEO) {
				if (_metaData && _metaData.width >= 0) {
					return _metaData.width;
				}
				if (! _content) {
					log.warn("Getting originalWidth from a clip that does not have content loaded yet, returning zero");
					return 0;
				}
				return _content is Video ? (_content as Video).videoWidth : _originalWidth;
			}
			return _originalWidth;
		}

		public function set originalHeight(height:int):void {
			this._originalHeight = height;
		}
		
		public function get originalHeight():int {
			if (_type == ClipType.VIDEO) {
				if (_metaData && _metaData.height >= 0) {
					return _metaData.height;
				}
				if (! _content) {
					log.warn("Getting originalHeight from a clip that does not have content loaded yet, returning zero");
					return 0;
				}
				return _content is Video ? (_content as Video).videoHeight : _originalHeight;
			}
			return _originalHeight;
		}

		public function set width(width:int):void {
			if (! _content) {
				log.warn("Trying to change width of a clip that does not have media content loaded yet");
				return;
			}
			_content.width = width;
		}
		
		[Value]
		public function get width():int {
			return getWidth();
		}
		
		private function getWidth():int {
			if (! _content) {
				log.warn("Getting width from a clip that does not have content loaded yet, returning zero");
				return 0;
			}
			return _content.width;
		}

		public function set height(height:int):void {
			if (! _content) {
				log.warn("Trying to change height of a clip that does not have media content loaded yet");
				return;
			}
			_content.height = height;
		}
		
		[Value]
		public function get height():int {
			return getHeight();
		}
		
		private function getHeight():int {
			if (! _content) {
				log.warn("Getting height from a clip that does not have content loaded yet, returning zero");
				return 0;
			}
			return _content.height;
		}
		
		[Value]
		public function get bufferLength():int {
			return _bufferLength;
		}
		
		public function set bufferLength(bufferLength:int):void {
			_bufferLength = bufferLength;
		}
		
		public function get played():Boolean {
			return _played;
		}
		
		public function set played(played:Boolean):void {
			_played = played;
		}
		
		[Value]
		public function get provider():String {
			if (type == ClipType.AUDIO) return "audio";
			return _provider;
		}
		
		public function set provider(provider:String):void {
			_provider = provider;
		}
		
		[Value]
		public function get cuepoints():Array {
			var cues:Array = new Array();
			for each (var cue:Object in _cuepoints) {
				cues.push(cue);
			}
			return cues;
		}
		
		public function set accelerated(accelerated:Boolean):void {
			_accelerated = accelerated;
		}
		
		[Value]
		public function get accelerated():Boolean {
			return _accelerated;
		}

		public function get isNullClip():Boolean {
			return false;
		}

		// common clip listens to events from the normal clips and redispatches		
		public function onClipEvent(event:ClipEvent):void {
			log.info("received onClipEvent, I am commmon clip: " + (this == _playlist.commonClip));
			doDispatchEvent(event, true);
			log.debug(this + ": dispatched play event with target " + event.target);
		}

		public function onBeforeClipEvent(event:ClipEvent):void {
			log.info("received onBeforeClipEvent, I am commmon clip: " + (this == _playlist.commonClip));
			doDispatchBeforeEvent(event, true);
			log.debug(this + ": dispatched before event with target " + event.target);
		}
		
		private function get commonClip():Clip {
            if (! _playlist) return null;
			return _playlist.commonClip;
		}
		
		[Value]		
		public function get customProperties():Object {
			return _customProperties;
		}
		
		public function set customProperties(props:Object):void {
			_customProperties = props;
			
			// workaraound to not allow setting cuepoints to custom properties
			if (_customProperties && _customProperties["cuepoints"]) {
				delete _customProperties["cuepoints"];
			}
		}
		
		public function get smoothing():Boolean {
			return _smoothing;
		}
		
		public function set smoothing(smoothing:Boolean):void {
			_smoothing = smoothing;
		}
		
		public function getCustomProperty(property:String):Object {
			if (!_customProperties) return null;
			return _customProperties[property];
		}

		public function setCustomProperty(property:String, value:Object):void {
			if (!_customProperties) {
				_customProperties = new Object();
			}
			_customProperties[property] = value;
		}
		
		[Value]				
		public function get fadeInSpeed():int {
			return _fadeInSpeed;
		}
		
		public function set fadeInSpeed(fadeInSpeed:int):void {
			_fadeInSpeed = fadeInSpeed;
		}
		
		[Value]		
		public function get fadeOutSpeed():int {
			return _fadeOutSpeed;
		}
		
		public function set fadeOutSpeed(fadeOutSpeed:int):void {
			_fadeOutSpeed = fadeOutSpeed;
		}
		
		[Value]		
		public function get live():Boolean {
			return _live;
		}
		
		public function set live(live:Boolean):void {
			_live = live;
		}
		
		[Value]		
		public function get linkUrl():String {
			return _linkUrl;
		}
		
		public function set linkUrl(linkUrl:String):void {
			_linkUrl = linkUrl;
		}
		
		[Value]		
		public function get linkWindow():String {
			return _linkWindow;
		}
		
		public function set linkWindow(linkWindow:String):void {
			_linkWindow = linkWindow;
		}
		
		protected function get cuepointsInNegative():Array {
			return _cuepointsInNegative;
		}
		
		/**
		 * Use the previous clip in the playlist as an image for this audio clip?
		 * This is only for audio clips.
		 */
		[Value]
		public function get image():Boolean {
			return _image;
		}
		
		public function set image(image:Boolean):void {
			_image = image;
		}
		
		public function get autoPlayNext():Boolean {
			return _autoPlayNext;
		}
		
		public function set autoPlayNext(autoPlayNext:Boolean):void {
			_autoPlayNext = autoPlayNext;
		}
		
		public function get cuepointMultiplier():Number {
			return _cuepointMultiplier;
		}
		
		public function set cuepointMultiplier(cuepointMultiplier:Number):void {
			_cuepointMultiplier = cuepointMultiplier;
		}
		
		public function dispatchNetStreamEvent(name:String, infoObject:Object):void {
			dispatch(ClipEventType.NETSTREAM_EVENT, name, infoObject);
		}

        public function get connectionProvider():String {
            return _connectionProvider;
        }

        public function set connectionProvider(val:String):void {
            _connectionProvider = val;
        }

        public function get urlResolvers():Array {
            return _urlResolvers;
        }

        public function setUrlResolvers(val:Object):void {
            _urlResolvers = val is Array ? val as Array : [val];
        }
    }
}
