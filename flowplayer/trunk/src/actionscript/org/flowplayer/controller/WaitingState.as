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
    import org.flowplayer.model.Clip;
import org.flowplayer.model.ClipEventType;
	
	import flash.utils.Dictionary;
	
	import org.flowplayer.controller.PlayListController;
	import org.flowplayer.model.ClipEvent;
	import org.flowplayer.model.Playlist;
	import org.flowplayer.model.State;	

	/**
	 * @author api
	 */
	internal class WaitingState extends PlayState {

		public function WaitingState(stateCode:State, playList:Playlist, playListController:PlayListController, providers:Dictionary) {
			super(stateCode, playList, playListController, providers);
		}
		
		internal override function doPlay():void {
			log.debug("doPlay()");
			if (! playListReady) return;
			bufferingState.nextStateAfterBufferFull = playingState;
			if (onEvent(ClipEventType.BEGIN, [false])) {
				playList.current.played = true;
				changeState(bufferingState);
			}
		}

        internal override function handleOnClipDone(clip:Clip, isFinish:Boolean, defaultAction:Boolean = true):void {
            log.debug("handleOnClipDone()");
        }

		internal override function stopBuffering():void {
			log.debug("stopBuffering() called");
			getMediaController().stopBuffering();
		}

		internal override function doStop(closeStream:Boolean, silent:Boolean):void {
			log.debug("cannot stop in waiting state ");
		}
		
		internal override function doStartBuffering():void {
			if (! playListReady) return;
			log.debug("startBuffering()");
			bufferingState.nextStateAfterBufferFull = pausedState;
			if (onEvent(ClipEventType.BEGIN, [true])) {
				changeState(bufferingState);
			}
		}
	}
}
