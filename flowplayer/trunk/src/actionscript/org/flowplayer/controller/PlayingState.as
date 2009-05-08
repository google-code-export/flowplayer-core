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
	
	import org.flowplayer.controller.PlayListController;
	import org.flowplayer.flow_internal;
    import org.flowplayer.model.Clip;
import org.flowplayer.model.ClipEvent;
import org.flowplayer.model.ClipEventSupport;
import org.flowplayer.model.ClipEventType;
    import org.flowplayer.model.EventType;
import org.flowplayer.model.Playlist;
	import org.flowplayer.model.State;
	import org.flowplayer.model.Status;		
	
	use namespace flow_internal;
	/**
	 * @author api
	 */
	internal class PlayingState extends PlayState {
        private var _inStreamTracker:InStreamTracker;

        public function PlayingState(stateCode:State, playlist:Playlist, playlistController:PlayListController, providers:Dictionary) {
            super(stateCode, playlist, playlistController, providers);
            _inStreamTracker = new InStreamTracker(playlistController);
            playList.onStart(onStart, hasMidstreamClips);
            playList.onResume(onResume, hasMidstreamClips);
        }

        private function hasMidstreamClips(clip:Clip):Boolean {
            var children:Array = clip.playlist;
            if (children.length == 0) return false;
            for (var i:int = 0; i < children.length; i++) {
                if (Clip(children[i]).position > 0) {
                    return true;
                }
            }
            return false;
        }

        internal override function play():void {
            log.debug("play()");
            stop();
            bufferingState.nextStateAfterBufferFull = playingState;

            if (onEvent(ClipEventType.BEGIN, [false])) {
                changeState(bufferingState);
                playList.current.played = true;
            }
        }

        override protected function setEventListeners(eventSupport:ClipEventSupport, add:Boolean = true):void {
            if (add) {
                log.debug("adding event listeners");
                eventSupport.onPause(onPause);
                eventSupport.onStop(onStop);
                eventSupport.onFinish(onFinish);
                eventSupport.onBeforeFinish(onClipDone);
//                eventSupport.onStop(onClipStop);
                eventSupport.onSeek(onSeek, hasMidstreamClips);
                eventSupport.onClipAdd(onClipAdd);
            } else {
                eventSupport.unbind(onPause);
                eventSupport.unbind(onStop);
                eventSupport.unbind(onFinish);
                eventSupport.unbind(onClipDone, ClipEventType.FINISH, true);
                eventSupport.unbind(onSeek);
                eventSupport.unbind(onClipAdd);
            }
        }

        private function onClipAdd(event:ClipEvent):void {
            if (playList.current.playlist.length > 0) {
                _inStreamTracker.start();
            }
        }

        private function onStart(event:ClipEvent):void {
            log.debug("onStart");
            _inStreamTracker.start(true);
        }

        private function onResume(event:ClipEvent):void {
            _inStreamTracker.start();
        }

        private function onPause(event:ClipEvent):void {
            _inStreamTracker.stop();
        }

        private function onStop(event:ClipEvent):void {
            _inStreamTracker.stop();
        }

        private function onFinish(event:ClipEvent):void {
            _inStreamTracker.stop();
            removeOneShotClip(event.target as Clip);
        }

        private function onSeek(event:ClipEvent):void {
            _inStreamTracker.reset();
            _inStreamTracker.start();
        }

        private function removeOneShotClip(clip:Clip):void {
            if (clip.position == -2) {
                log.error("removing one shot child clip from the playlist");
                playList.removeChildClip(clip);
            }
        }

		internal override function stopBuffering():void {
			log.debug("stopBuffering() called");
			stop();
			getMediaController().stopBuffering();
		}

		internal override function pause():void {
			if (onEvent(ClipEventType.PAUSE)) {
				changeState(pausedState);
			}
		}
		
		internal override function seekTo(seconds:Number):void {
			onEvent(ClipEventType.SEEK, [seconds]);
		}

//        private function onClipStop(event:ClipEvent):void {
//            if (event.isDefaultPrevented()) return;
//            var clip:Clip = event.target as Clip;
//            log.debug("onClipStop(), clip " + clip);
//
//
//            if (clip.isPostroll) {
//                log.debug("onClipStop(): this is a postroll clip");
//                changeState(waitingState);
//
//            } else if (clip.isPreroll) {
//                stop(false, true);
//                playList.setInStreamClip(null);
//                doPlay();
//
//            } else if (clip.isMidStream) {
//                _inStreamTracker.stop();
//                _inStreamTracker.reset();
//                playList.setInStreamClip(null);
//                changeState(pausedState);
//                playListController.resume();
//
//            } else {
//                changeState(waitingState);
//            }
//            removeOneShotClip(clip);
//        }
    }
}
