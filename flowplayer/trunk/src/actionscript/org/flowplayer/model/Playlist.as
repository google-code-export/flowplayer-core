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

package org.flowplayer.model {
	import org.flowplayer.flow_internal;
	import org.flowplayer.model.ClipEvent;		
	
			
	
	
	
			

	use namespace flow_internal;
	/**
	 * @author anssi
	 */
	public class Playlist extends ClipEventSupport {

		private var currentPos:Number;
		private var _commonClip:Clip;
		private var _clips:Array;

		public function Playlist(commonClip:Clip) {
			if (commonClip == null) {
				commonClip = new NullClip();
			}
			super(commonClip);
			_commonClip = commonClip;
			_commonClip.setPlaylist(this);
			initialize();		
		}
		
		private function initialize(newClips:Array = null):void {
			_clips = new Array();
			if (newClips) {
				for (var i:Number = 0; i < newClips.length; i++) {
					addClip(newClips[i]);
				}
			}
			super.setClips(_clips);
			currentPos = 0;
		}

		// doc: PlayEventType.PLAYLIST_CHANGED

		/**
		 * Discards all clips and adds the specified clip to the list.
		 */
		public function replaceClips(clip:Clip):void {
			doReplace([clip]);
		}

		/**
		 * Discards all clips and addes the specified clips to the list.
		 */
		public function replaceClips2(clips:Array):void {
			doReplace(clips);
		}
		
		private function doReplace(newClips:Array):void {
			var oldClipsEventHelper:ClipEventSupport = new ClipEventSupport(_commonClip, _clips);
			initialize(newClips);			
			doDispatchEvent(new ClipEvent(ClipEventType.PLAYLIST_REPLACE, oldClipsEventHelper), true);
		}

		public function addClip(clip:Clip):void {
			_clips.push(clip);
			clip.setPlaylist(this);
			if (clip != _commonClip) {
				clip.onAll(_commonClip.onClipEvent);
				log.info("adding listener to all before events, common clip listens to other clips");
				clip.onBeforeAll(_commonClip.onBeforeClipEvent);
			}
		}
		
		/**
		 * Gets the clip with the specified index.
		 * @param index of the clip to retrieve, if -1 returns the common clip
		 */
		public function getClip(index:Number):Clip {
			if (index == -1) return _commonClip;
			if (_clips.length == 0) return new NullClip();
			return _clips[index];
		}
		
		public function get length():Number {
			return _clips.length;
		}
				
		public function hasNext():Boolean {
			return currentPos < length - 1; 
		}
		
		public function hasPrevious():Boolean {
			return currentPos > 0;
		}

		public function get current():Clip {
			if (_clips.length == 0) return new NullClip();
			return _clips[currentPos];
		}
	
		public function set current(clip:Clip):void {
			toIndex(indexOf(clip));
		}
	
		public function get currentIndex():Number {
			return currentPos;
		}
		
		public function next():Clip {
			trace("PlayList.next(), current index = " + currentPos);
			if (currentPos == _clips.length -1) return null;
			var clip:Clip = _clips[++currentPos];
			return clip;
		}

		public function get nextClip():Clip {
			if (currentPos == _clips.length -1) return null;
			return _clips[currentPos + 1];
		}
		
		public function get previousClip():Clip {
			if (currentPos == 0) return null;
			return _clips[currentPos - 1];
		}
		
		public function previous():Clip {
			trace("PlayList.prev(), current index = " + currentPos);
			if (currentPos == 0) return null;
			return _clips[--currentPos];
		}

		public function toIndex(index:Number):Clip {
			if (index < 0) return null;
			if (index >= _clips.length) return null;
			var clip:Clip = _clips[index];
			if (index == currentPos) return clip;
			currentPos = index;
			return clip;
		}
		
		public function indexOf(clip:Clip):Number {
			for (var i : Number = 0; i < _clips.length; i++) {
				if (_clips[i] == clip) return i;
			}
			return -1;
		}

		public function toString():String {
			return "[playList] length " + _clips.length + ", clips " + _clips; 
		}
		
		public function get commonClip():Clip {
			return _commonClip;
		}
	}
}
