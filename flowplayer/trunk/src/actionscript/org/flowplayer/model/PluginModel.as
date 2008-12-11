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
	import org.flowplayer.model.Callable;	import org.flowplayer.model.Cloneable;	
	/**
	 * @author api
	 */
	public interface PluginModel extends Identifiable, Callable, Cloneable {
		
		function dispatchOnLoad():void;
		
		function dispatchOnLoadError():void;
			
		function dispatch(eventType:PluginEventType, eventkId:String = null):void;
		
		function dispatchEvent(event:PluginEvent):void;

		function onPluginEvent(listener:Function):void;

		function onLoad(listener:Function):void;

		function onError(listener:Function):void;
		
		function unbind(listener:Function, event:EventType = null, beforePhase:Boolean = false):void;

		function get config():Object;
		
		function set config(config:Object):void;
		
	}
}
