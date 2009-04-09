package org.flowplayer.config {
import com.adobe.utils.XMLUtil;
import org.flowplayer.model.Clip;
import org.flowplayer.model.ClipType;
    import org.flowplayer.model.Playlist;
import org.flowplayer.util.Log;


    
    internal class RSSPlaylistParser {
        private var log:Log = new Log(this);

        public function parse(rawRSS:String, playlist:Playlist):void {
            log.info("parse");
            if(! XMLUtil.isValidXML(rawRSS)) {
                throw new Error("Feed does not contain valid XML.");
            }
            var doc:XML = new XML(rawRSS);
            for each (var ch:XML in doc.children()) {
                if (ch.localName() == 'channel') {
                    for each (var item:XML in ch.children()) {
                        if(item.name() == 'item') {
                            parseClip(item, playlist);
                        }
                    }
                }
            }
        }
        
        public function parseClip(item:XML, playlist:Playlist):void {
            log.debug("parseClip");
            var clip:Clip =  new Clip();
            playlist.addClip(clip);
            for each (var elem:XML in item.children()) {
                log.debug(elem.localName() + ": " + elem.text().toString());
                
                switch(elem.localName()) {
                    case 'duration':
                        clip.duration = int(elem.text().toString());
                        break;
                    case 'enclosure':
                        clip.url = elem.@url.toString();
                        clip.type = ClipType.fromMimeType(elem.@type.toString());
                        break;
                    case 'link':
                        clip.linkUrl = elem.text().toString();
                        break;
                    case 'group':
                        parseMedia(elem, clip);
                        break;
                    default:
                        var prop:Object = parseCustomProperty(elem);
                        addClipCustomProperty(clip, elem, prop);
                }
            }
            parseMedia(item, clip);
            log.debug("created clip " + clip);
        }
        
        private function addClipCustomProperty(clip:Clip, elem:XML, value:Object):void {
            log.debug("getting propety name for " + elem.localName() + " value is ", value);
            var name:String = getCustomPropName(elem);
            var existing:Object = clip.getCustomProperty(name);
            if (existing) {
                log.debug("found existing " + existing);
                var values:Array = existing is Array ? existing as Array : [existing];
                values.push(value);
                clip.customProperties[name] = values;
            } else {
                clip.setCustomProperty(name, value);
            }
            log.debug("clip custom property " + name + " now has value ", clip.customProperties[name]);

        }

        private function getCustomPropName(elem:XML):String {
            if (! elem.namespace()) return elem.localName();
            if (! elem.namespace().prefix) return elem.localName();
            return elem.namespace().prefix + ":" + elem.localName(); 
//            return elem.namespace().prefix + elem.localName().charAt(0).toUpperCase() + elem.localName().substring(1);;
        }
        
        private function parseCustomProperty(elem:XML):Object {
            if (elem.children().length() == 0 && elem.attributes().length() == 0) {
                return elem.toString(); 
            }
            if (elem.children().length() == 1 && XML(elem.children()[0]).nodeKind() == "text" && elem.attributes().length() == 0) {
                log.debug("has one text child onlye, retrieving it's contents")
                return elem.text().toString();
            }
            var result:Object = new Object();
            for each (var attr:XML in elem.attributes()) {
                result[attr.localName()] = attr.toString();
            }

            for each (var child:XML in elem.children()) {
                result[child.localName() || "text"] = parseCustomProperty(child);
            }
            return result;
        }

        private function parseMedia(obj:XML, clip:Clip):void {
            for each (var elem:XML in obj.children()) {
                log.debug("parseMedia(), " + elem.localName() + ": " + elem.text().toString());

                switch(elem.localName()) {
                    case 'content':
                        clip.url = elem.@url.toString();
                        if(elem.@type) {
                            clip.type = ClipType.fromMimeType(elem.@type.toString());
                        }
                        if(int(elem.@duration.toString()) > 0) {
                            clip.duration = int(elem.@duration.toString());
                        }
//                        if(elem.@start) {
//                            clip.start = TimeUtil.seconds(elem.@start.toString());
//                        }
                        if(elem.children().length() >0) {
                            parseMedia(elem, clip);
                        }
                        break;
//                    default:
//                        clip.setCustomProperty(elem.localName(), elem.text());
                }
                log.debug(elem.toString());
            }
        }
    }
}