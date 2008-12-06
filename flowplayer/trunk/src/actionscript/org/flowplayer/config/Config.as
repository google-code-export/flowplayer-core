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
	
	import org.flowplayer.config.PluginBuilder;
	import org.flowplayer.model.Clip;
	import org.flowplayer.model.DisplayProperties;
	import org.flowplayer.model.Logo;
	import org.flowplayer.model.PlayButtonOverlay;
	import org.flowplayer.model.Playlist;
	import org.flowplayer.model.PluginModel;
	import org.flowplayer.util.Assert;
	import org.flowplayer.util.LogConfiguration;
	import org.flowplayer.util.PropertyBinder;		

	/**
	 * @author anssi
	 */
	public class Config {

		private var playList:Playlist;
		private var config:Object;
		private var _pluginBuilder:PluginBuilder;
		private var _playlistBuilder:PlaylistBuilder;
		public var logFilter:String;
		private var _playerSwfName:String;
		private var _controlsVersion:String;
		private var _audioVersion:String;

		public function Config(config:Object, playerSwfName:String, controlsVersion:String, audioVersion:String) {
			Assert.notNull(config, "No configuration provided.");
			this.config = config;
			_playerSwfName = playerSwfName;
			_playlistBuilder = new PlaylistBuilder(playerId, config.playlist, config.clip);
			_controlsVersion = controlsVersion;
			_audioVersion = audioVersion;
		}

		public function get playerId():String {
			return this.config.playerId;
		}

		public function createClip(clipObj:Object):Clip {
			return _playlistBuilder.createClip(clipObj);
		}
		
		public function createCuepoints(cueObjects:Array, callbackId:String):Array {
			return _playlistBuilder.createCuepointGroup(cueObjects, callbackId);
		}

		public function getPlaylist(clipObjects:Array = null):Playlist {
			if (clipObjects) {
				_playlistBuilder = new PlaylistBuilder(playerId, clipObjects, config.clip);
				playList = _playlistBuilder.createPlaylist();
			} else if (! playList) {
				playList = _playlistBuilder.createPlaylist();
			}
			return playList;
		}
		
		public function getLoadables():Array {
			return viewObjectBuilder.createLoadables(config.plugins, getPlaylist());
		}
		
		private function get viewObjectBuilder():PluginBuilder {
			if (_pluginBuilder == null) {
				_pluginBuilder = new PluginBuilder(_playerSwfName, _controlsVersion, _audioVersion, this, config.plugins, config);
			}
			return _pluginBuilder;
		}
		
		public function getScreenProperties():DisplayProperties {
			return viewObjectBuilder.getScreen(getObject("screen"));
		}

		public function getPlayButtonOverlay():PlayButtonOverlay {
			var play:PlayButtonOverlay = viewObjectBuilder.getDisplayProperties(getObject("play"), "play", PlayButtonOverlay) as PlayButtonOverlay;
			if (play) {
				play.buffering = useBufferingAnimation;
			}
			return play;
		}
		
		public function getLogo():Logo {
			return viewObjectBuilder.getDisplayProperties(getObject("logo"), "logo", Logo) as Logo;
		}
		
		public function getObject(name:String):Object {
			return config[name];
		}
		
		public function getLogConfiguration():LogConfiguration {
			if (! config.log) return new LogConfiguration();
			return new PropertyBinder(new LogConfiguration(), null).copyProperties(config.log) as LogConfiguration;
		}
		
		public function get licenseKey():String {
			return config.key;
		}
		
		public function get canvasStyle():Object {
			var style:Object = getObject("canvas");
			if (! style) {
				style = new Object();
			}
			setProperty("backgroundGradient", style, [ 0.3, 0 ]);
			setProperty("border", style, "0px");
			setProperty("backgroundColor", style, "transparent");
			setProperty("borderRadius", style, "0");
			return style;
		}
		
		private function setProperty(prop:String, style:Object, value:Object):void {
			if (! style[prop]) {
				style[prop] = value;
			}
		}
		
		public function get contextMenu():Array {
			return getObject("contextMenu") as Array;
		}
				public function getPlugin(disp:DisplayObject, name:String, config:Object):PluginModel {
			return viewObjectBuilder.getPlugin(disp, name, config);
		}
		
		public function get showErrors():Boolean {
			if (! config.hasOwnProperty("showErrors")) return true;
			return config["showErrors"];  
		}
		
		private function get useBufferingAnimation():Boolean {
			if (! config.hasOwnProperty("buffering")) return true;
			return config["buffering"];
		}
	}
}
