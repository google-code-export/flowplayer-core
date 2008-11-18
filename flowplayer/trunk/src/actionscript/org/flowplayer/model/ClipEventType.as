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
	import flash.utils.Dictionary;
	
	import org.flowplayer.flow_internal;		

	public class ClipEventType extends EventType {
		
		public static const CONNECT:ClipEventType = new ClipEventType("onConnect");
		public static const METADATA:ClipEventType = new ClipEventType("onMetaData");
		public static const START:ClipEventType = new ClipEventType("onStart");
		public static const PAUSE:ClipEventType = new ClipEventType("onPause");
		public static const RESUME:ClipEventType = new ClipEventType("onResume");
		public static const STOP:ClipEventType = new ClipEventType("onStop");
		public static const FINISH:ClipEventType = new ClipEventType("onFinish");
		public static const CUEPOINT:ClipEventType = new ClipEventType("onCuepoint");
		public static const SEEK:ClipEventType = new ClipEventType("onSeek");
		
		public static const BUFFER_EMPTY:ClipEventType = new ClipEventType("onBufferEmpty");
		public static const BUFFER_FULL:ClipEventType = new ClipEventType("onBufferFull");
		public static const BUFFER_STOP:ClipEventType = new ClipEventType("onBufferStop");
		public static const LAST_SECOND:ClipEventType = new ClipEventType("onLastSecond");
		public static const UPDATE:ClipEventType = new ClipEventType("onUpdate");
		public static const ERROR:ClipEventType = new ClipEventType("onError");

		public static const PLAYLIST_REPLACE:ClipEventType = new ClipEventType("onPlaylistReplace");

		private static var _allValues:Dictionary;
		private static var _cancellable:Dictionary = new Dictionary();
		{
			_cancellable[START.name] = START;
			_cancellable[SEEK.name] = SEEK;
			_cancellable[PAUSE.name] = PAUSE;
			_cancellable[RESUME.name] = RESUME;
			_cancellable[STOP.name] = STOP;
		}
	
		override public function get isCancellable():Boolean {
			return _cancellable[this.name];
		}
		
		public static function get cancellable():Dictionary {
			return _cancellable;
		}

		public static function get all():Dictionary {
			return _allValues;
		}

		/**
		 * Creates a new type.
		 */
		public function ClipEventType(name:String) {
			super(name);
			if (! _allValues) {
				_allValues = new Dictionary();
			}
			_allValues[name] = this;
		}

		public function toString():String {
			return "[PlayEventType] '" + name + "'";
		}
		
		public function get playlistIsEventTarget():Boolean {
			return this == PLAYLIST_REPLACE;
		}
	}
}
