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
	import org.flowplayer.flow_internal;
	import org.flowplayer.model.ClipEvent;
    import org.flowplayer.util.ObjectConverter;
	
			
	
	
	
			

	use namespace flow_internal;
	/**
	 * @author anssi
	 */
	public class Playlist extends ClipEventSupport {

		private var _currentPos:Number;
        private var _inStreamClip:Clip;
		private var _commonClip:Clip;
		private var _clips:Array;

		public function Playlist(commonClip:Clip = null) {
			if (commonClip == null) {
				commonClip = new NullClip();
			}
			super(commonClip);
			_commonClip = commonClip;
			_commonClip.setParentPlaylist(this);
			initialize();		
		}
		
		private function initialize(newClips:Array = null):void {			
			_clips = new Array();
            _inStreamClip = null;
			if (newClips) {
				for (var i:Number = 0; i < newClips.length; i++) {
					doAddClip(newClips[i]);
				}
			}
			super.setClips(_clips);
			_currentPos = 0;
            log.debug("initialized, current clip is " + current);
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

		override flow_internal function setClips(clips:Array):void {
			for (var i:Number = 0; i < clips.length; i++) {
				doAddClip(clips[i]);
			}
			super.setClips(_clips);
		}
		
		private function doReplace(newClips:Array, silent:Boolean = false):void {
			var oldClipsEventHelper:ClipEventSupport = new ClipEventSupport(_commonClip, _clips);
			initialize(newClips);
            if (! silent) {
                doDispatchEvent(new ClipEvent(ClipEventType.PLAYLIST_REPLACE, oldClipsEventHelper), true);
            }
		}


        /**
         * Adds a new clip into the playlist. Insertion of clips does not change the current clip.
         * @param clip
         * @param index optional insertion point, if not given the clip is added to the end of the list.
         */
        public function addClip(clip:Clip, index:int = -1, addAsChild:Boolean = false):void {
            if (addAsChild) {
                addChildClip(clip, index);
                return;
            }
            log.debug("current clip " + current);
            if (current.isNullClip || current == commonClip) {
                log.debug("replacing common/null clip");
                // we only have the common clip or a common clip, perform a playlist replace!
                doReplace([clip], true);
            } else {
                doAddClip(clip, index);
                if (index >= 0 && index <= _currentPos && hasNext()) {
                    log.debug("moving current pos one up");
                    _currentPos++;
                }
                super.setClips(_clips);
            }
            doDispatchEvent(new ClipEvent(ClipEventType.CLIP_ADD, index >= 0 ? index : _clips.length - 1), true);
        }

        /**
         * Removes the specified child clip.
         * @param clip
         * @return
         */
        public function removeChildClip(clip:Clip):void {
            clip.parent.removeChild(clip);
        }

        private function addChildClip(clip:Clip, index:int):void {
            if (index == -1) {
                index = _clips.length - 1;
            }
            var parent:Clip = getClip(index);
            parent.addChild(clip);
            if (clip.position == 0) {
                _clips.splice(index, 0, clip);
            } else if (clip.position == -1) {
                _clips.splice(index + 1, 0, clip);
            }
            clip.setParentPlaylist(this);
            clip.setEventListeners(this);
            doDispatchEvent(new ClipEvent(ClipEventType.CLIP_ADD, index, clip), true);
        }

		private function doAddClip(clip:Clip, index:int = -1):void {
            log.debug("addClip " + clip);
            clip.setParentPlaylist(this);
            if (index == -1) {
                _clips.push(clip);
            } else {
                _clips.splice(index, 0, clip);
            }
            if (clip.preroll) {
                addChildClip(clip.preroll, index);
            }
            if (clip.postroll) {
                addChildClip(clip.postroll, index);
            }
            log.debug("clips now " + _clips);

			if (clip != _commonClip) {
                clip.onAll(_commonClip.onClipEvent);
                log.error("adding listener to all before events, common clip listens to other clips");
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
            log.debug("hasNext(): " + (_inStreamClip ? "currently in instream clip" : "currentPos " + _currentPos));
            if (_inStreamClip && _inStreamClip.position == 0) {
                return true;
            }
			return _currentPos < length - 1;
		}
		
		public function hasPrevious():Boolean {
			return _currentPos > 0;
		}

		public function get current():Clip {
            if (_inStreamClip) return _inStreamClip;
            if (_currentPos == -1) return null;
			if (_clips.length == 0) return new NullClip();
			return _clips[_currentPos];
		}

        public function get currentPreroll():Clip {
            if (_currentPos == -1 ) return null;
            if (_clips.length == 0) return null;
            if (_inStreamClip) return null;
            var parent:Clip = _clips[_currentPos];
            return parent.preroll;
        }

        public function setInStreamClip(clip:Clip):void {
            log.debug("setInstremClip to " + clip);
            _inStreamClip = clip;
        }
	
		public function set current(clip:Clip):void {
			toIndex(indexOf(clip));
		}
	
		public function get currentIndex():Number {
			return _currentPos;
		}
		
		public function next():Clip {
			if (_currentPos == _clips.length -1) return null;
            return _clips[++_currentPos];
		}

		public function get nextClip():Clip {
            log.debug("nextClip()");
			if (_currentPos == _clips.length -1) return null;
			return _clips[_currentPos + 1];
		}
		
		public function get previousClip():Clip {
			if (_currentPos == 0) return null;
            return _clips[_currentPos + 1];
		}
		
		public function previous():Clip {
			if (_currentPos == 0) return null;
			return _clips[--_currentPos];
		}

		public function toIndex(index:Number):Clip {
			if (index < 0) return null;
			if (index >= _clips.length) return null;
			var clip:Clip = _clips[index];
            _inStreamClip = null;
            if (index == _currentPos) return clip;
            _currentPos = index;
            return _inStreamClip || clip;
		}
		
		public function indexOf(clip:Clip):Number {
			for (var i : Number = 0; i < _clips.length; i++) {
				if (_clips[i] == clip) return i;
                if (clip.parent == _clips[i]) return i;
			}
			return -1;
		}

		public function toString():String {
			return "[playList] length " + _clips.length + ", clips " + _clips; 
		}
		
		public function get commonClip():Clip {
			return _commonClip;
		}
		
		/**
		 * Does this playlist have a clip with the specified type?
		 */
		public function hasType(type:ClipType):Boolean {
            var clips:Array = _clips.concat(childClips);
            for (var i:Number = 0; i < clips.length; i++) {
                if (Clip(clips[i]).type == type) {
                    return true;
                }
            }
            return false
        }
	}
}
