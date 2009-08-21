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
package org.flowplayer.view {
    import flash.display.DisplayObject;
    import flash.display.MovieClip;
    import flash.display.StageAlign;
    import flash.display.StageScaleMode;
    import flash.events.Event;
    import flash.events.ProgressEvent;
    import flash.events.TimerEvent;
    import flash.utils.Timer;
    import flash.utils.getDefinitionByName;

    import org.flowplayer.util.Arrange;

    public class Preloader extends MovieClip {

        private var _app:DisplayObject;
        private var _initTimer:Timer;
        private var _rotation:RotatingAnimation;
        private static var _stageHeight:int = 0;
        private static var _stageWidth:int = 0;
        // this variable can be set from external SWF files, if it's set well use it to construct the config
        public var injectedConfig:String;

        public function Preloader() {
            stop();
            addEventListener(Event.ADDED_TO_STAGE, onAddedToStage);
            addEventListener(Event.RESIZE, arrange);
            loaderInfo.addEventListener(Event.COMPLETE, init);
        }

        private function get rotationEnabled():Boolean {
            var config:Object = stage.loaderInfo.parameters["config"];
            if (! config) return true;
            if (config.replace(/\s/g, "").indexOf("buffering:null") > 0) return false;
            return true;
        }

        private function checkLoaded():Boolean {
            if (loaderInfo.bytesLoaded == loaderInfo.bytesTotal) {
                init();
                return true;
            }
            return false;
        }

        private function arrange(event:Event = null):void {
            stageHeight = stage.stageHeight;
            stageWidth = stage.stageWidth;
            _rotation.setSize(stageHeight * 0.22, stageHeight * 0.22);
            Arrange.center(_rotation, stage.width, stage.height - 28);
        }

        private function onAddedToStage(event:Event):void {
            trace("Preloader added to stage, stage size " + stageWidth + " x " + stageHeight);
            prepareStage();
            if (rotationEnabled) {
                _rotation = new RotatingAnimation();
                addChild(_rotation);
                arrange();
                _rotation.start();
            }

            loaderInfo.addEventListener(ProgressEvent.PROGRESS, onLoadProgress);

            // prepare stage if the app (Launcher) has been greated already. this is the
            // case when we are embedded in another SWF
            if (_app) {
                prepareStage();
            }
		}

		private function onLoadProgress(event:ProgressEvent):void {
            if (checkLoaded()) return;
  			var percent:Number = Math.floor((event.bytesLoaded*100) / event.bytesTotal);
            trace("percent " + percent);
            if (_rotation) {
                Arrange.center(_rotation, stageWidth, stageHeight);
            }
   		}
       
        private function init(event:Event = null):void {
            trace("init");
            if (_initTimer) {
                _initTimer.stop();
            }
            if (_app) return;

            if (_rotation) {
                _rotation.stop();
                if (_rotation.parent) {
                    removeChild(_rotation);
                }
            }
            nextFrame();
            try {
                var mainClass:Class = Class(getDefinitionByName("org.flowplayer.view.Launcher"));
                _app = new mainClass() as DisplayObject;
                addChild(_app as DisplayObject);
                trace("Launcher instantiated");
                trace("stage size " + stageWidth + " x " + stageHeight);
            } catch (e:Error) {
                trace("error instantiating Launcher " + e + ": " + e.message);
                if (! _initTimer) {
                    trace("starting init timer");
                    _app = null;
                    prevFrame();
                    _initTimer = new Timer(300);
                    _initTimer.addEventListener(TimerEvent.TIMER, function(e:TimerEvent):void { init(); });
                }
                _initTimer.start();
                if (_rotation) {
                    addChild(_rotation);
                    _rotation.start();
                }
                return;
            }
        }

		private function prepareStage():void {
            if (! stage) return;
            stage.align = StageAlign.TOP_LEFT;
            stage.scaleMode = StageScaleMode.NO_SCALE;
            stageHeight = stage.stageHeight;
            stageWidth = stage.stageWidth;
        }

        public static function get stageHeight():int {
            return _stageHeight;
        }

        public static function set stageHeight(val:int):void {
            if (val < _stageHeight) return;
            _stageHeight = val;
        }

        public static function get stageWidth():int {
            return _stageWidth;
        }

        public static function set stageWidth(val:int):void {
            if (val < _stageWidth) return;
            _stageWidth = val;
        }
    }
}
