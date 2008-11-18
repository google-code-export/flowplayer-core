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

	public class ClipType {
		public static const VIDEO:ClipType = new ClipType("video");
		public static const IMAGE:ClipType = new ClipType("image");

		private static var enumCreated:Boolean;
		{ enumCreated = true; }

		private var _type:String;

		public function ClipType(type:String) {
			if (enumCreated)
				throw new Error("Cannot create ad-hoc ClipType instances");
			this._type = type;
		}
		
		public function get type():String {
			return _type;
		}
		
		public static function fromFileExtension(name:String):ClipType {
			var dotPos:Number = name.lastIndexOf(".");
			var lcName:String = name.toLowerCase();
			var extension:String = lcName.substring(dotPos + 1, lcName.length);
			return resolveType(extension);
		}
		
		public static function resolveType(type:String):ClipType {
			if (['3g2', '3gp', 'aac', 'f4b', 'f4p', 'f4v', 'flv', 'm4a', 'm4v', 'mov', 'mp4', 'vp6', 'mpeg4', 'video'].indexOf(type) >= 0)
				return ClipType.VIDEO;
			if (['png', 'jpg', 'jpeg', 'gif', 'swf', 'image'].indexOf(type) >= 0)
				return ClipType.IMAGE;
			
			return ClipType.VIDEO;
		}
		
		public function toString():String {
			return "ClipType: '" + _type + "'";
		}
	}
}
