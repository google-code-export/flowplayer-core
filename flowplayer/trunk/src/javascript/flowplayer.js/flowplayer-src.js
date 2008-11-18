/** 
 * flowplayer.js [3.0.0]. Player embedding script using flashembed 0.32
 * 
 * http://flowplayer.org/documentation/install.html
 *
 * Copyright (c) 2008 Tero Piirainen (tipiirai@gmail.com)
 *
 * Released under the MIT License:
 * http://www.opensource.org/licenses/mit-license.php
 * 
 * >> Basically you can do anything you want but leave this header as is <<
 * 
 * version @VERSION - $Date 
 */ 
(function(){ 
 
/*** goals: loading, configuration, event handling, OOP API, multiple instances ***/ 
 
/*jslint glovar: true, browser: true, evil: true */
/*global flowplayer, $f */

var jQ = typeof jQuery == 'function';

// {{{ private utility methods
	
	// thanks: http://keithdevens.com/weblog/archive/2007/Jun/07/javascript.clone
	function clone(obj) {	
		if (!obj || typeof obj != 'object') { return obj; }		
		var temp = new obj.constructor();	
		for (var key in obj) {	
			if (obj.hasOwnProperty(key)) {
				temp[key] = clone(obj[key]);
			}
		}		
		return temp;
	}

	// stripped from jQuery, thanks John Resig 
	function each(obj, fn, args) {
		if (!obj) { return; }
		
		var name, i = 0, length = obj.length;
	
		if (length === undefined) {
			for (name in obj) {
				if (fn.call(obj[name], name, obj[name]) === false) { break; }
			}
		} else {
			for (var value = obj[0];
				i < length && fn.call( value, i, value ) !== false; value = obj[++i]){}
		}
	
		return obj;
	}

	// returns a named element from an object
	function deepScan(name, obj) {
		var found = null;
	
		each(obj, function(prop, value) {
			if (prop == name)  {
				found = value;
				return false;
			}			
			if (typeof value == 'object' && (!value.length)) {
				found = deepScan(name, value);	
			}
		});
		
		return found;
	}
	
	// convenience
	function el(id) {
		return document.getElementById(id); 	
	}	

	function extend(to, from, skipFuncs) {
		if (to && from) {			
			each(from, function(name, value) {
				if (!skipFuncs || typeof value != 'function') {
					to[name] = value;		
				}
			});
		}
	}
	
	// var arr = select("elem.className"); 
	function select(query) {
		var index = query.indexOf("."); 
		if (index != -1) {
			var tag = query.substring(0, index) || "*";
			var klass = query.substring(index + 1, query.length);
			var els = [];
			each(document.getElementsByTagName(tag), function() {
				if (this.className && this.className.indexOf(klass) != -1) {
					els.push(this);		
				}
			});
			return els;
		}
	}
	
	// fix event inconsistencies across browsers
	function stopEvent(e) {
		e = e || window.event;
		
		if (e.preventDefault) {
			e.stopPropagation();
			e.preventDefault();
			
		} else {
			e.returnValue = false;	
			e.cancelBubble = true;
		} 
		return false;
	}

	
//}}}	
	


function Player(wrapper, params, conf) {   

		
	// private variables
	var 
		self = this, 
		api = null, 
		html, 
		commonClip, 
		playlist = [], 
		
		// container for all event listeners. {onStart:[obj, obj, obj],  ...}
		listeners = {}, 
		playerId, 
		loaded;	

	
// {{{ private methods

   function pickListeners(root, index) {
      
      each(root, function(name, value) {
            
         if (name == 'cuepoints') {
            if (value[0][0].length) {
               each(value, function() {
                  addCuepoints(this[0], this[1], index);       
               });
            } else { 
               addCuepoints(value[0], value[1], index);
            }
               
         } else if (typeof value == 'function')  {
            bind(name, value, {index:index});   
         }
      });   
   }
   
	var guid = 0;
	
   function bind(evt, fn, opts) {
      
      var arr = (listeners[evt] = listeners[evt] || []);

		if (!fn.$$guid) {
			fn.$$guid = guid++;	
		}
			
      var listener = {
         event: evt,
         fn: fn
      };
      
      extend(listener, opts);    
      arr.push(listener);     
      
		// raise clip listeners above common listeners
      arr.sort(function(a, b) {
         return a.index - b.index;     
      });
      
      return listener;
   }

   function addCuepoints(points, fn, index) {
            
      var opts = {
         index: index,
         matches: function(time) {
            var match = false;
            time = time.time || time;
            each(this.cuepoints, function()  {
               if (this == time || this.time == time)  {
                  match = true;  
                  return false;
               }
            });
            
            return match;
         },
         cuepoints: points,
         cached: !api
      };      
      
		bind("onCuepoint", fn, opts);
		
      if (api) {        
         api.addCuepoints(cuepoints, index);
      }     
   }   

	function getApi()  {
		if (!api) {
			throw "flowplayer('"+self.id()+"') not loaded. Try moving call to it's onLoad event";
		}
		return api;
	}

	function unbind(fn, fromEvent) {
		
		each(listeners, function(evt, arr)  {
			if (!fromEvent || evt == fromEvent) {
				var i = 0;
				each(arr, function()  {			
					if (this.fn.$$guid == fn.$$guid)  {
						arr.splice(i, 1);		
					}
					i++;
				});
			}
		});
		return self;
		
	}
	
	function hasEvent(events, evt) {
		evt = evt.toLowerCase();
		if (events.indexOf(evt) == -1) {			
			throw "Nonexistent event " + evt;	
		}	
		return true;
	}
	
	
//}}}


// {{{ Clip

	var Clip = function(json, index) {
		
		var clip = this;
		
		if (typeof json == 'string') {
			json = {url:json};	
		}
		
		extend(clip, json, true);		
		this.index = index;
		this.isCommon = index == -1;	
		
		
		// pick listeners		
		pickListeners(json, index);
		
		
		// event handling 
		each(("Start*,Metadata,Pause*,Resume*,Seek*,Stop*,Finish,LastSecond,Change,BufferFull,BufferEmpty").split(","),
			function() {
			
			var evt = "on" + this;
				
			// before event
			if (evt.indexOf("*") != -1) {
				evt = evt.substring(0, evt.length -1); 
				var evt2 = "onBefore" + evt.substring(2);
				clip[evt2] = function(fn) {
					bind(evt2, fn, {index:index});
					return clip;
				};				
			}  
			
			clip[evt] = function(fn) {
				bind(evt, fn, {index:index});
				return clip;
			};
			
		});			  
		
		extend(clip, {
				
			onCuepoint: function(cuepoints, fn) {			
				addCuepoints(cuepoints, fn, index);
				return clip;
			},
			
			unbind: function(fn, evt) {
				if (hasEvent(events, evt)) {
					unbind(fn, evt);	
				}
				return clip;
			}
			
		});

	};
	
	//}}}

	
// {{{ Plugin
		
	var Plugin = function(pluginName, json) {

		var plugin = this;
		
		// plugin properties
		json = json || getApi().getPlugin(pluginName);	
		json = eval("(" + json + ")");
		
		var methods = json.methods;
		delete json.methods; 
		
		extend(plugin, json, true);
		

		// animate method
		this.animate = function(props, speed, fn) {			
			if (fn) {
				var fnId = "_" + Math.random();
				fn.name = pluginName;
				listeners[fnId] = fn;
			}

			getApi().plugin_animate(pluginName, props, speed || 500, fnId);		
		};
		
		// plugin's own methods
		each(methods, function() {
			var name = "" + this;			
			plugin[name] = function() {
				
				// pick possible fn from arguments
				var callback = null;
				
				each(arguments, function() {
					if (typeof this == 'function')  { 
						this.name = pluginName;	
						var fnId = "_" + Math.random();
						listeners[fnId] = this;
						callback = {listenerId: fnId};
					}
				});

				api.plugin_invoke(pluginName, name, callback, arguments[0]); 
			};
		});  
		
		return this;
		
	};
	
//}}}


// {{{ construction

	Player.s.push(this); 
	
	// plain url is given as config
	if (typeof conf == 'string') {
		conf = {clip:{url:conf}};	
	}
	
	// get core listeners	
	pickListeners(conf);
	
	// common clip is always there
	commonClip = new Clip(conf.clip, -1);
	
	
	// playlist
	if (conf.playlist) {		
		var index = 0;
		
		each(conf.playlist, function() {
			playlist.push(new Clip(this, index));
			index++;
		});
	}

	// flashembed parameters
	if (typeof params == 'string') {
		params = {src: params};	
	}    		
	
	// setup express install
	params.version = [9,0];
	params.expressInstall = 'http://localhost/js/expressinstall.swf';
 
	
	function clickHandler(e) {
		
		if (self.fireEvent("onBeforeLoad") === false) {
			return stopEvent(e);	
		}
		
		if (!self.isLoaded()) {
			self.load();
		}
		return stopEvent(e);					
	}
	
	function init() {
		
		if (!wrapper) {
			return false;	
		}
		
		// wrapper href as clip
		playerId = wrapper.id || "fp" + ("" + Math.random()).substring(1, 9);		
		params.id = playerId + ".api";
		conf.playerId = playerId;
		
		if (wrapper.getAttribute("href")) { 
			conf.playlist = [{url:wrapper.getAttribute("href")}];			
		}	
		
		// defer loading upon click
		if (wrapper.innerHTML.replace(/\s/g, '') !== '') {	 
			
			if (wrapper.addEventListener) {
				wrapper.addEventListener("click", clickHandler, false);	
			} else if (wrapper.attachEvent) {
				wrapper.attachEvent("onclick", clickHandler);	
			}
			
		} else {			
			self.load();
		}
		
	}

	// possibly defer initialization when dom is ready
	if (typeof wrapper == 'string') { 
		flashembed.domReady(function() {
			wrapper = el(wrapper);
			init();		
		});
		
	} else {
		init();
	}
	
//}}}

  
// {{{ public methods 
	
	extend(self, {
			
		id: function() {
			return playerId;	
		}, 
		
		isLoaded: function() {
			return (api !== null);	
		},
		
		parent: function() {
			return wrapper;	
		},
		
		dump: function() {
			console.log(playerId, listeners);	
			return self;
		},	
		
		// TODO: remove this from production
		api: function() {
			return api;	
		},
		
		load: function(fn) {
			
			if (!api) {
				
				// unload all instances
				each(Player.s, function()  {
					this.unload();		
				});
				
				html = wrapper.innerHTML; 
	 
				if (!loaded) {
					bind("onLoad", function() {
						
						api = api || el(self.id() + ".api");
						
						// populate cuepoints 
						each(listeners.onCuepoint, function() {					
							
							if (this.cached) {
								api.addCuepoints(this.cuepoints, this.index);
								this.cached = false;
							}
						});
						
					}, {index: -2});
					
					loaded = true;	
				}
				
				flashembed(wrapper, params, {config: conf});
				
				// user's possible fn
				if (fn) {				
					bind("onLoad", fn);	
				}
				
				// setup testing utility
				if (typeof TestPlayer == 'function') {
					setTimeout(function() {api = new TestPlayer(self, conf);}, 100);
				}
			} 
			
			return self;		
		},
		
		unload: function() {

			if (self.fireEvent("onBeforeUnload") === false) {
				return self;
			}
			
			if (html) {
				wrapper.innerHTML = html;
				self.fireEvent("onUnload");
				api = null;
			}		
			return self;
		},
		
		getConfig: function() {		
			return conf;	
		},
	
		getClip: function(index) {		
			if (index >= 0) {
				return playlist ? playlist[index] : null;
			} else {
				return commonClip;	
			}
		},
	
		getCommonClip: function()  {
			return commonClip;	
		},
		
		
		getPlaylist: function() {
			return playlist; 
		},
		
	  
		getPlugin: function(name) {		
			json = getApi().getPlugin(name);
			return json != 'null' ? new Plugin(name, json) : null; 
		},
		
		getScreen: function() {
			return self.getPlugin("screen");	
		}, 
		
		loadPlugin: function(name, url, props, fn) {
			
			if (fn) {
				var fnId = "_" + Math.random();
				fn.name = name;	
				listeners[fnId] = fn;
			}
			
			var json = getApi().plugin_load(name, url, props, fnId);
			return json != 'null' ? new Plugin(name, json) : null; 
		},
		
		
		getState: function() {
			return self.isLoaded() ? getApi().getState() : -1;
		},
		
		// "lazy" play
		play: function(clip) {
			
			function play(clip) {
				getApi();
				if (clip) {
					if (typeof clip == 'string') { clip = {url: clip}; }
					api.play(clip)
				} else {
					api.play();	
				}
			}
			
			if (self.isLoaded()) {
				play(clip);
				
			} else {
				self.load(function() {
					play(clip);
				});
			}
			
			return self;
		},
		
		unbind: function(fn, evt) {
			unbind(fn, evt);
			return self;
		}
		
	});
	

	
	// core API methods
	each(("getVersion,pause,mute,unmute,stop,clear,toggle,seek,getStatus,getVolume,setVolume,getTime").split(","),		
		function() {		 
			var name = this;
			self[name] = function(arg) {
				var ret = (arg === undefined) ? api[name]() : api[name](arg);
				return (ret === undefined || ret.version) ? self : ret;
			};			 
		}
	); 	
	
	// event handler
	each(("Load*,Unload*,Keypress*,Click*,Volume*,Mute*,Unmute*,PlaylistChange,Fullscreen*,FullscreenExit").split(","),
		function() {		 
			var name = "on" + this;
			
			// before event
			if (name.indexOf("*") != -1) {
				name = name.substring(0, name.length -1); 
				var name2 = "onBefore" + name.substring(2);
				self[name2] = function(fn) {
					bind(name2, fn);	
					return self;
				};						
			}
			
			// normal event
			self[name] = function(fn) {
				bind(name, fn);	
				return self;
			};			 
		}
	); 
	
	
//}}}


// {{{ public method: fireEvent
		
	this.fireEvent = function(evt, arg0, arg1) {
	
		console.log("flowplayer.fireEvent", evt, "arg:", arg0, "arg1", arg1);
		
		if (evt == 'contextMenu') {
			return conf.contextMenu[arg0].call(self);	
		}

		if (evt == 'onPluginEvent') {
			
			// fire plugin's function property in conf 
			if (arg1) {
				var pluginConf = conf.plugins[arg0];
				if (pluginConf) {
					var method = deepScan(arg1, pluginConf.config);
					if (method) {
						return method.call(self);
					}
				}
				
			// "one shot" listener (onAnimate, onInvoke)
			} else {
				var fn = listeners[arg0];
				if (fn) {
					var plugin = new Plugin(fn.name); 
					fn.call(plugin);
					delete listeners[arg0];
					return; 
				}					
			} 
			return;	
		}		

		// onPlaylistChange
		if (evt == 'onPlaylistChange') {  
			playlist = [];
			
			var index = 0;
			each(arg0, function() {
				playlist.push(new Clip(this, index));
				index++;
			});

			return;			
		}			
		

		index = arg0;
		var clip = playlist[index];	
		
		// onMetaData || onChange
		if (evt == 'onMetaData' || evt == 'onChange') {
			
			// we don't like eval, but here we know that nothing hazardous gets evaluated
			arg0 = eval("(" + arg0 + ")");	
			index = arg0.index;	
			clip = playlist[index];	
			extend(clip, arg0);
			delete clip.customProperties;
			delete clip.metaData;
		} 
		
		
		// cuepoints		
		if (evt == 'onCuepoint') {
			each(listeners.onCuepoint, function() {
				if ((this.index == index || this.isCommon) && this.matches(arg1))  {
					if (this.fn.call(self, clip, arg1) === false)  {
						return false;
					}	
				}
			});			
			return;
		} 
		
		
		// rest of the callbacks
		var ret = true;
		
		each(listeners[evt], function() {	   
			
			if (!(this.index >= 0) || this.index == index)  { 
		
				// clip, arg1 || arg1
				var args = [clip || arg1];
				if (clip) {
					args.push(arg1);	
				}
		
				ret = this.fn.apply(self, args);				
				if (ret === false)  {
					return false;
				}	
			}			
		});

		return ret;		

	};

//}}}
 

}


// container for player instances
Player.s = [];


// {{{ flowplayer() & statics 

function Iterator(arr) {
	
	this.length = arr.length;
	
	this.each = function(fn)  {
		each(arr, fn);	
	};
	
	this.size = function() {
		return arr.length;	
	};
	
}

window.flowplayer = window.$f = function() {
	
	var instance = null;
	var arg = arguments[0];	
	
	
	// $f()
	if (!arguments.length) {
		each(Player.s, function() {
			if (this.isLoaded())  {
				instance = this;	
			}
		});
		
		return instance || Player.s[0];
	} 
	
	if (arguments.length == 1) {
		
		// $f(index);
		if (typeof arg == 'number') { 
			return Player.s[arg];	
	
			
		// $f(wrapper || 'containerId' || '*');
		} else {
			
			// $f("*");
			if (arg == '*') {
				return new Iterator(Player.s);	
			}
			
			// $f(wrapper || 'containerId');
			each(Player.s, function() {
				if (this.id() == arg || this.id() == arg.id)  {
					instance = this;	
				}
			});
			
			return instance;					
		}
	} 			

	// instance builder 
	if (arguments.length > 1) {
		
		var nodes = arg;
		var swf = arguments[1];
		var conf = (arguments.length == 3) ? arguments[2] : {};
						
		if (typeof nodes == 'string') {
			
			// select nodes by classname
			if (nodes.indexOf(".") != -1) {
				var instances = [];
				flashembed.domReady(function() { 
					each(select(nodes), function() {
						instances.push(new Player(this, clone(swf), clone(conf))); 		
					});
				});	
				
				return instances;
				
			// select node by id
			} else {						
				return new Player(el(nodes) !== null ? el(nodes) : nodes, swf, conf);  	
			} 
			
			
		// nodes is a DOM element
		} else if (nodes) {
			return new Player(nodes, swf, conf);						
		}
		
	} 
	
	return null; 
};
	
extend(window.$f, {

	// called by Flash ExternalInterface		
	fireEvent: function(id, evt, arg0, arg1) {
		var p = $f(id);		
		return p ? p.fireEvent(evt, arg0, arg1) : null;
	},
	
	
	// extend Player by modifying it's prototype
	addPlugin: function(name, fn) {
		Player.prototype[name] = fn;
		return $f;
	}
	
});

// to be removed
window.Flowplayer = $f;

	
//}}}



// jQuery support
if (jQ) {
	
	jQuery.prototype.flowplayer = function(params, conf) {  
		
		// select instances
		if (arguments.length <= 1) {
			var arr = [];
			this.each(function()  {
				var p = $f(this);
				if (p) {
					arr.push(p);	
				}
			});
			return arguments.length ? arr[arguments[0]] : new Iterator(arr);
		}
		
		// create flowplayer instances
		return this.each(function() { 
			$f(this, clone(params), clone(conf));	
		}); 
		
	};
	
}

})();
