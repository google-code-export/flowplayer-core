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

package org.flowplayer.config {
	import flash.display.DisplayObject;
	
	import org.flowplayer.model.DisplayPluginModel;
	import org.flowplayer.model.DisplayPluginModelImpl;
	import org.flowplayer.model.DisplayProperties;
	import org.flowplayer.model.DisplayPropertiesImpl;
	import org.flowplayer.model.Loadable;
	import org.flowplayer.model.Plugin;
	import org.flowplayer.model.PluginModel;
	import org.flowplayer.util.Log;
	import org.flowplayer.util.PropertyBinder;	

	internal class PluginBuilder {

		private var log:Log = new Log(this);
		private var _pluginObjects:Object;
		private var _skinObjects:Object;
		private var _config:Config;
		private var _playerSwfName:String;		private var _controlsVersion:String;
		public function PluginBuilder(playerSwfName:String, controlsVersion:String, config:Config, pluginObjects:Object, skinObjects:Object) {
			_playerSwfName = playerSwfName;
			_config = config;
			_pluginObjects = pluginObjects || new Object();
			_skinObjects = skinObjects || new Object();
			_controlsVersion = controlsVersion;
		}

		public function createLoadables(fromObjects:Object):Array {
			var pluginsToLoad:Array = new Array();
			for (var name:String in fromObjects) {
				if (! isObjectDisabled(name, _pluginObjects)) {
					log.debug("creating loadable for '" + name + "', " + fromObjects[name]);
					var loadable:Loadable = new Loadable(name, _config);
					new PropertyBinder(loadable, "config").copyProperties(fromObjects[name]);
					pluginsToLoad.push(loadable);
				}
			}
			createLoadable("controls", pluginsToLoad, _controlsVersion);
//			createLoadable("controlbuttons", pluginsToLoad, _controlsVersion);
			return pluginsToLoad;
		}
		
		private function isObjectDisabled(name:String, confObjects:Object):Boolean {
			if (! confObjects.hasOwnProperty(name)) return false;
			var pluginObj:Object = confObjects[name];
			log.debug("'" + name + "' was found in configuration " + pluginObj);
			return pluginObj == null;
		}
		
		private function createLoadable(name:String, plugins:Array, version:String):void {			if (isObjectDisabled(name, _pluginObjects)) {
				log.debug(name + " is disabled");
				return;
			}
			var loadable:Loadable = findOrCreate(name, plugins);
			if (! loadable.url) {
				loadable.url = getLoadableUrl(name, version);
			}
			plugins.push(loadable);
		}
				private function findOrCreate(name:String, plugins:Array):Loadable {			var loadable:Loadable;
			for each (var plugin:Loadable in plugins) {
				if (plugin.name == name)
					loadable = plugin;
			}
			if (! loadable) {				loadable = new Loadable(name, _config);
			}
			return loadable;		}
		private function getLoadableUrl(name:String, version:String):String {
			var playerVersion:String = getPlayerVersion();
			if (playerVersion) {
				return "flowplayer." + name + "-" + version + ".swf";
			} else {
				return "flowplayer." + name + ".swf";
			}
		}
		
		private function getPlayerVersion():String {
			var version:String = getVersionFromSwfName("flowplayer");
			if (version) return version;
			return getVersionFromSwfName("flowplayer.commercial");
		}
		
		private function getVersionFromSwfName(swfName:String):String {
			if (_playerSwfName.indexOf(swfName + "-") != 0) return null;
			if (_playerSwfName.indexOf(".swf") < (swfName + "-").length) return null;
			return _playerSwfName.substring((swfName + "-").length, _playerSwfName.indexOf(".swf"));
		}

		public function getDisplayProperties(conf:Object, name:String, DisplayPropertiesClass:Class = null):DisplayProperties {
			if (isObjectDisabled(name, _skinObjects)) {
				log.debug(name + " is disabled");
				return null;
			}
			var props:DisplayProperties = DisplayPropertiesClass ? new DisplayPropertiesClass() as DisplayProperties : new DisplayPropertiesImpl();
			if (conf) {
				new PropertyBinder(props, null).copyProperties(conf);
			}
			props.name = name;
			return props;
		}
		
		public function getScreen(screenObj:Object):DisplayProperties {
			log.warn("getScreen " + screenObj);
			var screen:DisplayProperties = new DisplayPropertiesImpl(null, "screen", false);
			new PropertyBinder(screen, null).copyProperties(getScreenDefaults());
			if (screenObj) {
				log.info("setting screen properties specified in configuration");
				new PropertyBinder(screen, null).copyProperties(screenObj);
			}
			screen.zIndex = 0;
			return screen;
		}

		private function getScreenDefaults():Object {
			var screen:Object = new Object();
			screen.left = "50%";
			screen.bottom = "50%";
			screen.width = "100%";
			screen.height = "100%";
			screen.name = "screen";
			screen.zIndex = 0;
			return screen;
		}
		
		public function getPlugin(disp:DisplayObject, name:String, config:Object):PluginModel {
			var plugin:DisplayPluginModel = new PropertyBinder(new DisplayPluginModelImpl(disp, name, false), "config").copyProperties(config, true) as DisplayPluginModel;
			log.debug(name + " position specified in config " + plugin.position);
			
			// add defaults settings from the plugin instance (will not override those set in config)
			if (disp is Plugin) {
				log.debug(name + " implements Pluggable, querying defaultConfig");
				var defaults:Object = Plugin(disp).getDefaultConfig();
				if (defaults) {
					fixPositionSettings(plugin, defaults);
					if (! (config && config.hasOwnProperty("opacity")) && defaults.hasOwnProperty("opacity")) {
						plugin.opacity = defaults["opacity"];
					}
					plugin = new PropertyBinder(plugin, "config").copyProperties(defaults, false) as DisplayPluginModel;
					log.debug(name + " position after applying defaults " + plugin.position + ", zIndex " + plugin.zIndex);
				}
			}
			return plugin;
		}
		
		private function fixPositionSettings(props:DisplayProperties, defaults:Object):void {
			clearOpposite("bottom", "top", props, defaults);
			clearOpposite("left", "right", props, defaults);
		}
		
		private function clearOpposite(prop1:String, prop2:String, props:DisplayProperties, defaults:Object):void {
			if (props.position[prop1].hasValue() && defaults.hasOwnProperty(prop2)) {
				delete defaults[prop2];
			} else if (props.position[prop2].hasValue() && defaults.hasOwnProperty(prop1)) {
				delete defaults[prop1];
			}
		}
	}
}
