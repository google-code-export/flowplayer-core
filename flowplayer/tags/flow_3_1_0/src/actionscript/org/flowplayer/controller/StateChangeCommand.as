/*    
 *    Copyright 2008 Anssi Piirainen
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
	import org.flowplayer.flow_internal;	
	use namespace flow_internal;

	/**
	 * @author api
	 */
	internal class StateChangeCommand {
		private var _controller:MediaController;
		private var _controllerFunction:Function;
		private var _args:Array;
		private var _playlistController:PlayListController;
		private var _newState:PlayState;

		public function StateChangeCommand(controller:MediaController, controllerFunction:Function, args:Array, playlistController:PlayListController, newState:PlayState) {
			_controller = controller;
			_controllerFunction = controllerFunction;
			_args = args;
			_playlistController = playlistController;
			_newState = newState;
		}

		public function execute():void {
			_playlistController.setPlayState(_newState);
			_controllerFunction.apply(_controller, _args);
		}	
	}
}
