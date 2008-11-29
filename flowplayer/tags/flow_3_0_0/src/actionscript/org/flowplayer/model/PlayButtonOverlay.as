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
	public class PlayButtonOverlay extends DisplayPluginModelImpl {

		private var _fadeSpeed:int;
		private var _rotateSpeed:int;
		private var _url:String;		private var _label:String;
		private var _replayLabel:String;
		public function PlayButtonOverlay() {
			super(null, "play", false);
			// these are used initially before screen is arranged
			// once screen is availabe, these will be overridden
			top = "45%";
			left = "50%";
			width = "22%";
			height = "22%";
			visible = false;
			_rotateSpeed = 50;
			_fadeSpeed = 500;
			_replayLabel = "Play again";
		}

		
		public function get url():String {
			return _url;
		}
		
		public function set url(url:String):void {
			_url = url;
		}
		
		public function get fadeSpeed():int {
			return _fadeSpeed;
		}
		
		public function set fadeSpeed(fadeSpeed:int):void {
			_fadeSpeed = fadeSpeed;
		}
		
		public function get rotateSpeed():int {
			if (_rotateSpeed > 100) return 100;
			return _rotateSpeed;
		}
		
		public function set rotateSpeed(rotateSpeed:int):void {
			_rotateSpeed = rotateSpeed;
		}
		
		public function get label():String {
			return _label;
		}
		
		public function set label(label:String):void {
			_label = label;
		}
		
		public function get replayLabel():String {
			return _replayLabel;
		}
		
		public function set replayLabel(replayLabel:String):void {
			_replayLabel = replayLabel;
		}
	}
}
