/*    
 *    Copyright (c) 2008, 2009 Flowplayer Oy
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
	import flash.utils.Dictionary;
	
	import org.flowplayer.config.Config;
	import org.flowplayer.controller.MediaController;
	import org.flowplayer.controller.MediaControllerFactory;
	import org.flowplayer.controller.PlayListController;
	import org.flowplayer.flow_internal;
	import org.flowplayer.model.Clip;
	import org.flowplayer.model.ClipEvent;
	import org.flowplayer.model.ClipEventSupport;
	import org.flowplayer.model.ClipEventType;
	import org.flowplayer.model.Playlist;
	import org.flowplayer.model.ProviderModel;
	import org.flowplayer.model.State;
	import org.flowplayer.model.Status;
	import org.flowplayer.util.Assert;
	import org.flowplayer.util.Log;
	import org.flowplayer.view.PlayerEventDispatcher;		
	use namespace flow_internal;	
	
	/**
	 * PlayStates are responsible for controlling the media playback of one clip.
	 * The states delegate to MediaControllers. PlayStates also dispatch PlayEvents.
	 * 
	 * 
	 * @author api
	 */
	internal class PlayState {
		
		protected var log:Log = new Log(this);
		protected var playListController:PlayListController;
		protected var playList:Playlist;
		//private var screen:Screen;
		
		internal static var waitingState:PlayState;
		internal static var endedState:EndedState;
		internal static var playingState:PlayingState;
		internal static var pausedState:PausedState;
		internal static var bufferingState:BufferingState;
		private static var _controllerFactory:MediaControllerFactory;
		private var _stateCode:State;
		private var _active:Boolean;

		internal static function initStates(playList:Playlist, playListController:PlayListController, providers:Dictionary, playerEventDispatcher:PlayerEventDispatcher, config:Config, loader:ResourceLoader):void {
			waitingState = new WaitingState(State.WAITING, playList, playListController, providers);
			endedState = new EndedState(State.ENDED, playList, playListController, providers);
			playingState = new PlayingState(State.PLAYING, playList, playListController, providers);
			pausedState = new PausedState(State.PAUSED, playList, playListController, providers);
			bufferingState = new BufferingState(State.BUFFERING, playList, playListController,  providers);
			playListController.setPlayState(waitingState);
			if (!_controllerFactory)
				_controllerFactory = new MediaControllerFactory(providers, playerEventDispatcher, config, loader);
		}
		
		internal static function addProvider(provider:ProviderModel):void {
			_controllerFactory.addProvider(provider);
		}

		public function PlayState(stateCode:State, playList:Playlist, playListController:PlayListController, providers:Dictionary) {
			this._stateCode = stateCode;
			this.playList = playList;
            playList.onPlaylistReplace(onPlaylistChanged);
            playList.onClipAdd(onClipAdded);
			this.playListController = playListController;
		}

		internal final function set active(active:Boolean):void {
			log.debug(" is active: " + active);
			_active = active;
			if (active) {
				playList.onBeforeFinish(onClipDone);
			} else {
				playList.unbind(onClipDone, ClipEventType.FINISH, true);
			}
			setEventListeners(playList, active);			
		}

		protected function setEventListeners(eventHelper:ClipEventSupport, add:Boolean = true):void {
			// overridden in subclasses
		}

		internal function get state():State {
			return _stateCode;
		}
		
		internal function startBuffering():void {
			log.debug("cannot start buffering in this state");
		}
		
		internal function stopBuffering():void {
			log.debug("cannot stop buffering in this state");
		}
		
		internal function play():void {
			log.debug("cannot start playing in this state");
		}
		
		internal function stop(closeStreamAndConnection:Boolean = false, silent:Boolean = false):void {
			log.debug("stop() called");
			if (silent) {
				getMediaController().onEvent(null, [closeStreamAndConnection]);
				return;
			}
			if (onEvent(ClipEventType.STOP, getMediaController(), [closeStreamAndConnection])) {
				changeState(waitingState);
			}
		}
		
		internal function close():void {
			if (onEvent(ClipEventType.STOP, getMediaController(), [true, true])) {
				changeState(waitingState);
			}
		}
		
		internal function pause():void {
			log.debug("cannot pause in this state");
		}
		
		internal function resume():void {
			log.debug("cannot resume in this state");
		}
		
		internal function seekTo(seconds:Number):void {
			log.debug("cannot seek in this state");
		}
		
		internal function get muted():Boolean {
			return _controllerFactory.getVolumeController().muted;
		}
		
		internal function set muted(value:Boolean):void {
			_controllerFactory.getVolumeController().muted = value;
		}

		internal function set volume(volume:Number):void {
			_controllerFactory.getVolumeController().volume = volume;
		}

		internal function get volume():Number {
			return _controllerFactory.getVolumeController().volume;
		}

		internal function get status():Status {
			var status:Status = getMediaController().getStatus(_stateCode);
			return status;
		}

		protected function onEvent(eventType:ClipEventType, mediaController:MediaController = null, params:Array = null):Boolean {
			Assert.notNull(eventType, "eventType must be non-null");
			if (playList.current.isNullClip) return false;
			
			if (eventType.isCancellable) {
				if (! playList.current.dispatchBeforeEvent(new ClipEvent(eventType))) {
					log.info("event default was prevented, will not execute a state change");
					return false;
				}
			}
			log.debug("calling onEvent(" + eventType + ") on media controller");
			(mediaController || getMediaController()).onEvent(eventType, params);
			return true;
		}

		protected function changeState(newState:PlayState):void {
			if (playListController.getPlayState() != newState) {
				playListController.setPlayState(newState);
			}
		}

		internal function dispatchPlayEvent(eventType:ClipEventType):void {
			var clip:Clip = playList.current;
			log.debug("dispatching " + eventType);
			clip.dispatch(eventType);
		}
		
		internal function getMediaController():MediaController {
			var myclip:Clip = playList.current;
			return _controllerFactory.getMediaController(myclip, playList);
		}
				
		protected function onClipDone(event:ClipEvent):void {
			log.info(this + " onClipDone");
			var defaultAction:Boolean = ! event.isDefaultPrevented();
			Clip(event.target).dispatchEvent(event);
			if (playList.hasNext()) {
				if (defaultAction) {
					log.debug("onClipDone, moving to next clip");
					playListController.next(true, true);
				} else {
					stop(false, true);
					changeState(waitingState);
				}
			} else {
				if (defaultAction) {
					stop(false, true);
					changeState(waitingState);
				} else {
					playListController.rewind();
				}
			}
		}

        private function onPlaylistChanged(event:ClipEvent):void {
            setEventListeners(ClipEventSupport(event.info), false);
            if (_active) {
                setEventListeners(ClipEventSupport(event.target));
            }
        }

        private function onClipAdded(event:ClipEvent):void {
            if (_active) {
                setEventListeners(ClipEventSupport(event.target));
            }
        }

		protected function get playListReady():Boolean {
			if (! playList.current || playList.current.isNullClip) {
				log.debug("playlist has nos clips to play, returning");
				return false;
			}
			return true;
		}
	}
}
