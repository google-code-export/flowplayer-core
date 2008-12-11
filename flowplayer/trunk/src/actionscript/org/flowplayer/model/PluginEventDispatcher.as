package org.flowplayer.model {
	import flash.utils.Dictionary;
	
	import org.flowplayer.flow_internal;
	import org.flowplayer.model.EventDispatcher;	

	use namespace flow_internal;
	/**
	 * @author anssi
	 */
	public class PluginEventDispatcher extends EventDispatcher {
		
		/**
		 * Dispatches a plugin event.
		 * @param eventType the type of the event to dispatch
		 * @param eventId the ID for the event, this the ID used to distinguis between diferent generic plugin events
		 * @see PluginEvent#id
		 */
		public function dispatch(eventType:PluginEventType, eventId:String = null):void {
			doDispatchEvent(new PluginEvent(eventType, eventId, name), true);
		}
		
		/**
		 * Dispatches an event of type PluginEventType.LOAD
		 * @see PluginEventType#LOAD
		 */
		public function dispatchOnLoad():void {
			dispatch(PluginEventType.LOAD);
		}
		
		/**
		 * Dispatches a plugin error event.
		 * @see PluginEventType#ERROR
		 */
		public function dispatchOnLoadError():void {
			dispatch(PluginEventType.ERROR, "pluginLoad");
		}

		public function dispatchEvent(event:PluginEvent):void {
			doDispatchEvent(event, true);
		}

		public function dispatchBeforeEvent(event:PluginEvent):Boolean {
			return doDispatchBeforeEvent(event, true);
		}

		public function onPluginEvent(listener:Function):void {
			setListener(PluginEventType.PLUGIN_EVENT, listener);
		}

		public function onLoad(listener:Function):void {
			setListener(PluginEventType.LOAD, listener);
		}

		public function onError(listener:Function):void {
			setListener(PluginEventType.ERROR, listener);
		}
		
		override protected function get cancellableEvents():Dictionary {
			return PluginEventType.cancellable;
		}

		override protected function get allEvents():Dictionary {
			return PluginEventType.all;
		}
		
		public function get name():String {
			return null;
		}
	}
}
