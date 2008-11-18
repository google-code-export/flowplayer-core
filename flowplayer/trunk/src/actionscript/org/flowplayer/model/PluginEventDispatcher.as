package org.flowplayer.model {
	import flash.utils.Dictionary;
	
	import org.flowplayer.flow_internal;
	import org.flowplayer.model.EventDispatcher;	

	use namespace flow_internal;
	/**
	 * @author anssi
	 */
	public class PluginEventDispatcher extends EventDispatcher {
		
		public function dispatch(eventType:PluginEventType, callbackId:String):void {
			doDispatchEvent(new PluginEvent(eventType, callbackId, name), true);
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
