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
        }

        private function onAddedToStage(event:Event):void {
            log("onAddedToStage(): stage size " + stage.width + " x " + stage.height);
            if (rotationEnabled) {
                _rotation = new RotatingAnimation();
                addChild(_rotation);
                arrange();
                _rotation.start();
            }

            addEventListener(Event.RESIZE, arrange);
            loaderInfo.addEventListener(ProgressEvent.PROGRESS, onLoadProgress);
//            loaderInfo.addEventListener(Event.COMPLETE, init);

            // prepare stage if the app (Launcher) has been greated already. this is the
            // case when we are embedded in another SWF
            if (_app) {
                prepareStage();
            }
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

		private function onLoadProgress(event:ProgressEvent):void {
  			var percent:Number = Math.floor((event.bytesLoaded*100) / event.bytesTotal);
            log(percent);
            if (_rotation) {
                Arrange.center(_rotation, stage.stageWidth, stage.stageHeight);
            }
            if (percent < 100) {
                return;
            }
            prepareStage();
            if (stageHasSize()) {
                log("onLoadProgress() calling init()");
                init();
            } else {
                log("onLoadProgress() starting stage wait");
                startStageWait();
            }
   		}
       
        private function init(event:Event = null):void {
            log("init()");
            if (_initTimer) {
                _initTimer.stop();
            }
            if (_stageTimer) {
                _stageTimer.stop();
            }
            nextFrame();
//            prepareStage();

            if (! stageHasSize()) {
                log("init(), stage does not have size yet, starting wait timer");
                startStageWait();
                return;
            } else {
                log("stage has size " + stage.stageWidth + " x " + stage.stageHeight);
            }
            if (_app) {
                log("init(), _app already instantiated returning");
                return;
            }
            if (_rotation) {
                _rotation.stop();
                if (_rotation.parent) {
                    removeChild(_rotation);
                }
            }

            try {
                var mainClass:Class = Class(getDefinitionByName("org.flowplayer.view.Launcher"));
                _app = new mainClass() as DisplayObject;
                addChild(_app as DisplayObject);
                log("Launcher instantiated " + _app);
            } catch (e:Error) {
                log("error instantiating Launcher " + e + ": " + e.message);
                _app = null;
                if (! _initTimer) {
                    log("starting init timer");
                    prevFrame();
                    _initTimer = new Timer(300);
                    _initTimer.addEventListener(TimerEvent.TIMER, function(e:TimerEvent):void { init(); });
                }
                _initTimer.start();
            }
        }

		private function prepareStage():void {
            if (! stage) return;
            stage.align = StageAlign.TOP_LEFT;
            stage.scaleMode = StageScaleMode.NO_SCALE;
        }

        private function log(msg:Object):void {
            _log.debug(msg + "");
            trace(msg + "");
        }

        private function stageHasSize():Boolean {
            return stage.stageWidth > 0 && stage.stageHeight > 0
        }

        private function get rotationEnabled():Boolean {
            var config:Object = stage.loaderInfo.parameters["config"];
            if (! config) return true;
            if (config.replace(/\s/g, "").indexOf("buffering:null") > 0) return false;
            return true;
        }

        private function arrange(event:Event = null):void {
            _rotation.setSize(stage.height * 0.22, stage.width * 0.22);
            Arrange.center(_rotation, stage.width, stage.stage.height - 28);
        }
    }
}
