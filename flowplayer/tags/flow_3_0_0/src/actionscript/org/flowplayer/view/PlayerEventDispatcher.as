package org.flowplayer.view {
	import flash.utils.Dictionary;
	
	import org.flowplayer.flow_internal;
	import org.flowplayer.model.EventDispatcher;
	import org.flowplayer.model.PlayerEvent;
	import org.flowplayer.model.PlayerEventType;	
	use namespace flow_internal;
	
	/**
	 * @author anssi
	 */
	public class PlayerEventDispatcher extends EventDispatcher {
		
		/**
		 * Dispatches a player event of the specified type.
		 */
		public function dispatch(eventType:PlayerEventType, info:Object = null):void {
			doDispatchEvent(new PlayerEvent(eventType, info), true);
		}
		
		/**
		 * Dispatches a player event.
		 */
		public function dispatchEvent(event:PlayerEvent):void {
			doDispatchEvent(event, true);
		}

		/**
		 * Dispatches the specified event to the before phase listeners.
		 */
		public function dispatchBeforeEvent(event:PlayerEvent):Boolean {
			return doDispatchBeforeEvent(event, true);
		}
		
		/**
		 * Adds a onLoad event listener. The event is triggered when the player has been loaded and initialized.
		 * @param listener
		 * @param add if true the listener is addes, otherwise removed
		 * @see PlayerEvent
		 */
		public function onLoad(listener:Function):void {
			setListener(PlayerEventType.LOAD, listener);
		}
		
		/**
		 * Adds a fullscreen-enter event listener. The event is fired when the player goes to
		 * the fullscreen mode.
		 * @param listener
		 * @see PlayerEvent
		 */
		public function onFullscreen(listener:Function):void {
			log.debug("adding listener for fullscreen " + PlayerEventType.FULLSCREEN);
			setListener(PlayerEventType.FULLSCREEN, listener);
		}
		
		/**
		 * Adds a fullscreen-exit event listener. The event is fired when the player exits from
		 * the fullscreen mode.
		 * @param listener
		 * @see PlayerEvent
		 */
		public function onFullscreenExit(listener:Function):void {
			setListener(PlayerEventType.FULLSCREEN_EXIT, listener);
		}
		
		/**
		 * Adds a volume mute event listener. The event is fired when the volume is muted
		 * @param listener
		 * @see PlayerEvent
		 */
		public function onMute(listener:Function):void {
			setListener(PlayerEventType.MUTE, listener);
		}
		
		/**
		 * Adds a volume un-mute event listener. The event is fired when the volume is unmuted
		 * @param listener
		 * @see PlayerEvent
		 */
		public function onUnmute(listener:Function):void {
			setListener(PlayerEventType.UNMUTE, listener);
		}
		
		/**
		 * Adds a volume event listener. The event is fired when the volume level is changed.
		 * @param listener
		 * @see PlayerEvent
		 */
		public function onVolume(listener:Function):void {
			setListener(PlayerEventType.VOLUME, listener);
		}
		
		override protected function get cancellableEvents():Dictionary {
			return PlayerEventType.cancellable;
		}

		override protected function get allEvents():Dictionary {
			return PlayerEventType.all;
		}
	}
}
