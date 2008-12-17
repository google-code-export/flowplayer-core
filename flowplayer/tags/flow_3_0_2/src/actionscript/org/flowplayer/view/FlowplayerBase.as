/**
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
	import org.flowplayer.controller.PlayListController;
	import org.flowplayer.controller.ResourceLoader;
	import org.flowplayer.controller.ResourceLoaderImpl;
	import org.flowplayer.flow_internal;
	import org.flowplayer.model.Clip;
	import org.flowplayer.model.DisplayPluginModel;
	import org.flowplayer.model.DisplayProperties;
	import org.flowplayer.model.EventDispatcher;
	import org.flowplayer.model.Loadable;
	import org.flowplayer.model.PlayerError;
	import org.flowplayer.model.PlayerEvent;
	import org.flowplayer.model.Playlist;
	import org.flowplayer.model.Plugin;
	import org.flowplayer.model.PluginFactory;
	import org.flowplayer.model.ProviderModel;
	import org.flowplayer.model.State;
	import org.flowplayer.model.Status;
	import org.flowplayer.util.Assert;
	import org.flowplayer.util.Log;
	import org.flowplayer.util.LogConfiguration;
	import org.flowplayer.util.TextUtil;
	import org.flowplayer.util.URLUtil;
	import org.flowplayer.view.Panel;
	
	import flash.display.DisplayObject;
	import flash.display.Stage;
	import flash.text.TextField;
	import flash.utils.getDefinitionByName;		
	
	use namespace flow_internal;

	/**
	 * @author anssi
	 */
	public class FlowplayerBase extends PlayerEventDispatcher implements ErrorHandler {

		protected var _playListController:PlayListController;
		protected var _pluginRegistry:PluginRegistry;
		protected var _config:Config;
		protected var _animationEngine:AnimationEngine;
		protected var _panel:Panel;

		private static var _instance:FlowplayerBase = null;
		private var _stage:Stage;
		private var _errorHandler:ErrorHandler;
		private var _fullscreenManager:FullscreenManager;
		private var _pluginLoader:PluginLoader;
		private var _playerSWFBaseURL:String;

		public function FlowplayerBase(
			stage:Stage, 
			control:PlayListController, 
			pluginRegistry:PluginRegistry, 
			panel:Panel, 
			animationEngine:AnimationEngine, 
			errorHandler:ErrorHandler, 
			config:Config, 
			fullscreenManager:FullscreenManager,
			pluginLoader:PluginLoader,
			playerSWFBaseURL:String) {

			// dummy references to get stuff included in the lib
			Assert.notNull(1);
			URLUtil.isCompleteURLWithProtocol("foo");
			
			var plug:Plugin;
			var plugFac:PluginFactory;
			var style:FlowStyleSheet;
			var styleable:StyleableSprite;
			
			if (_instance) {
				log.error("Flowplayer already instantiated");
				throw new Error("Flowplayer already instantiated");
			}
			_stage = stage;
			this._playListController = control;
//			registerCallbacks();
			_pluginRegistry = pluginRegistry;
			_panel = panel;
			_animationEngine = animationEngine;
			_errorHandler = errorHandler;
			_config = config;
			_fullscreenManager = fullscreenManager;
			fullscreenManager.playerEventDispatcher = this;
			_pluginLoader = pluginLoader;
			_playerSWFBaseURL = playerSWFBaseURL;
			_instance = this;
		}
		
		/**
		 * Plays the current clip in playList or the specified clip.
		 * @param clip an optional clip to play. If specified it will replace the player's
		 * playlist.
		 */
		public function play(clip:Clip = null):FlowplayerBase {
			log.debug("play(" + clip + ")");
			_playListController.play(clip);
			return this;
		}

		/**
		 * Starts buffering the current clip in playList.
		 */
		public function startBuffering():FlowplayerBase {
			log.debug("startBuffering()");
			_playListController.startBuffering();
			return this;
		}

		/**
		 * Stops buffering.
		 */
		public function stopBuffering():FlowplayerBase {
			log.debug("stopBuffering()");
			_playListController.stopBuffering();
			return this;
		}
		
		/**
		 * Pauses the current clip.
		 */
		public function pause():FlowplayerBase {
			log.debug("pause()");
			_playListController.pause();
			return this;
		}
		
		/**
		 * Resumes playback of the current clip.
		 */
		public function resume():FlowplayerBase {
			log.debug("resume()");
			_playListController.resume();
			return this;
		}
		
		/**
		 * Toggles between paused and resumed states.
		 * @return true if the player is playing after the call, false if it's paused
		 */
		public function toggle():Boolean {
			if (state == State.PAUSED) {
				resume();
				return true;
			} else if (state == State.PLAYING) {
				pause();
				return false;
			} else if (state == State.WAITING) {
				play();
				return true;
			}
			return false;
		}
		
		/**
		 * Is the player currently paused?
		 * @return true if the player is currently in the paused state
		 * @see #state
		 */
		public function isPaused():Boolean {
			return state == State.PAUSED;
		}

		/**
		 * Is the player currently playing?
		 * @return true if the player is currently in the playing or buffering state
		 * @see #state
		 */
		public function isPlaying():Boolean {
			return state == State.PLAYING || state == State.BUFFERING;
		}

		/**
		 * Stops the player and rewinds to the beginning of the playList.
		 */
		public function stop():FlowplayerBase {
			log.debug("stop()");
			_playListController.stop();
			return this;
		}		
		/**
		 * Stops the player and closes the stream and connection.
		 */		public function close():FlowplayerBase {
			log.debug("close()");
			_playListController.close();
			return this;
		}
		
		/**
		 * Moves to next clip in playList.
		 */
		public function next():Clip {
			log.debug("next()");
			return _playListController.next(false);
		}
		
		/**
		 * Moves to previous clip in playList.
		 */
		public function previous():Clip {
			log.debug("previous()");
			return _playListController.previous();
		}
		
		/**
		 * Toggles between the full-screen and normal display modeds.
		 */
		public function toggleFullscreen():FlowplayerBase {
			log.debug("toggleFullscreen");
			if (dispatchBeforeEvent(PlayerEvent.fullscreen())) {
				_fullscreenManager.toggleFullscreen();
			}
			return this;
		}
		
		/**
		 * Is the volume muted?
		 */
		public function get muted():Boolean {
			return _playListController.muted;
		}
		
		/**
		 * Sets the volume muted/unmuted.
		 */
		public function set muted(value:Boolean):void {
			_playListController.muted = value;
		}
		
		/**
		 * Sets the volume to the specified level.
		 * @param volume the new volume value, must be between 0 and 100
		 */
		public function set volume(volume:Number):void {
			_playListController.volume = volume;
		}
		
		/**
		 * Gets the current volume level.
		 * @return the volume level percentage (0-100)
		 */
		public function get volume():Number {
			log.debug("get volume");
			return _playListController.volume;
		}
		
		/**
		 * Shows the specified plugin display object on the panel.
		 * @param disp the display object to show
		 * @param props the DisplayProperties to be used
		 */
		public function showPlugin(disp:DisplayObject, props:DisplayProperties = null):void {
			disp.alpha = props ? props.alpha : 1;
			disp.visible = true;
			props.display = "block";
			if (props.zIndex == -1) {
				props.zIndex = newPluginZIndex;
			}
			log.debug("showPlugin, zIndex is " + props.zIndex);
			_panel.addView(disp, null, props);
			_pluginRegistry.updateDisplayProperties(props);
		}
		/**
		 * Removes the specified plguin display object from the panel.
		 * @param view the display object to remove
		 * @param props the {@link DisplayProperties display properties} to be used
		 */
		public function hidePlugin(disp:DisplayObject):void {
			_panel.removeView(disp);
			var props:DisplayProperties = _pluginRegistry.getPluginByDisplay(disp);
			if (props) {
				props.display = "none";
				_pluginRegistry.updateDisplayProperties(props);
			}
		}
		
		/**
		 * Shows or hides the specied display object to/from the panel.
		 * @param the display objet to be shown/hidden
		 * @param props the DisplayProperties to be used if the plugin will be shown
		 * @return <code>true</code> if the display object was shown, <code>false</code> if it went hidden
		 * @see #showPlugin
		 * @see #hidePlugin
		 */
		public function togglePlugin(disp:DisplayObject, props:DisplayProperties = null):Boolean {
			if (disp.parent == _panel) {
				hidePlugin(disp);
				return false;
			} else {
				showPlugin(disp, props);
				return true;
			}
		}
		
		
		/**
		 * Gets the animation engine.
		 */
		public function get animationEngine():AnimationEngine {
			return _animationEngine;
		}

		/**
		 * Gets the plugin registry.
		 */
		public function get pluginRegistry():PluginRegistry {
			return _pluginRegistry;
		}

		/**
		 * Seeks to the specified target second value in the clip's timeline.
		 */
		public function seek(seconds:Number):FlowplayerBase {
			log.debug("seek to " + seconds + " seconds");
			_playListController.seekTo(seconds);
			return this;
		}
		
		/**
		 * Seeks to the specified point.
		 * @param the point in the timeline, between 0 and 100
		 */
		public function seekRelative(value:Number):FlowplayerBase {
			log.debug("seekRelative " + value + "%, clip is " + playlist.current);
			seek(playlist.current.duration * (value/100));
			return this;
		}

		/**
		 * Gets the current status {@link PlayStatus}
		 */
		public function get status():Status {
			return _playListController.status;
		}

		/**
		 * Gets the player state.
		 */
		public function get state():State {
			return _playListController.getState();
		}

		/**
		 * Gets the playList.
		 */
		public function get playlist():Playlist {
			return _playListController.playlist;
		}

		/**
		 * Gets the current clip (the clip currently playing or the next one to be played when playback is started).
		 */
		public function get currentClip():Clip {
			return playlist.current;
		}
		
		/**
		 * Shows the specified error message in the player area.
		 */
		public function showError(message:String):void {
			_errorHandler.showError(message);
		}

		/**
		 * Handles the specified error.
		 */
		public function handleError(error:PlayerError, info:Object = null, throwError:Boolean = true):void {
			_errorHandler.handleError(error, info);
		}

		/**
		 * Gets the Flowplayer version number.
		 * @return for example [3, 0, 0, "free", "release"] - the 4th element
		 * tells if this is the "free" version or "commercial", the 5th
		 * element specifies if this is an official "release" or a "development" version.
		 */
		public function get version():Array {
			// this is hacked like this because we cannot have imports to classes
			// that are conditionally compiled - otherwise this class cannot by compiled by compc
			// library compiler
			var VersionInfo:Class = Class(getDefinitionByName("org.flowplayer.config.VersionInfo"));
			return VersionInfo.version;
		}

		/**
		 * Gets the player's id.
		 */
		public function get id():String {
			return _config.playerId;
		}
		
		/**
		 * Loads the specified plugin.
		 * @param plugin the plugin to load
		 * @param callback a function to call when the loading is complete
		 */
		public function loadPlugin(pluginName:String, url:String, callback:Function):void {
			loadPluginLoadable(new Loadable(pluginName, _config, url), callback);
		}
		
		/**
		 * Creates a text field with default font. If the player configuration has a FontProvider
		 * plugin configured, we'll use that. Otherwise platform fonts are used, the platform font
		 * search string used to specify the font is:
		 * "Trebuchet MS, Lucida Grande, Lucida Sans Unicode, Bitstream Vera, Verdana, Arial, _sans, _serif"
		 */
		public function createTextField(fontSize:int = 12, bold:Boolean = false):TextField {
			if (fonts && fonts.length > 0) {
				return TextUtil.createTextField(true, fonts[0], fontSize, bold);
			}
			return TextUtil.createTextField(false, null, fontSize, bold);
		}

		protected function loadPluginLoadable(loadable:Loadable, callback:Function = null):void {
			var loaderCallback:Function = function():void {
				log.debug("plugin loaded");
				_pluginRegistry.setPlayerToPlugin(loadable.plugin);
				if (loadable.plugin is DisplayPluginModel) {
					var displayPlugin:DisplayPluginModel = loadable.plugin as DisplayPluginModel;
					if (displayPlugin.visible) {
						log.debug("adding plugin to panel");
						if (displayPlugin.zIndex < 0) {
							displayPlugin.zIndex = newPluginZIndex;
						}
						_panel.addView(displayPlugin.getDisplayObject(), null,  displayPlugin);
					}
				} else if (loadable.plugin is ProviderModel){
					_playListController.addProvider(loadable.plugin as ProviderModel);
				}
				
				if (callback != null) {
					callback(loadable.plugin); 				
				}
			};
			_pluginLoader.loadPlugin(loadable, loaderCallback);
		}				private function get newPluginZIndex():Number {
			var play:DisplayProperties = _pluginRegistry.getPlugin("play") as DisplayProperties;
			if (! play) return 100;
			return play.zIndex;
		}
		/**
		 * Gets the fonts that have been loaded as plugins.
		 */
		public function get fonts():Array {
			return _pluginRegistry.fonts;
		}
		
		/**
		 * Is the player in fullscreen mode?
		 */
		public function isFullscreen():Boolean {
			return _fullscreenManager.isFullscreen;
		}
		
		/**
		 * Resets the screen and the controls to their orginal display properties
		 */
		public function reset(pluginNames:Array = null, speed:Number = 500):void {
			if (! pluginNames) {
				pluginNames = [ "controls", "screen" ];
			}
			for (var i:Number = 0; i < pluginNames.length; i++) {
				resetPlugin(pluginNames[i], speed);
			}
		}
		
		/**
		 * Configures logging.
		 */
		public function logging(level:String, filter:String = "*"):void {
			var config:LogConfiguration = new LogConfiguration();
			config.level = level;
			config.filter = filter;
			Log.configure(config);
		}
		
		/**
		 * Flowplayer configuration.
		 */
		public function get config():Config {
			return _config;
		}

		/**
		 * Resource loader.
		 */		
		public function createLoader():ResourceLoader {
			return new ResourceLoaderImpl(_config.playerId ? null : _playerSWFBaseURL, this);
		}

		private function resetPlugin(pluginName:String, speed:Number = 500):void {
			var props:DisplayProperties = _pluginRegistry.getOriginalProperties(pluginName) as DisplayProperties;
			if (props) {
				_animationEngine.animate(props.getDisplayObject(), props, speed);
			}
		}

		protected function checkPlugin(plugin:Object, pluginName:String, RequiredClass:Class = null):void {
			if (! plugin) {
				showError("There is no plugin called '" + pluginName + "'");
				return;
			}
			if (RequiredClass && ! plugin is RequiredClass) {
				showError("Specifiec plugin '" + pluginName + "' is not an instance of " + RequiredClass);
			}
		}
		
//
//		private function onFullScreen(event:FullScreenEvent):void {
//			_eventHub.handlePlayerEvent(event.fullScreen ? PlayerEvent.fullscreen() : PlayerEvent.fullscreenExit());
//		}
//		
//		private function onPluginEvent(event:PluginEvent):void {
//			ExternalEvent.firePluginEvent(id, event.pluginName, event.methodName, null, event.eventObject);
//		}
	}
}
