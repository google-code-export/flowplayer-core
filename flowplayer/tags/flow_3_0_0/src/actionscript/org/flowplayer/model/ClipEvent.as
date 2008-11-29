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
	import flash.events.Event;	
	/**
	 * @author anssi
	 */
	public class ClipEvent extends AbstractEvent  {

		public function ClipEvent(eventType:EventType, info:Object = null) {
			super(eventType, info);
		}

		public override function clone():Event {
			return new ClipEvent(eventType, info);
		}

		public override function toString():String {
			return formatToString("ClipEvent", "type", "info");
		}
				
		protected override function get externalEventArgument():Object {
			if (eventType == ClipEventType.PLAYLIST_REPLACE) {
				return (target as ClipEventSupport).clips;
			} 
			if (target is Clip) {
				return Clip(target).index;
			}
			return target;
		}
				
		protected override function get externalEventArgument2():Object {
			if (eventType == ClipEventType.CUEPOINT) {
				return Cuepoint(info).callbackId;
			} 
			if (eventType == ClipEventType.START || eventType == ClipEventType.UPDATE) {
				return target;
			}
			return super.externalEventArgument2;
		}
				
		protected override function get externalEventArgument3():Object {
			if (eventType == ClipEventType.CUEPOINT) {
				return info is DynamicCuepoint ? info : Cuepoint(info).time;
			}
			return super.externalEventArgument3;
		}
	}
}
