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

package org.flowplayer.view {
	import org.flowplayer.model.Plugin;	
	import org.flowplayer.controller.NetStreamControllingStreamProvider;	
	
	import com.adobe.utils.StringUtil;
	
	import org.flowplayer.config.ExternalInterfaceHelper;
	import org.flowplayer.controller.StreamProvider;
	import org.flowplayer.model.Callable;
	import org.flowplayer.model.DisplayPluginModel;
	import org.flowplayer.model.FontProvider;
	import org.flowplayer.model.Loadable;
	import org.flowplayer.model.PlayerError;
	import org.flowplayer.model.PluginModel;
	import org.flowplayer.model.ProviderModel;
	import org.flowplayer.util.Log;
	import org.flowplayer.util.URLUtil;
	
	import flash.display.DisplayObject;
	import flash.display.Loader;
	import flash.display.LoaderInfo;
	import flash.events.Event;
	import flash.events.EventDispatcher;
	import flash.events.IOErrorEvent;
	import flash.events.ProgressEvent;
	import flash.net.URLRequest;
	import flash.system.ApplicationDomain;
	import flash.system.LoaderContext;
	import flash.system.SecurityDomain;
	import flash.utils.Dictionary;
	import flash.utils.getDefinitionByName;
	import flash.utils.getQualifiedClassName;		
	/**
	 * @author api
	 */
	public class PluginLoader extends EventDispatcher {

		private var log:Log = new Log(this);
		private var _loadables:Array;
		private var _loadedPlugins:Dictionary;
		private var _loadedCount:int;
		private var _errorHandler:ErrorHandler;
		private var _swiffsToLoad:Array;
		private var _pluginRegistry:PluginRegistry;
		private var _providers:Dictionary;
		private var _callback:Function;
		private var _baseUrl:String;
		private var _useExternalInterface:Boolean;
		private var _loadErrorListener:Function;
		private var _loadListener:Function;

		public function PluginLoader(baseUrl:String, pluginRegistry:PluginRegistry, errorHandler:ErrorHandler, useExternalInterface:Boolean, loadListener:Function, loadErrorListener:Function) {
			_baseUrl = baseUrl;
			_pluginRegistry = pluginRegistry;
			_errorHandler = errorHandler;
			_useExternalInterface = useExternalInterface;
			_loadListener = loadListener;
			_loadErrorListener = loadErrorListener;
			_loadedCount = 0;
		}

		private function getPluginSwiffUrls(plugins:Array):Array {
			var result:Array = new Array();
			for (var i:Number = 0; i < plugins.length; i++) {
				var loadable:Loadable = Loadable(plugins[i]); 
				if (result.indexOf(loadable.url) < 0) {
					result.push(constructUrl(loadable.url));
				}
			}
			return result;
		}
		
		private function constructUrl(url:String):String {
			if (url.indexOf("..") >= 0) return url;
			if (url.indexOf("/") >= 0) return url;
			return URLUtil.addBaseURL(_baseUrl, url);
		}

		public function loadPlugin(model:Loadable, callback:Function = null):void {
			_callback = callback;
			load([model]);
		}

		public function load(plugins:Array):void {
			log.debug("load()");
			_providers = new Dictionary();
			_loadables = plugins;
			_swiffsToLoad = getPluginSwiffUrls(plugins);
			if (! _loadables || _loadables.length == 0) {
				log.info("Not loading any plugins.");
				return;
			}
			_loadedPlugins = new Dictionary();
			_loadedCount = 0;
			var loaderContext:LoaderContext = new LoaderContext();
			loaderContext.applicationDomain = ApplicationDomain.currentDomain;
			if (!URLUtil.localDomain(_baseUrl)) {
				loaderContext.securityDomain = SecurityDomain.currentDomain;
			}
			var urls:Dictionary = new Dictionary();
			
			for (var i:Number = 0; i < _swiffsToLoad.length; i++) {
				var loader:Loader = new Loader();
				loader.contentLoaderInfo.addEventListener(Event.COMPLETE, loaded);
				var url:String = _swiffsToLoad[i];
				urls[loader.contentLoaderInfo] = url;
				loader.contentLoaderInfo.addEventListener(IOErrorEvent.IO_ERROR, function(event:IOErrorEvent):void { onIoError(event, urls); });
				loader.contentLoaderInfo.addEventListener(ProgressEvent.PROGRESS, onProgress);
				log.debug("starting to load plugin from url " + _swiffsToLoad[i]);
				loader.load(new URLRequest(url), loaderContext);				
			}
		}
		
		private function onProgress(event:ProgressEvent):void {
			log.debug("load in progress");
		}

		private function onIoError(event:IOErrorEvent, pluginUrls:Dictionary):void {
			_errorHandler.handleError(PlayerError.PLUGIN_LOAD_FAILED, "Unable to load plugin using url '" + pluginUrls[LoaderInfo(event.target)] + "': " + event.text);
		}

		public function get plugins():Dictionary {
			return _loadedPlugins;
		}

		private function loaded(event:Event):void {
			var info:LoaderInfo = event.target as LoaderInfo;
			log.debug("loaded class name " + getQualifiedClassName(info.content));
			
//			Security.allowDomain(info.url);
			
			var instanceUsed:Boolean = false;
			_loadables.forEach(function(loadable:Loadable, index:int, array:Array):void {
				if (! loadable.plugin && hasSwiff(info.url, loadable.url)) {
					log.debug("this is the swf for loadable " + loadable);
					initializePlugin(loadable, createPluginInstance(instanceUsed, info.content));
					instanceUsed = true;
				}
			});
			if (++_loadedCount == _swiffsToLoad.length) {
				log.debug("all plugin SWFs loaded. loaded total " + loadedCount + " plugins");
				setConfigPlugins();
				dispatchEvent(new Event(Event.COMPLETE, true, false));
			}
			if (_callback != null) {
				_callback();
			}
		}

		private function initializePlugin(loadable:Loadable, pluginInstance:Object):void {
			log.debug("initializing plugin for loadable " + loadable + ", instance " + pluginInstance);
				
			_loadedPlugins[loadable] = pluginInstance;
		
			log.debug("pluginInstance " + pluginInstance);
			var plugin:PluginModel;
			if (pluginInstance is FontProvider) {
				_pluginRegistry.registerFont(FontProvider(pluginInstance).fontFamily);

			} else if (pluginInstance is DisplayObject) {
				plugin = Loadable(loadable).createDisplayPlugin(pluginInstance as DisplayObject);
				_pluginRegistry.registerDisplayPlugin(plugin as DisplayPluginModel, pluginInstance as DisplayObject);

			} else if (pluginInstance is StreamProvider) {
				plugin = Loadable(loadable).createProvider(pluginInstance);
				_providers[plugin.name] = pluginInstance;
				_pluginRegistry.registerProvider(plugin as ProviderModel, pluginInstance);

			} else {
				log.error("unknown plugin type " + pluginInstance);
			}
			if (pluginInstance is Plugin) {
				plugin.onLoad(_loadListener);
				plugin.onError(_loadErrorListener);
			}
			if (plugin is Callable && _useExternalInterface) {
				ExternalInterfaceHelper.initializeInterface(plugin as Callable, pluginInstance);
			}
		}
		
		private function createPluginInstance(instanceUsed:Boolean, instance:DisplayObject):Object {
			if (instance.hasOwnProperty("newPlugin")) return instance["newPlugin"](); 
			
			if (! instanceUsed) {
				log.debug("using existing instance " + instance);
				return instance; 
			}
			var className:String = getQualifiedClassName(instance);
			log.info("creating new " + className);
			var PluginClass:Class = Class(getDefinitionByName(className));
			return new PluginClass() as DisplayObject;
		}
		
		public function setConfigPlugins():void {
			_loadables.forEach(function(loadable:Loadable, index:int, array:Array):void {
				var pluginInstance:Object = plugins[loadable];
				log.info(index + ": setting config to " + pluginInstance + ", " + loadable);
				if (pluginInstance is NetStreamControllingStreamProvider) {
					log.debug("NetStreamControllingStreamProvider(pluginInstance).config = " +loadable.plugin);
					NetStreamControllingStreamProvider(pluginInstance).config = loadable.plugin;
				} else {
					if (pluginInstance.hasOwnProperty("onConfig")) {
						pluginInstance.onConfig(loadable.plugin);
					}
				}
			});
		}

		private function hasSwiff(infoUrl:String, modelUrl:String):Boolean {
			var slashPos:int = modelUrl.lastIndexOf("/");
			var swiffUrl:String = slashPos >= 0 ? modelUrl.substr(slashPos) : modelUrl;
			return StringUtil.endsWith(infoUrl, swiffUrl);
		}
		
		public function get providers():Dictionary {
			return _providers;
		}
		
		public function get loadedCount():int {
			return _loadedCount;
		}
	}
}
