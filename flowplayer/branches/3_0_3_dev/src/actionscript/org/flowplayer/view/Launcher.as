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
	import org.flowplayer.model.Loadable;	
	import org.flowplayer.model.ProviderModel;	
	import org.flowplayer.config.Config;
	import org.flowplayer.config.ConfigLoader;
	import org.flowplayer.config.ExternalInterfaceHelper;
	import org.flowplayer.config.VersionInfo;
	import org.flowplayer.controller.NetStreamControllingStreamProvider;
	import org.flowplayer.controller.PlayListController;
	import org.flowplayer.controller.ResourceLoader;
	import org.flowplayer.controller.ResourceLoaderImpl;
	import org.flowplayer.flow_internal;
	import org.flowplayer.model.Callable;
	import org.flowplayer.model.Clip;
	import org.flowplayer.model.ClipEvent;
	import org.flowplayer.model.DisplayPluginModel;
	import org.flowplayer.model.DisplayProperties;
	import org.flowplayer.model.DisplayPropertiesImpl;
	import org.flowplayer.model.EventDispatcher;
	import org.flowplayer.model.Logo;
	import org.flowplayer.model.PlayButtonOverlay;
	import org.flowplayer.model.PlayerError;
	import org.flowplayer.model.PlayerEvent;
	import org.flowplayer.model.Playlist;
	import org.flowplayer.model.Plugin;
	import org.flowplayer.model.PluginError;
	import org.flowplayer.model.PluginEvent;
	import org.flowplayer.model.PluginModel;
	import org.flowplayer.model.State;
	import org.flowplayer.util.Arrange;
	import org.flowplayer.util.Log;
	import org.flowplayer.util.TextUtil;
	import org.flowplayer.util.URLUtil;
	import org.flowplayer.view.Panel;
	import org.flowplayer.view.Screen;
	import org.osflash.thunderbolt.Logger;
	
	import flash.display.DisplayObject;
	import flash.display.DisplayObjectContainer;
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.events.KeyboardEvent;
	import flash.events.MouseEvent;
	import flash.events.TimerEvent;
	import flash.net.URLRequest;
	import flash.net.navigateToURL;
	import flash.system.Capabilities;
	import flash.system.Security;
	import flash.text.TextField;
	import flash.text.TextFieldAutoSize;
	import flash.ui.Keyboard;
	import flash.utils.Dictionary;
	import flash.utils.Timer;		
	use namespace flow_internal;

	public class Launcher extends StyleableSprite implements ErrorHandler {
		private var _panel:Panel;
		private var _screen:Screen;
		private var _config:Config;
		private var _flowplayer:Flowplayer;
		private var _pluginRegistry:PluginRegistry;
		private var _animationEngine:AnimationEngine;
		private var _playButtonOverlay:PlayButtonOverlay;
		private var _controlsModel:DisplayPluginModel;		private var _providers:Dictionary = new Dictionary();
		private var _fullscreenManager:FullscreenManager;
		private var _canvasLogo:Sprite;
		private var _pluginLoader:PluginLoader;
		private var _error:TextField;
		private var _pluginsInitialized:Number = 0;
		private var _numLoadablePlugins:int = -1;
		[Frame(factoryClass="org.flowplayer.view.Preloader")]
		public function Launcher() {
			super("#canvas", this);
			addEventListener(Event.ADDED_TO_STAGE, initPhase1);
		}

		private function initPhase1(event:Event):void {
			createFlashVarsConfig();
			Log.configure(_config.getLogConfiguration());

			if (_config.playerId) {
				Security.allowDomain(URLUtil.pageUrl);
			}
			
			_config.getPlaylist().onBeforeBegin(function(event:ClipEvent):void { hideErrorMessage(); });

			loader = createNewLoader(); 

			rootStyle = _config.canvasStyle;
			stage.addEventListener(Event.RESIZE, onStageResize);
			setSize(stage.stageWidth, stage.stageHeight);

			if (! VersionInfo.commercial) {
				log.debug("Adding logo to canvas");
				createLogoForCanvas();
			}

			log = new Log(this);
			EventDispatcher.playerId = _config.playerId;
			
			log.debug("security sandbox type: " + Security.sandboxType);
			
			log.info(VersionInfo.versionInfo());
			log.debug("creating Panel");

			createPanel();
			_pluginRegistry = new PluginRegistry(_panel);
			
			log.debug("Creating animation engine");
			createAnimationEngine(_pluginRegistry);
			
			log.debug("creating play button overlay");
			createPlayButtonOverlay();
			
			log.debug("creating screen");
			createScreen();
			
			loadPluginsIfConfigured();
		}

		private function initPhase2(pluginsLoadedEvent:Event = null):void {
			_pluginLoader.removeEventListener(Event.COMPLETE, this.initPhase2);
			
			log.debug("creating PlayListController");
			_providers = _pluginLoader.providers;
			var playListController:PlayListController = createPlayListController();
			
			addPlayListListeners();
			createFullscreenManager(playListController.playlist);
			
			log.debug("creating Flowplayer API");
			createFlowplayer(playListController);

			addScreenToPanel();

			if (!validateLicenseKey()) {
				createLogoForCanvas();
				resizeCanvasLogo();
			}
			
			log.debug("creating logo");
			createLogo();
			
			contextMenu = new ContextMenuBuilder(_config.playerId, _config.contextMenu).build();
			
			log.debug("initializing ExternalInterface");
			if (useExternalInterfade()) {
				_flowplayer.initExternalInterface();
			}

			log.debug("calling onLoad to plugins");
			_pluginRegistry.onLoad(_flowplayer);
		}

		private function initPhase3(event:Event = null):void {
			
			log.debug("Adding visible plugins to panel");
			addPluginsToPanel(_pluginRegistry);
			
			log.debug("arranging screen");
			arrangeScreen();
			
			log.debug("dispatching onLoad");
			if (useExternalInterfade()) {
				_flowplayer.dispatchEvent(PlayerEvent.load("player"));
			} 

			log.debug("starting configured streams");
			startStreams();

			stage.addEventListener(KeyboardEvent.KEY_DOWN, onKeyDown);
			addListeners();
		}

		private function resizeCanvasLogo():void {
			_canvasLogo.alpha = 1;
			_canvasLogo.width = 150;
			_canvasLogo.scaleY = _canvasLogo.scaleX;
			arrangeCanvasLogo();
		}

		private function useExternalInterfade():Boolean {
			log.debug("useExternalInteface: " + (_config.playerId != null));
			return _config.playerId != null;
		}

		private function onStageResize(event:Event = null):void {
			setSize(stage.stageWidth, stage.stageHeight);
			arrangeCanvasLogo();
		}

		private function arrangeCanvasLogo():void {
			if (!_canvasLogo) return;
			_canvasLogo.x = 15;
			_canvasLogo.y = stage.stageHeight - (_controlsModel ? _controlsModel.dimensions.height.toPx(stage.stageHeight) + 10 : 10) - _canvasLogo.height;
		}

		private function loadPluginsIfConfigured():void {
			var plugins:Array = _config.getLoadables();
			log.info("will load following plugins: ");
			for (var i:Number = 0; i < plugins.length; i++) {
				log.info("" + plugins[i]);
			}
			_pluginLoader = new PluginLoader(URLUtil.playerBaseUrl(loaderInfo), _pluginRegistry, this, useExternalInterfade(), onPluginLoad, onPluginLoadError);
			_pluginLoader.addEventListener(Event.COMPLETE, initPhase2);
			if (plugins.length == 0) {
				log.debug("configuration has no plugins");
				initPhase2();
			} else {
				log.debug("loading plugins and providers");
				_pluginLoader.load(plugins);
			}
		}
		
		private function onPluginLoad(event:PluginEvent):void {
			var plugin:PluginModel = event.target as PluginModel;
			log.info("plugin " + plugin + " initialized");
			checkPluginsInitialized();
		}

		private function onPluginLoadError(event:PluginEvent):void {
			if (! event.hasError(PluginError.INIT_FAILED)) return;
			
			var plugin:PluginModel = event.target as PluginModel;
			log.warn("load/init error on " + plugin);
			_pluginRegistry.removePlugin(plugin);
			checkPluginsInitialized();
		}
		
		private function checkPluginsInitialized():void {
			var numPlugins:int = getLoadablePluginCount();
			
			if (++_pluginsInitialized == numPlugins) {
				log.info("all plugins initialized");
				initPhase3();
			}
			log.info(_pluginsInitialized + " out of " + numPlugins + " plugins initialized");
		}
		
		private function getLoadablePluginCount():int {
			if (_numLoadablePlugins == -1) {
				_numLoadablePlugins = countLoadablePlugins();
			}
			return _numLoadablePlugins;
		}
		
		private function countLoadablePlugins():int {
			var count:Number = 0;
			var loadables:Array = _config.getLoadables();
			for (var i:Number = 0; i < loadables.length; i++) {

				var plugin:PluginModel = Loadable(loadables[i]).plugin;
				var isNonAdHocPlugin:Boolean = (plugin is DisplayPluginModel && DisplayPluginModel(plugin).getDisplayObject() is Plugin) ||
					plugin is ProviderModel && ProviderModel(plugin).getProviderObject() is Plugin;

				if (isNonAdHocPlugin) {
					log.debug("will wait for onLoad from plugin " + plugin);
					count++;
				} else {
					log.debug("will NOT wait for onLoad from plugin " + Loadable(loadables[i]).plugin);
				}
			}
			// +1 comes from the playbuttonoverlay
			return count + (_playButtonOverlay ? 1 : 0);
		}
		
		private function playerSwfName():String {
			var url:String = loaderInfo.url;
			var lastSlash:Number = url.lastIndexOf("/");
			return url.substring(lastSlash + 1, url.indexOf(".swf") + 4); 
		}

		private function validateLicenseKey():Boolean {
			try {
				return LicenseKey.validate(useExternalInterfade() ? null: root.loaderInfo.url, _flowplayer.version, _config.licenseKey);
			} catch (e:Error) {
				log.warn("License key not accepted, will show flowplayer logo");
			}
			return false;
		}

		private function createFullscreenManager(playlist:Playlist):void {
			_fullscreenManager = new FullscreenManager(stage, playlist, _panel, _pluginRegistry, _animationEngine);
		}

		public function showError(message:String):void {
			if (! _panel) return;
			if (! _config.showErrors) return;
			if (_error && _error.parent == this) {
				removeChild(_error);
			}
			
			_error = TextUtil.createTextField(false);
			_error.background = true;
			_error.backgroundColor = 0;
			_error.textColor = 0xffffff;
			_error.autoSize = TextFieldAutoSize.CENTER;
			_error.multiline = true;
			_error.wordWrap = true;
			_error.text = message;
			_error.selectable = true;
			_error.width = stage.stageWidth - 40;
			Arrange.center(_error, stage.stageWidth, stage.stageHeight);
			addChild(_error);
			
			createErrorMessageHideTimer();
		}				private function createErrorMessageHideTimer():void {
			var errorHideTimer:Timer = new Timer(4000, 1);
			errorHideTimer.addEventListener(TimerEvent.TIMER_COMPLETE, hideErrorMessage);
			errorHideTimer.start();
		}

		private function hideErrorMessage(event:TimerEvent = null):void {
			if (_error && _error.parent == this) {
				if (_animationEngine) {
					_animationEngine.fadeOut(_error, 1000, function():void { removeChild(_error); });
				} else {
					removeChild(_error);
				}
			}
		}

		public function handleError(error:PlayerError, info:Object = null, throwError:Boolean = true):void {
			if (_flowplayer) {
				_flowplayer.dispatchError(error, info);
			} else {
				// initialization is not complete, create a dispatches just to dispatch this error
				new PlayerEventDispatcher().dispatchError(error, info);
			}
			doHandleError(error.code + ": " + error.message + ( info ? ": " + info : ""), throwError);
		}

		private function doHandleError(message:String, throwError:Boolean = true):void {
			if (_config && _config.playerId) {
				Logger.error(message);
			}
			showError(message);
			if (_flowplayer) {
				_flowplayer.stop();
			}
			if (throwError && Capabilities.isDebugger) {
				throw new Error(message);
			}
		}

		private function createAnimationEngine(pluginRegistry:PluginRegistry):void {
			_animationEngine = new AnimationEngine(_panel, pluginRegistry);
		}

		private function addPluginsToPanel(_pluginRegistry:PluginRegistry):void {
			for each (var pluginObj:Object in _pluginRegistry.plugins) {
				if (pluginObj is DisplayPluginModel) {
					var model:DisplayPluginModel = pluginObj as DisplayPluginModel;
					log.debug("adding plugin '"+ model.name +"' to panel: " + model.visible + ", plugin object is " + model.getDisplayObject());
					if (model.visible) {
						if (model.zIndex == -1) {
							model.zIndex = 100;
						}
						_panel.addView(model.getDisplayObject(), undefined, model);
					}
					if (model.name == "controls") {
						_controlsModel = model;
					}
				}
			}
			if (_controlsModel) {
				arrangeCanvasLogo();
			}
		}
		
		private function addScreenToPanel():void {
			// if controls visible and screen was not explicitly configured --> place screen on top of controls
			var screen:DisplayProperties = _pluginRegistry.getPlugin("screen") as DisplayProperties;
			screen.display = "none";
			screen.getDisplayObject().visible = false;
			_panel.addView(screen.getDisplayObject(), null, screen);
		}
		
		private function arrangeScreen():void {
			var screen:DisplayProperties = _pluginRegistry.getPlugin("screen") as DisplayProperties;
			if (_controlsModel && _controlsModel.visible && ! screenTopOrBottomConfigured()) {
				var heightConfigured:Boolean = _config.getObject("screen") && _config.getObject("screen").hasOwnProperty("height"); 
				if (isControlsAlwaysAutoHide() || (_controlsModel.position.bottom.px > 0)) {
					screen.bottom = 0;
					if (! heightConfigured) {
						screen.height =  "100%";
					}
				} else {
					var controlsHeight:Number = _controlsModel.getDisplayObject().height;
					screen.bottom = controlsHeight;
					if (! heightConfigured) {
						screen.height =  ((stage.stageHeight - controlsHeight) / stage.stageHeight) * 100 + "%";
					}
				}
			}
			log.debug("arranging screen to pos " + screen.position);
			screen.display = "block";
			screen.getDisplayObject().visible = true;
			_pluginRegistry.updateDisplayProperties(screen);
			_panel.update(screen.getDisplayObject(), screen);
			_panel.draw(screen.getDisplayObject());
		}

		private function screenTopOrBottomConfigured():Boolean {
			var screen:Object = _config.getObject("screen");
			if (! screen) return false;
			if (screen.hasOwnProperty("top")) return true;
			if (screen.hasOwnProperty("bottom")) return true;
			return false;
		}

		private function isControlsAlwaysAutoHide():Boolean {
			if (!_controlsModel) return false;
			if (!_controlsModel.config) return false;
			log.debug("controlsModel.config.auotoHide == always", (_controlsModel.config.autoHide == 'always'));
			return  _controlsModel.config.autoHide == 'always';
		}

		private function createFlowplayer(playListController:PlayListController):void {
			_flowplayer = new Flowplayer(stage, playListController, _pluginRegistry, _panel, 
				_animationEngine, this, this, _config, _fullscreenManager, _pluginLoader, URLUtil.playerBaseUrl(loaderInfo));
			playListController.playerEventDispatcher = _flowplayer;
		}

		private function createFlashVarsConfig():void {
			for (var prop:String in stage.loaderInfo.parameters) {
				log.debug(prop + ": " + (stage.loaderInfo.parameters[prop]));
			}
			if (! stage.loaderInfo.parameters) {
				return;
			}
			
			_config = ConfigLoader.flow_internal::parseConfig(stage.loaderInfo.parameters["config"], playerSwfName(), VersionInfo.controlsVersion, VersionInfo.audioVersion); 
		}

		private function createPlayListController():PlayListController {
			if (! _providers) {
				_providers = new Dictionary();
			}
			var httpProvider:NetStreamControllingStreamProvider = new NetStreamControllingStreamProvider();
			httpProvider.playerConfig = _config;
			_providers["http"] = httpProvider;
			return new PlayListController(_config.getPlaylist(), _providers, _config, createNewLoader());
		}
		
		private function createScreen():void {
			_screen = new Screen(_config.getPlaylist(), _animationEngine, _playButtonOverlay, _pluginRegistry);
			var screenModel:DisplayProperties = _config.getScreenProperties();
			initView(_screen, screenModel, null, false);
			if (_playButtonOverlay) {
				PlayButtonOverlayView(_playButtonOverlay.getDisplayObject()).setScreen(_screen, hasClip);
			}
//			addViewLiteners(_screen);
		}

		private function createPlayButtonOverlay():void {
			_playButtonOverlay = _config.getPlayButtonOverlay();
			if (! _playButtonOverlay) return;
			
			_playButtonOverlay.onLoad(onPluginLoad);
			_playButtonOverlay.onError(onPluginLoadError);

			log.debug("playlist has clips? " + hasClip);
			var overlay:PlayButtonOverlayView = new PlayButtonOverlayView(! playButtonOverlayWidthDefined(), _playButtonOverlay, _pluginRegistry, _config.getPlaylist(), true);
			initView(overlay, _playButtonOverlay, null, false);
		}
		
		private function playButtonOverlayWidthDefined():Boolean {
			if (! _config.getObject("play")) return false;
			return _config.getObject("play").hasOwnProperty("width");
		}
		
		private function get hasClip():Boolean {
			var firstClip:Clip = _config.getPlaylist().current;
			var hasClip:Boolean = ! firstClip.isNullClip && (firstClip.url || firstClip.provider != 'http');
			return hasClip; 
		}
		
		private function createLogo():void {
			var logo:Logo = _config.getLogo() || new Logo();
			var logoView:LogoView = new LogoView(_panel, logo, _flowplayer);
			initView(logoView, logo, logoView.draw, false);
		}

		private function initView(view:DisplayObject, props:DisplayProperties, resizeListener:Function = null, addToPanel:Boolean = true):void {
			if (props.name != "logo" || VersionInfo.commercial) {
				_pluginRegistry.registerDisplayPlugin(props, view);
			}
			if (addToPanel) {
				_panel.addView(view, resizeListener, props);
			}
			if (props is Callable) {
				ExternalInterfaceHelper.initializeInterface(props as Callable, view);
			}
		}
		
		private function addListeners():void {
			_screen.addEventListener(MouseEvent.CLICK, onViewClicked);
			addEventListener(MouseEvent.ROLL_OVER, onMouseOver);
			addEventListener(MouseEvent.ROLL_OUT, onMouseOut);
			
			// add some color so that the ROLL_OVER/ROLL_OUT events are always triggered
			graphics.beginFill(0, 0);
			graphics.drawRect(0, 0, stage.stageWidth, stage.stageHeight);
			graphics.endFill();
		}
		
		private function onMouseOut(event:MouseEvent):void {
			_flowplayer.dispatchEvent(PlayerEvent.mouseOut());
		}
		private function onMouseOver(event:MouseEvent):void {
			_flowplayer.dispatchEvent(PlayerEvent.mouseOver());
		}
		private function createPanel():void {
			_panel = new Panel();
			addChild(_panel);
		}
		
		private function startStreams():void {
			var canStart:Boolean = true;
			if (_flowplayer.state != State.WAITING) {
				log.debug("streams have been started in player.onLoad(), will not start streams here.");
				canStart = false;
			}
			if (! hasClip) {
				log.info("Configuration has no clips to play.");
				canStart = false;
			}

			var playButton:PlayButtonOverlayView = _playButtonOverlay ? PlayButtonOverlayView(_playButtonOverlay.getDisplayObject()) : null;
			
			if (canStart) {
				if (_flowplayer.currentClip.autoPlay) {
					log.debug("clip is autoPlay");
					_flowplayer.play();
				} else if (_flowplayer.currentClip.autoBuffering) {
					log.debug("clip is autoBuffering");
					_flowplayer.startBuffering();
				} else {
					if (playButton) {
						playButton.stopBuffering();
						playButton.showButton();
					}
				}
			} else {
				// cannot start playing here, stop buffering indicator, don't show the button
				if (playButton) {
					playButton.stopBuffering();
				}
			}
		}
		
		private function addPlayListListeners():void {
			var playlist:Playlist = _config.getPlaylist();
			playlist.onError(onClipError);
		}
		
		private function onClipError(event:ClipEvent):void {
			doHandleError(event.info + ", " + event.info2 + ", " + event.info3 + ", clip: '" + Clip(event.target) + "'");
		}

		private function onViewClicked(event:MouseEvent):void {
			log.debug("onViewClicked, target " + event.target + ", current target " + event.currentTarget);
			if (_playButtonOverlay && isParent(DisplayObject(event.target), _playButtonOverlay.getDisplayObject())) {
				_flowplayer.toggle();
				return;
			}
			
			var clip:Clip = _flowplayer.playlist.current; 
			if (clip.linkUrl) {
				_flowplayer.pause();
				navigateToURL(new URLRequest(clip.linkUrl), clip.linkWindow);
			} else {
				_flowplayer.toggle();
			}
		}
		
		private function isParent(child:DisplayObject, parent:DisplayObject):Boolean {
			if (DisplayObject(child).parent == parent) return true;
			if (! (parent is DisplayObjectContainer)) return false;
			for (var i:Number = 0;i < DisplayObjectContainer(parent).numChildren; i++) {
				var curChild:DisplayObject = DisplayObjectContainer(parent).getChildAt(i);
				if (isParent(child, curChild)) { 
					return true;
				}
			}
			return false;
		}

		private function onKeyDown(event:KeyboardEvent):void {
			log.debug("keydown");
			if (_flowplayer.dispatchBeforeEvent(PlayerEvent.keyPress(event.keyCode))) {
				_flowplayer.dispatchEvent(PlayerEvent.keyPress(event.keyCode));
				if (event.keyCode == Keyboard.SPACE) {
					_flowplayer.toggle();
				}
			}
		}
		
		override protected function onRedraw():void {
			if (bgImageHolder && getChildIndex(bgImageHolder) > getChildIndex(_panel)) {
				swapChildren(bgImageHolder, _panel);
			}
		}
		
		private function createLogoForCanvas():void {
			if (_canvasLogo) return;
			_canvasLogo = new CanvasLogo();
			_canvasLogo.width = 85;
			_canvasLogo.scaleY = _canvasLogo.scaleX;
			_canvasLogo.alpha = .4;
			_canvasLogo.addEventListener(MouseEvent.CLICK, 
				function(event:MouseEvent):void { navigateToURL(new URLRequest("http://flowplayer.org"), "_self"); });
			_canvasLogo.buttonMode = true;
			log.debug("adding logo to display list");
			addChild(_canvasLogo);
			onStageResize();
		}
		
		private function createNewLoader():ResourceLoader {
			return new ResourceLoaderImpl(_config.playerId ? null : URLUtil.playerBaseUrl(loaderInfo), this);
		}
	}
}