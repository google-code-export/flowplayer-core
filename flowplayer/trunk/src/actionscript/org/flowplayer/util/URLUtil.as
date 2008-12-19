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

package org.flowplayer.util {
	import flash.display.LoaderInfo;	
	import flash.external.ExternalInterface;		

	/**
	 * @author anssi
	 */
	public class URLUtil {
				public static function completeURL(baseURL:String, fileName:String):String {			return addBaseURL(baseURL || pageUrl, fileName);
		}

		public static function addBaseURL(baseURL:String, fileName:String):String {
			if (fileName == null) return null;
			
			if (isCompleteURLWithProtocol(fileName)) return fileName;
			if (fileName.indexOf("/") == 0) return fileName;
			
			if (baseURL == '' || baseURL == null || baseURL == 'null') {
				return fileName;
			}
			if (baseURL != null) {
				if (baseURL.lastIndexOf("/") == baseURL.length - 1)
					return baseURL + fileName;
				return baseURL + "/" + fileName;
			}
			return fileName;
		}

		public static function isCompleteURLWithProtocol(fileName:String):Boolean {
			if (! fileName) return false;
			return fileName.indexOf("://") > 0;
		}
		
		public static function get pageUrl():String {
			if (!ExternalInterface.available) return null;
			try {
				var href:String = ExternalInterface.call("window.location.href.toString");
				var endPos:int = href.indexOf("?");
				if (endPos < 0) {
					endPos = href.lastIndexOf("/");
				}
				return href.substring(0, endPos);
			} catch (e:Error) {
			}
			return null;
		}
		
		public static function playerBaseUrl(loaderInfo:LoaderInfo):String {
			var url:String = loaderInfo.url;
			var firstSwf:Number = url.indexOf(".swf");
			url = url.substring(0, firstSwf);
			var lastSlashBeforeSwf:Number = url.lastIndexOf("/");
			return url.substring(0, lastSlashBeforeSwf);
		}
		
		public static function localDomain(swfUrl:String):Boolean {
			if (swfUrl.indexOf("http://localhost/") == 0) return true;
			if (swfUrl.indexOf("file://") == 0) return true;
			if (swfUrl.indexOf("http://127.0.0.1") == 0) return true;
			if (swfUrl.indexOf("http://") == 0) return false;
			if (swfUrl.indexOf("/") == 0) return true;
			return false;
		}
	}
}
