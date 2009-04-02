package org.flowplayer.view {
	import flash.display.DisplayObject;
	import flash.display.MovieClip;
	import flash.display.Sprite;
	import flash.display.StageAlign;
	import flash.display.StageScaleMode;
	import flash.events.Event;
	import flash.events.ProgressEvent;
    import flash.events.TimerEvent;
import flash.text.TextField;
	import flash.text.TextFormat;
    import flash.utils.Timer;
import flash.utils.getDefinitionByName;

	public class Preloader extends MovieClip {

		private var _app:DisplayObject;
		private var _percent:TextField;
        private var _initTimer:Timer;

		public function Preloader() {
            stop();
            if (checkLoaded()) return;
            
            _percent = new TextField();
            var format:TextFormat = new TextFormat();
            format.font = "Lucida Grande, Lucida Sans Unicode, Bitstream Vera, Verdana, Arial, _sans, _serif";
            _percent.defaultTextFormat = format;
            _percent.text = "Loading...";
            addChild(_percent);
            addEventListener(Event.ADDED_TO_STAGE, onAddedToStage);
        }

        private function checkLoaded():Boolean {
            if (loaderInfo.bytesLoaded == loaderInfo.bytesTotal) {
                init();
                return true;
            }
            return false;
        }
		
		private function onAddedToStage(event:Event):void {
            trace("added to stage");
            if (checkLoaded()) return;
            loaderInfo.addEventListener(ProgressEvent.PROGRESS, onLoadProgress);
            loaderInfo.addEventListener(Event.COMPLETE, init);
		}

		private function onLoadProgress(event:ProgressEvent):void {
            if (checkLoaded()) return;
  			var percent:Number = Math.floor((event.bytesLoaded*100) / event.bytesTotal);
            graphics.clear();
            trace("percent " + percent);
            if (_percent) {
                _percent.text = (percent + "%");
                _percent.x = stage.stageWidth / 2 - _percent.textWidth / 2;
                _percent.y = stage.stageHeight / 2 - _percent.textHeight / 2;
            }
   		}
       
        private function init(event:Event = null):void {
            trace("init");
            if (_initTimer) {
                _initTimer.stop();
            }
            if (_app) return;
            
        	if (_percent) {
        		removeChild(_percent);
                _percent = null;
            }
        	prepareStage();
            nextFrame();
            try {
                var mainClass:Class = Class(getDefinitionByName("org.flowplayer.view.Launcher"));
                _app = new mainClass() as DisplayObject;
                addChild(_app as DisplayObject);
                trace("Launcher instantiated and added to frame " + currentFrame);
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
            }
        }

		private function prepareStage():void {
			stage.align = StageAlign.TOP_LEFT;
			stage.scaleMode = StageScaleMode.NO_SCALE;
		}
    }
}
