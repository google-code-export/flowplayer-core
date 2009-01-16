/*     *    Copyright 2008 Flowplayer Oy * *    This file is part of Flowplayer. * *    Flowplayer is free software: you can redistribute it and/or modify *    it under the terms of the GNU General Public License as published by *    the Free Software Foundation, either version 3 of the License, or *    (at your option) any later version. * *    Flowplayer is distributed in the hope that it will be useful, *    but WITHOUT ANY WARRANTY; without even the implied warranty of *    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the *    GNU General Public License for more details. * *    You should have received a copy of the GNU General Public License *    along with Flowplayer.  If not, see <http://www.gnu.org/licenses/>. */package org.flowplayer.model {
	import org.flowplayer.controller.ConnectionProvider;	
	import org.flowplayer.model.Cloneable;	

	/**	 * @author api	 */	public class ProviderModel extends PluginEventDispatcher implements PluginModel {		private var _name:String;		private var _config:Object;		private var _methods:Array = new Array();		private var _providerObject:Object;		private var _connectionProvider:String;		private var _clipURLResolver:String;		
		public function ProviderModel(providerObject:Object, name:String) {			_name = name;			_providerObject = providerObject;		}		public function clone():Cloneable {			var clone:ProviderModel = new ProviderModel(_providerObject, _name);			clone.config = _config;			clone.methods = _methods;			return clone;		}
		public function addMethod(method:PluginMethod):void {			_methods.push(method);		}				public function getMethod(externalName:String):PluginMethod {			return PluginMethodHelper.getMethod(_methods, externalName);		}				public function invokeMethod(externalName:String, args:Array = null):Object {			return PluginMethodHelper.invokePlugin(this, getProviderObject(), externalName, args);		}				public function set config(config:Object):void {			_config = config;		}				[Value]		override public function get name():String {			return _name;		}				public function toString():String {			return "[Provider] '" + _name + "'";		}
		
		public function getProviderObject():Object {			return _providerObject;
		}				public function set name(name:String):void {			_name = name;		}				[Value]		public function get config():Object {			return _config;		}
				[Value(name="methods")]		public function get methodNames():Array {			return PluginMethodHelper.methodNames(_methods);		}				public function set methods(methods:Array):void {			_methods = methods;		}		public function get connectionProvider():String {			return _connectionProvider;		}		public function set connectionProvider(connectionProvider:String):void {			_connectionProvider = connectionProvider;		}
		
		public function get clipURLResolver():String {			return _clipURLResolver;
		}
		
		public function set clipURLResolver(clipURLResolver:String):void {			_clipURLResolver = clipURLResolver;
		}	}}