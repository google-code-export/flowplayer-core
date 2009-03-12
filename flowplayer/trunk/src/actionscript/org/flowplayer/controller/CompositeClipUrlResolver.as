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
    import flash.events.NetStatusEvent;
import org.flowplayer.model.Clip;
    import org.flowplayer.model.PluginModel;
    import org.flowplayer.util.Log;
import org.flowplayer.view.PluginRegistry;

    public class CompositeClipUrlResolver implements ClipURLResolver {
        private static var log:Log = new Log("org.flowplayer.controller::CompositeClipUrlResolver");
        private var _resolvers:Array;

        public function CompositeClipUrlResolver(resolvers:Array) {
            _resolvers = resolvers;
        }

        public static function createResolver(names:Array, pluginRegistry:PluginRegistry, fallbackResolver:String):ClipURLResolver {
            if (! names || names.length == 0) return getResolver(fallbackResolver, pluginRegistry);
            if (names.length == 1) return getResolver(names[0], pluginRegistry);

            log.debug("creating composite resolver with " + names.length + " resolvers");
            var resolvers:Array = new Array();
            for (var i:int = 0; i < names.length; i++) {
                resolvers.push(getResolver(names[i], pluginRegistry));
            }
            return new CompositeClipUrlResolver(resolvers);
        }

        private static function getResolver(name:String, pluginRegistry:PluginRegistry):ClipURLResolver {
            return PluginModel(pluginRegistry.getPlugin(name)).pluginObject as ClipURLResolver;
        }

        public function resolve(provider:StreamProvider, clip:Clip, successListener:Function):void {
        }

        public function set onFailure(listener:Function):void {
        }

        public function handeNetStatusEvent(event:NetStatusEvent):Boolean {
            return true;
        }
    }
}