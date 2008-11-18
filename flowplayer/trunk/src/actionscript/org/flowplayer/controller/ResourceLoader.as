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

package org.flowplayer.controller {
	import flash.display.Loader;
	import flash.events.Event;
	import flash.events.EventDispatcher;
	import flash.events.IOErrorEvent;
	import flash.events.SecurityErrorEvent;
	import flash.net.URLLoader;
	import flash.net.URLRequest;
	
	import org.flowplayer.util.Log;
	import org.flowplayer.view.ErrorHandler;		

	/**
	 * @author api
	 */
	public class ResourceLoader extends EventDispatcher {

		private var log:Log = new Log(this);
		private var _loaders:Object = new Object();
		private var _errorHandler:ErrorHandler;
		private var _urls:Array = new Array();
		private var _loadedCount:Number;

		public function ResourceLoader(errorHandler:ErrorHandler = null, loadListener:Function = null) {
			_errorHandler = errorHandler;
			if (loadListener != null) {
				addEventListener(Event.COMPLETE, loadListener);
			}
		}

		public function addTextResourceUrl(url:String):void {
			_urls.push(url);
			_loaders[url] = createURLLoader();
		}

		public function addBinaryResourceUrl(url:String):void {
			_urls.push(url);
			_loaders[url] = createLoader();
		}

		/**
		 * Starts loading.
		 * @param url the resource to be loaded, alternatively add the URLS using addUrl() before calling this
		 * @see #addTextResourceUrl()
		 * @see #addBinaryResourceUrl()
		 */
		public function load(url:String = null):void {
			_urls = new Array();
			if (url) {
				addBinaryResourceUrl(url);
			}
			if (! _urls || _urls.length == 0) {
				log.debug("nothing to load");
				return;
			}
			startLoading();
		}
		
		private function startLoading():void {
			_loadedCount = 0;
			for (var url:String in _loaders) {
				log.debug("startLoading() " + url);
				_loaders[url].load(new URLRequest(url));
			}
		}

		private function createURLLoader():URLLoader {
			var loader:URLLoader = new URLLoader();
			loader.addEventListener(Event.COMPLETE, onLoadComplete);
			loader.addEventListener(IOErrorEvent.IO_ERROR, onIOError);
			loader.addEventListener(SecurityErrorEvent.SECURITY_ERROR, onSecurityError);
			return loader;
		}

		private function createLoader():Loader {
			log.debug("creating new loader");
			var loader:Loader = new Loader();
			loader.contentLoaderInfo.addEventListener(Event.COMPLETE, onLoadComplete);
			loader.contentLoaderInfo.addEventListener(IOErrorEvent.IO_ERROR, onIOError);
			loader.contentLoaderInfo.addEventListener(SecurityErrorEvent.SECURITY_ERROR, onSecurityError);
			return loader;
		}
		
		public final function getContent(url:String = null):Object {
			try {
				var loader:Object = _loaders[url ? url : _urls[0]];
				return loader is URLLoader ? URLLoader(loader).data : Loader(loader).content;
//				return _loaders[url ? url : _urls[0]].content;
			} catch (e:SecurityError) {
				handleError("cannot access file (try loosening Flash security settings): " + e.message);
			}
			return null;
		}

		private function onLoadComplete(event:Event):void {
			if (++_loadedCount == _urls.length) {
				log.debug("onLoadComplete, all resources were loaded");
				dispatchEvent(event);
			}
		}
		
		private function onIOError(event:IOErrorEvent):void {
			log.error("IOError: " + event.text);
			handleError("Unable to load resources: " + event.text);
		}

		private function onSecurityError(event:SecurityErrorEvent):void {
			log.error("SecurityError: " + event.text);
			handleError("cannot access the resource file (try loosening Flash security settings): " + event.text);
		}
		
		protected function handleError(errorMessage:String, e:Error = null):void {
			if (_errorHandler) {
				if (e) {
					_errorHandler.handleError(e, errorMessage);
				} else {
					_errorHandler.showError(errorMessage);
				}
			}
		}
		
		/**
		 * Sets the error handler. All load errors will be handled with the specified
		 * handler.
		 */		
		public function set errorHandler(errorHandler:ErrorHandler):void {
			_errorHandler = errorHandler;
		}
	}
}
