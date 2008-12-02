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
	import org.flowplayer.config.Config;	
	import org.flowplayer.model.ClipEventType;	
	import org.flowplayer.view.PlayerEventDispatcher;	
	import org.flowplayer.util.Log;	
	
	import flash.utils.Dictionary;
	
	import org.flowplayer.flow_internal;
	import org.flowplayer.model.Clip;
	import org.flowplayer.model.ClipType;
	import org.flowplayer.model.Playlist;
	import org.flowplayer.model.ProviderModel;	

	/**
	 * @author anssi
	 */
	internal class MediaControllerFactory {

		private var _videoController:MediaController;
		private var _imageController:ImageController;
		private static var _instance:MediaControllerFactory;
		private var _volumeController:VolumeController;
		private var _streamProviders:Dictionary;
		private var _playerEventDispatcher:PlayerEventDispatcher;
		private var _config:Config;
		private var _loader:ResourceLoader;

		use namespace flow_internal;
		
		public function MediaControllerFactory(providers:Dictionary, playerEventDispatcher:PlayerEventDispatcher, config:Config, loader:ResourceLoader) {
			_streamProviders = providers;
			_instance = this;
			_playerEventDispatcher = playerEventDispatcher;
			_volumeController = new VolumeController(_playerEventDispatcher);
			_config = config;
			_loader = loader;
		}

		flow_internal function getMediaController(clip:Clip, playlist:Playlist):MediaController {
			var clipType:ClipType = clip.type;
			if (clipType == ClipType.VIDEO || clipType == ClipType.AUDIO) {
				return getStreamProviderController(playlist);
			}
			if (clipType == ClipType.IMAGE) {
				return getImageController(playlist);
			}
			throw new Error("No media controller found for clip type " + clipType);
			return null;
		}
		
		flow_internal function getVolumeController():VolumeController {
			return _volumeController;
		}
		
		private function getStreamProviderController(playlist:Playlist):MediaController {
			if (!_videoController) {
				_videoController = new StreamProviderController(this, getVolumeController(), _config, playlist);
			}
			return _videoController;
		}
		
		private function getImageController(playlist:Playlist):MediaController {
			if (!_imageController)
				_imageController = new ImageController(_loader, getVolumeController(), playlist);
			return _imageController;
		}
		
		internal function addProvider(provider:ProviderModel):void {
			_streamProviders[provider.name] = provider.getProviderObject();
		}
		
		public function getProvider(clip:Clip):StreamProvider {
			var provider:StreamProvider = _streamProviders[clip.provider];
			if (! provider) {
				clip.dispatch(ClipEventType.ERROR, "Provider '" + clip.provider + "' not found");
				return null;
			}
			provider.volumeController = getVolumeController();
			return provider;
		}
	}
}
