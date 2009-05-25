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

package org.flowplayer.util {
	import flash.utils.getQualifiedClassName;
	
	import org.flowplayer.util.Log;	

	/**
	 * PropertyBinder is used to populate object's properties by copying values
	 * from other objects. The target object should be an instance of a class that contains
	 * accessor or setter functions for the properties that are found in the source.
	 * 
	 * @author api
	 */
	public class PropertyBinder {

		private var log:Log = new Log(this);
		private var object:Object;		private var _extraProps:String;

		/**
		 * Creates a new property binder for the specified target object.
		 * @param object the target object into which the properties will be copid to
		 * @param extraProps a property name for all properties for which the target does not provide an accessor or a setter function
		 */		public function PropertyBinder(object:Object, extraProps:String = null) {
			log.info("created for " + getQualifiedClassName(object));
			this.object = object;
			_extraProps = extraProps;
		}
		
		public function copyProperties(source:Object, overwrite:Boolean = true):Object {
			if (! source) return object;
			log.debug("copyProperties, overwrite = " + overwrite + (_extraProps ? ", extraprops will be set to " + _extraProps : ""));
			for (var prop:String in source) {
				if (overwrite || ! hasValue(object, prop)) {
					initProperty(prop, object, source[prop]);
				}
			}
			log.debug("done with " + getQualifiedClassName(object));
			return object;
		}
		
		private function hasValue(obj:Object, prop:String):Boolean {
			if (objHasValue(obj, prop)) {
				return true;
			} else if (_extraProps) {
				return objHasValue(obj[_extraProps], prop);
			}
			return false;
		}

		private function objHasValue(obj:Object, prop:String):Boolean {
			try {
				var value:Object = obj[prop];
				if (value is Number) {
					return value >= 0;
				}
				if (value is Boolean) {
					return true;
				}
				return value;
			} catch (ignore:Error) { }
			try {
				return obj.hasValue(prop);
			} catch (ignore:Error) { }
			return false;
		}

		private function initProperty(prop:String, objectToPopulate:Object, value:Object):void {
			var setter:String = "set" + prop.charAt(0).toUpperCase() + prop.substring(1);
			try {
				if (objectToPopulate[setter]) {
					log.debug("initProperty with setter " + setter);
					objectToPopulate[setter](value);
				}
				log.debug("successfully initialized property '" + prop + "' to value '" + value +"'");
				return;
			} catch (e:Error) {
				log.debug("unable to initialize using " + setter);
			}
			
			try {
				log.debug("trying to set property '" + prop + "' directly");
				objectToPopulate[prop] = value;
				log.debug("successfully initialized property '" + prop + "' to value '" + value + "'");
				return;
			} catch (e:Error) {
				log.debug("unable to set to field / using accessor");
			}
			
			if (_extraProps) {
				log.debug("setting to extraprops " + _extraProps + ", prop " + prop + " value " + value);
				configure(objectToPopulate, _extraProps || "customProperties", prop, value);
			} else {
				log.debug("skipping property '" + prop + "', value " + value);
			}
		}
		
		private function configure(configurable:Object, configProperty:String, prop:String, value:Object):void {
			var config:Object = configurable[configProperty] || new Object();
			config[prop] = value;
			configurable[configProperty] = config;
		}
	}
}
