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
	import org.flowplayer.model.DisplayPropertiesImpl;	

	/**
	 * @author api
	 */
	public class Logo extends DisplayPropertiesImpl {
		
		private var _url:String;
		private var _fullscreenOnly:Boolean = true;
		private var _fadeSpeed:Number;
		private var _displayTime:int = 0;
		private var _scaleMaximum:Number = 2;
		private var _linkUrl:String;
		private var _linkWindow:String;
		
		public function Logo() {
			top = "20";
			right = "20";
			_linkWindow = "_self";
		}
		
		public function get url():String {
			return _url;
		}
		
		public function set url(url:String):void {
			_url = url;
			if (_url && _url.indexOf(".swf") > 0) {
				width = "6.5%";
				height = "6.5%";
			}
		}
		
		public function get fullscreenOnly():Boolean {
			return _fullscreenOnly;
		}
		
		public function set fullscreenOnly(fullscreenOnly:Boolean):void {
			_fullscreenOnly = fullscreenOnly;
		}
		public function get fadeSpeed():Number {
			return _fadeSpeed;
		}
		
		public function set fadeSpeed(fadeSpeed:Number):void {
			_fadeSpeed = fadeSpeed;
		}
		
		public function get displayTime():int {
			return _displayTime;
		}
		
		public function set displayTime(displayTime:int):void {
			_displayTime = displayTime;
		}
		
		public function get scaleMaximum():Number {
			return _scaleMaximum;
		}

		public function set scaleMaximum(scaleMaximum:Number):void {
			_scaleMaximum = scaleMaximum;
		}				public function get linkUrl():String {
			return _linkUrl;		}				public function set linkUrl(linkUrl:String):void {
			_linkUrl = linkUrl;		}
		
		public function get linkWindow():String {
			return _linkWindow;
		}
		
		public function set linkWindow(linkWindow:String):void {
			_linkWindow = linkWindow;
		}
	}
}
