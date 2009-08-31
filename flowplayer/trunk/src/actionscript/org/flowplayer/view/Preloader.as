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
    import org.flowplayer.util.Log;
    import org.flowplayer.util.LogConfiguration;

    public class Preloader extends MovieClip {
        private var _log:Log = new Log(this);
        private var _app:DisplayObject;
        private var _initTimer:Timer;
        private var _stageTimer:Timer;
        private var _rotation:RotatingAnimation;
        private static var _stageHeight:int = 0;
        private static var _stageWidth:int = 0;
        // this variable can be set from external SWF files, if it's set well use it to construct the config
        public var injectedConfig:String;
        private var _ready:Boolean = false;

        public function Preloader() {

            var logConfig:LogConfiguration = new LogConfiguration();
            logConfig.level = "error";
            logConfig.filter = "org.flowplayer.view.Preloader";
            Log.configure(logConfig);
            _log.debug("Preloader") ;

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
                if (stage.stageWidth == 0 || stage.stageHeight == 0) {
                    log("player completeley loaded but stage dimensions still zero, waiting for stage to have size");
                    startStageWait();
                    return false;
                }

                init();
                return true;
            }
            return false;
        }

        private function startStageWait():void {
            if (_stageTimer) return;
            _stageTimer = new Timer(200);
            _stageTimer.addEventListener(TimerEvent.TIMER, onStageWait);
            _stageTimer.start();
        }

        private function onStageWait(event:TimerEvent):void {
            if (stage.stageWidth == 0 || stage.stageHeight == 0) {
                log("stage dimensions " + stage.stageWidth + "x" + stage.stageHeight);
                return;
            }
            log("stage has nonzero size " + stage.stageWidth + "x" + stage.stageHeight);
            if (_ready) {
                _stageTimer.stop();
                init();
            } else {
                _ready = true;
            }
        }

        private function arrange(event:Event = null):void {
            stageHeight = stage.stageHeight;
            stageWidth = stage.stageWidth;
            _rotation.setSize(stageHeight * 0.22, stageHeight * 0.22);
            Arrange.center(_rotation, stage.width, stage.height - 28);
        }

        private function onAddedToStage(event:Event):void {
            log("onAddedToStage(): stage size " + stageWidth + " x " + stageHeight);
//            prepareStage();
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
            log(percent);
            if (_rotation) {
                Arrange.center(_rotation, stageWidth, stageHeight);
            }
   		}
       
        private function init(event:Event = null):void {
            log("init()");
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
            prepareStage();
            try {
                var mainClass:Class = Class(getDefinitionByName("org.flowplayer.view.Launcher"));
                _app = new mainClass() as DisplayObject;
                addChild(_app as DisplayObject);
                log("Launcher instantiated");
                log("stage size " + stageWidth + " x " + stageHeight);
            } catch (e:Error) {
                log("error instantiating Launcher " + e + ": " + e.message);
                if (! _initTimer) {
                    log("starting init timer");
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

        private function log(msg:Object):void {
            _log.debug(msg + "");
            trace(msg + "");
        }
    }
}
