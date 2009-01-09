package org.flowplayer.model {
	import flash.utils.Dictionary;	
	
	/**
	 * @author anssi
	 */
	public class EventType {
		private var _name:String;

		public function EventType(name:String) {
			_name = name;
		}

		public function get isCancellable():Boolean {
			throw new Error("isCancellable() not overridden");
			return false;
		}
		
		public function get name():String {
			return _name;
		}
	}
}
