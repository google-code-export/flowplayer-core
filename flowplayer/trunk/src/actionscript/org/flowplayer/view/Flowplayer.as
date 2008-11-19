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
	import org.flowplayer.config.Config;
	import org.flowplayer.config.ExternalInterfaceHelper;
	import org.flowplayer.controller.PlayListController;
	import org.flowplayer.flow_internal;
	import org.flowplayer.model.Callable;
	import org.flowplayer.model.Clip;
	import org.flowplayer.model.ClipEventType;
	import org.flowplayer.model.DisplayPluginModel;
	import org.flowplayer.model.DisplayProperties;
	import org.flowplayer.model.DisplayPropertiesImpl;
	import org.flowplayer.model.Loadable;
	import org.flowplayer.model.Playlist;
	import org.flowplayer.model.Plugin;
	import org.flowplayer.model.PluginEvent;
	import org.flowplayer.model.PluginEventType;
	import org.flowplayer.model.PluginModel;
	import org.flowplayer.model.Status;
	import org.flowplayer.util.NumberUtil;
	import org.flowplayer.util.ObjectConverter;
	import org.flowplayer.util.PropertyBinder;
	import org.flowplayer.view.FlowplayerBase;
	import org.flowplayer.view.Styleable;
	
	import flash.display.Stage;
	import flash.external.ExternalInterface;	
	
	use namespace flow_internal;

	/**
	 * @author api
	 */
	public class Flowplayer extends FlowplayerBase {

		
		private var _canvas:StyleableSprite;
		
		public function Flowplayer(
			stage:Stage, 
			control:PlayListController, 
			pluginRegistry:PluginRegistry, 
			panel:Panel, 
			animationEngine:AnimationEngine, 
			canvas:StyleableSprite, 
			errorHandler:ErrorHandler, 
			config:Config, 
			fullscreenManager:FullscreenManager,
			pluginLoader:PluginLoader) {
				
			super(stage, control, pluginRegistry, panel, animationEngine, errorHandler, config, fullscreenManager, pluginLoader);
			_canvas = canvas;
		}

		public function initExternalInterface():void {
			if (!ExternalInterface.available)
				log.info("ExternalInteface is not available in this runtime. JavaScript access will be disabled.");
			try {
				addCallback("getVersion", function():Array { return version; });
				addCallback("getPlaylist", function():Array { return convert(playlist.clips) as Array; });
				addCallback("getId", function():String { return id; });
				addCallback("play", genericPlay);
				addCallback("startBuffering", startBuffering);
				addCallback("stopBuffering", stopBuffering);
				addCallback("isFullscreen", isFullscreen);
				
				addCallback("toggle", toggle);
				addCallback("getState", function():Number { return state.code; });
				addCallback("getStatus", function():Object { return convert(status); });
				addCallback("isPlaying", isPlaying);
				addCallback("isPaused", isPaused);
				
				var wrapper:WrapperForIE = new WrapperForIE(this);
				addCallback("stop", wrapper.fp_stop );
				addCallback("pause", wrapper.fp_pause );
				addCallback("resume", wrapper.fp_resume );
				addCallback("close", wrapper.fp_close );

				addCallback("getTime", function():Number { return status.time; });
				addCallback("mute", function():void { muted = true; });
				addCallback("unmute", function():void { muted = false; });
				addCallback("isMuted", function():Boolean { return muted; });
				addCallback("setVolume", function(value:Number):void { volume = value; });
				addCallback("getVolume", function():Number { return volume; });
				addCallback("seek", genericSeek);
				addCallback("getCurrentClip", function():Object { 
					return new ObjectConverter(currentClip).convert(); });
				addCallback("getClip", function(index:Number):Object { return convert(playlist.getClip(index)); });
				addCallback("setPlaylist", function(clipObjects:Array):void { setPlaylist(_config.getPlaylist(clipObjects)); });
				addCallback("showError", showError);

				addCallback("loadPlugin", pluginLoad);
				addCallback("showPlugin", pluginShow);
				addCallback("hidePlugin", pluginHide);
				addCallback("togglePlugin", pluginToggle);
				addCallback("animate", animate);
				addCallback("css", css);
//				return;
				addCallback("reset", reset);
				addCallback("fadeIn", fadeIn);
				addCallback("fadeOut", fadeOut);
				addCallback("fadeTo", fadeTo);
				addCallback("getPlugin", function(pluginName:String):Object { 
					return new ObjectConverter(_pluginRegistry.getPlugin(pluginName)).convert();
				});
				addCallback("getRawPlugin", function(pluginName:String):Object { 
					return _pluginRegistry.getPlugin(pluginName);
				});
				addCallback("invoke", invoke);
				addCallback("addCuepoints", addCuepoints); 
				addCallback("updateClip", updateClip); 
				addCallback("logging", logging);

			} catch (e:Error) {
				handleError(e, "Unable to add callback to ExternalInterface");
			}
		}

		private function pluginHide(pluginName:String):void {
			var plugin:Object = _pluginRegistry.getPlugin(pluginName);
			checkPlugin(plugin, pluginName, DisplayProperties);
			hidePlugin(DisplayProperties(plugin).getDisplayObject());
		}

		private function pluginShow(pluginName:String, props:Object = null):void {
			pluginPanelOp(showPlugin, pluginName, props);			
		}

		private function pluginToggle(pluginName:String, props:Object = null):Boolean {
			return pluginPanelOp(togglePlugin, pluginName, props) as Boolean;			
		}

		private function pluginPanelOp(func:Function, pluginName:String, props:Object = null):Object {
			var plugin:Object = _pluginRegistry.getPlugin(pluginName);
			checkPlugin(plugin, pluginName, DisplayProperties);
			return func(DisplayProperties(plugin).getDisplayObject(), 
				(props ? new PropertyBinder(new DisplayPropertiesImpl(), null).copyProperties(props) : plugin) as DisplayProperties) ;			
		}

		private function pluginLoad(name:String, url:String, properties:Object = null, callbackId:String = null):void {
			var loadable:Loadable = new Loadable(name, _config, url);
			if (properties) {
				new PropertyBinder(loadable, "config").copyProperties(properties);
			}
			loadPluginLoadable(loadable, callbackId != null ? createCallback(callbackId) : null);
		}

		private static function addCallback(methodName:String, func:Function):void {
			ExternalInterfaceHelper.addCallback("fp_" + methodName, func);
		}
		
		private function genericPlay(param:Object = null):void {
			if (param == null) { 
				play();
				return;
			}
			if (param is Number) {
				_playListController.play(null, param as Number);
				return;
			}
			var clip:Clip = _config.createClip(param);
			if (! clip) {
				showError("cannot convert " + param + " to a clip");
				return;
			}
			play(clip);
		}
		
		private function genericSeek(target:Object):void {
			var percentage:Number = target is String ? NumberUtil.decodePercentage(target as String) : NaN;
			if (isNaN(percentage)) {
				seek(target is String ? parseInt(target as String) : target as Number);
			} else {
				seekRelative(percentage); 
			}
		}
		
		private function css(pluginName:String, props:Object = null):Object {
			log.debug("css, plugin " + pluginName);
			if (pluginName == "canvas") {
				_canvas.css(props);
				return props;
			} 
			return style(pluginName, props, false, 0);
		}
		private function convert(objToConvert:Object):Object {
			return new ObjectConverter(objToConvert).convert();
		}
		
			var result:Object = new Object();
			var coreDisplayProps:Array = [ "width", "height", "left", "top", "bottom", "right", "opacity" ];
			if (!animatable) {
				coreDisplayProps = coreDisplayProps.concat("display", "zIndex");
			}
			for (var propName:String in props) {
				if (coreDisplayProps.indexOf(propName) >= 0) {
					result[propName] = props[propName];
//					delete props[propName];
				}
			}
			return result;

		private function animate(pluginName:String, props:Object, durationMillis:Number = 400, listenerId:String = null):Object {
			return style(pluginName, props, true, durationMillis, listenerId);
		}

		private function style(pluginName:String, props:Object, animate:Boolean, durationMillis:Number = 400, listenerId:String = null):Object {
			var plugin:Object = _pluginRegistry.getPlugin(pluginName);
			checkPlugin(plugin, pluginName, DisplayPluginModel);
			log.debug("going to animate plugin " + pluginName); 

			var result:Object = convert(props ? _animationEngine.animate(DisplayProperties(plugin).getDisplayObject(), collectDisplayProps(props, animate), durationMillis, createCallback(listenerId, plugin)) : plugin);

			// check if plugin is Styleable and delegate to it
			if (plugin is DisplayProperties && DisplayProperties(plugin).getDisplayObject() is Styleable) {
				var newPluginProps:Object = Styleable(DisplayProperties(plugin).getDisplayObject())[animate ? "animate" : "css"](props);
				for (var prop:String in newPluginProps) {
					result[prop] = newPluginProps[prop];
				}
			}
			return result;
		}

		private function fadeOut(pluginName:String, durationMillis:Number = 400, listenerId:String = null):void {
			var props:DisplayProperties = prepareFade(pluginName, false);
			_animationEngine.fadeOut(props.getDisplayObject(), durationMillis, createCallback(listenerId, props));
		}

		private function fadeIn(pluginName:String, durationMillis:Number = 400, listenerId:String = null):void {
			var props:DisplayProperties = prepareFade(pluginName, true);
			_animationEngine.fadeIn(props.getDisplayObject(), durationMillis, createCallback(listenerId, props));
		}

		private function fadeTo(pluginName:String, alpha:Number, durationMillis:Number = 400, listenerId:String = null):void {
			var props:DisplayProperties = prepareFade(pluginName, true);
			_animationEngine.fadeTo(props.getDisplayObject(), alpha, durationMillis, createCallback(listenerId, props));
		}
		
		private function prepareFade(pluginName:String, show:Boolean):DisplayProperties {
			var plugin:Object = _pluginRegistry.getPlugin(pluginName);
			checkPlugin(plugin, pluginName, DisplayProperties);
			if (show) {
				var props:DisplayProperties = plugin as DisplayProperties;
				if (! props.getDisplayObject().parent || props.getDisplayObject().parent != _panel) {
					props.alpha = 0;
				} 
				showPlugin(props.getDisplayObject(), props);
			}
			return plugin as DisplayProperties;
		}

			var plugin:Callable = _pluginRegistry.getPlugin(pluginName) as Callable;
			checkPlugin(plugin, pluginName, Callable);
			try {
				log.debug("invoke()");
				if (plugin.getMethod(methodName).hasReturnValue) {
					log.debug("method has a return value");
					return plugin.invokeMethod(methodName, args is Array ? args as Array : [ args ]);
				} else {
					log.debug("method does not have a return value");
					plugin.invokeMethod(methodName, args is Array ? args as Array : [ args ]);
				}
			} catch (e:Error) {
				handleError(e, "Error when invoking method '" + methodName + "', on plugin '" + pluginName + "'");
			}
			return "undefined";
		}

		private function setPlaylist(playlist:Playlist):void {
			log.debug("setPlaylist, clips " + playlist.clips);
			_playListController.setPlaylist(playlist);
		}

		private function addCuepoints(cuepoints:Array, clipIndex:int, callbackId:String):void {
			var clip:Clip = _playListController.playlist.getClip(clipIndex);
			var points:Array = _config.createCuepoints(cuepoints, callbackId);
			if (! points || points.length == 0) {
				showError("unable to create cuepoints from " + cuepoints);
			}
			clip.addCuepoints(points);
			log.debug("clip has now cuepoints " + clip.cuepoints);
		}
		
		private function updateClip(clipObj:Object, clipIndex:int):void {
			var clip:Clip = _playListController.playlist.getClip(clipIndex);
			new PropertyBinder(clip, "customProperties").copyProperties(clipObj);
			clip.dispatch(ClipEventType.UPDATE);
		}
//
//		private function createCallback(listenerId:String):Function {
//			if (! listenerId) return null;
//			return function():void { 
//				new PluginEvent(PluginEventType.PLUGIN_EVENT, listenerId).fireExternal(_playerId); 
//			};
//		}

		private function createCallback(listenerId:String, pluginArg:Object = null):Function {
			if (! listenerId) return null;
			return function(plugin:PluginModel = null):void {
				if (plugin || pluginArg is PluginModel) {
					PluginModel(pluginArg || plugin).dispatch(PluginEventType.PLUGIN_EVENT, listenerId);
				} else {
					new PluginEvent(PluginEventType.PLUGIN_EVENT, listenerId, pluginArg is DisplayProperties ? DisplayProperties(pluginArg).name : pluginArg).fireExternal(_playerId);
				} 
			};
		}

	}
}