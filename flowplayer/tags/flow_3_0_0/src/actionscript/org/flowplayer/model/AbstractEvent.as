package org.flowplayer.model {
	import flash.events.Event;
	import flash.external.ExternalInterface;
	
	import org.flowplayer.flow_internal;
	import org.flowplayer.util.ObjectConverter;		
	
		
	
				
	
	
		
		

	use namespace flow_internal;
	/**
	 * @author anssi
	 */
	public class AbstractEvent extends Event {

		private var _info:Object;
		private var _eventType:EventType;
		private var _target:Object;
		private var _propagationStopped:Boolean;
		private var _isDefaultPrevented:Boolean;

		public function AbstractEvent(eventType:EventType, info:Object = null) {
			super(eventType.name);
			this._eventType = eventType;
			this._info = info;
			_target = target;
		}

		public function isCancellable():Boolean {
			return _eventType.isCancellable;
		}

		public override function clone():Event {
			return new AbstractEvent(_eventType, _info);
		}

		public override function toString():String {
			return formatToString("AbstractEvent", "type", "target");
		}
		
		public function get info():Object {
			return _info;
		}
		
		override public function get target():Object {
			if (_target) return _target;
			return super.target;
		}
		
		public function set target(target:Object):void {
			_target = target;
		}
		
		public function get eventType():EventType {
			return _eventType;
		}
		
		override public function stopPropagation():void {
			_propagationStopped = true;
		}
		
		override public function stopImmediatePropagation():void {
			_propagationStopped = true;
		}

		public function isPropagationStopped():Boolean {
			return _propagationStopped;
		}
		
		flow_internal function fireExternal(playerId:String, beforePhase:Boolean = false):Boolean {
			if (!ExternalInterface.available) return true;
			// NOTE: externalEventArgument3 is not converted!
			var returnVal:Object = ExternalInterface.call(
				"flowplayer.fireEvent",
				playerId || ExternalInterface.objectID, getExternalName(eventType.name, beforePhase), convert(externalEventArgument), convert(externalEventArgument2), externalEventArgument3);
			if (returnVal + "" == "false") return false;
			return true;
		}
		
		private function convert(objToConvert:Object):Object {
			return new ObjectConverter(objToConvert).convert();
		}

//		private function jsonize(externalEventArgument:Object):String {
//			if (externalEventArgument is String) return externalEventArgument as String;
//			return JSON.encode(externalEventArgument);
//		}

		private function getExternalName(name:String, beforePhase:Boolean):String {
			if (! beforePhase) return name;
			if (! name.indexOf("on") == 0) return "onBefore" + name;
			return "onBefore" + name.substr(2);
		}

		protected function get externalEventArgument():Object {
			return target;
		}
		
		protected function get externalEventArgument2():Object {
			return _info;
		}
		
		protected function get externalEventArgument3():Object {
			return null;
		}
		
		override public function isDefaultPrevented():Boolean {
			return _isDefaultPrevented;
		}
		
		override public function preventDefault():void {
			_isDefaultPrevented = true;
		}
	}
}
