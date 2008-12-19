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

package org.flowplayer.config {
	import org.flowplayer.flow_internal;
	import org.flowplayer.model.Clip;
	import org.flowplayer.model.Cuepoint;
	import org.flowplayer.model.NullClip;
	import org.flowplayer.model.Playlist;
	import org.flowplayer.util.Log;
	import org.flowplayer.util.PropertyBinder;
	import org.flowplayer.util.URLUtil;	
	
	use namespace flow_internal;

	/**
	 * @author anssi
	 */
	internal class PlaylistBuilder {
		private var log:Log = new Log(this);
		private var clipObjects:Array;
		private var _commonClip:Object;
		private var _playerId:String;

		
		public function PlaylistBuilder(playerId:String, clipObjects:Array, commonClip:Object) {
			_playerId = playerId;
			this.clipObjects = clipObjects || [];
			_commonClip = commonClip;
		}

		public function createClips(clipObjects:Array):Array {
			var clips:Array = new Array();
			for (var i : Number = 0; i < clipObjects.length; i++) {
				var clipObj:Object = clipObjects[i];
				if (clipObj is String) {
					clipObj = { url: clipObj };
				}
				clips.push(createClip(clipObj));
			}
			return clips;
		}

		public function createPlaylist():Playlist {
			var commonClip:Clip;
			if (_commonClip) {
				commonClip = createClip(_commonClip);
			}
			var playList:Playlist = new Playlist(commonClip);
			if (clipObjects && clipObjects.length > 0) {
				playList.setClips(createClips(clipObjects));
			} else if (_commonClip) {
				playList.addClip(createClip(_commonClip));
			}
			
			return playList;
		}
		
		private function setDefaults(clipObj:Object):void {
			if (clipObj == _commonClip) return;
			
			for (var prop:String in _commonClip) {
				if (clipObj[prop] == undefined) {
					clipObj[prop] = _commonClip[prop];
				}
			}
		}

		public function createClip(clipObj:Object):Clip {
			if (! clipObj) return null;
			if (clipObj is String) {
				clipObj = { url: clipObj };
			}
			setDefaults(clipObj);
			var url:String = clipObj.url;
			var baseUrl:String = clipObj.baseUrl;
			var fileName:String = url;
			if (URLUtil.isCompleteURLWithProtocol(url)) {
				var lastSlashIndex:Number = url.lastIndexOf("/");
				baseUrl = url.substring(0, lastSlashIndex);
				fileName = url.substring(lastSlashIndex + 1);
			}
			var clip:Clip = Clip.create(fileName, baseUrl);
			return new PropertyBinder(clip, "customProperties").copyProperties(clipObj) as Clip;
		}
		
		public function createCuepointGroup(cuepoints:Array, callbackId:String, timeMultiplier:Number):Array {
			var cues:Array = new Array();
			for (var i:Number = 0; i < cuepoints.length; i++) {
				var cueObj:Object = cuepoints[i];
				var cue:Object = createCuepoint(cueObj, callbackId, timeMultiplier);
				cues.push(cue);
			}
			return cues;
		}

		private function createCuepoint(cueObj:Object, callbackId:String, timeMultiplier:Number):Object {
			if (cueObj is Number) return new Cuepoint(roundTime(cueObj as int, timeMultiplier), callbackId);
			if (! cueObj.hasOwnProperty("time")) throw new Error("Cuepoint does not have time: " + cueObj);
			var cue:Object = Cuepoint.createDynamic(roundTime(cueObj.time, timeMultiplier), callbackId);
			for (var prop:String in cueObj) {
				if (prop != "time") {
					cue[prop] = cueObj[prop];
				}
//				log.debug("added cynamic property " + prop + ", to value " + cue[prop]);
			}
			return cue;
		}
		
		private function roundTime(time:int, timeMultiplier:Number):int {
			return Math.round(time * timeMultiplier / 100) * 100;
		}
	}
}
