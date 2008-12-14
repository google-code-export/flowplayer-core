package org.flowplayer.controller {
	import org.flowplayer.model.ClipType;	
	import org.flowplayer.model.ClipEventType;	
	import org.flowplayer.model.Cuepoint;	
	import org.flowplayer.util.Log;	
	
	import flash.events.TimerEvent;	
	import flash.utils.Timer;	
	import flash.events.EventDispatcher;	
	
	import org.flowplayer.model.Clip;import flash.utils.getTimer;	
	
	/**
	 * PlayTimeTracker is responsible of tracking the playhead time. It checks
	 * if the clip's whole duration has been played and notifies listeners when
	 * this happens. It's also responsible of firing cuepoints.
	 * 
	 * @author Anssi
	 */
	internal class PlayTimeTracker extends EventDispatcher {

		private var log:Log = new Log(this);
		private var _clip:Clip;
		private var _startTime:int;
		private var _timer:Timer;
		private var _storedTime:int = 0;
		private var _previousCuePointTime:int = -1;
		private var _onLastSecondDispatched:Boolean;
		private var _controller:MediaController;

		public function PlayTimeTracker(clip:Clip, controller:MediaController) {
			_clip = clip;
			_controller = controller;
		}
		
		public function start():void {
			if (_timer && _timer.running)
				stop();
			_timer = new Timer(30);
			_timer.addEventListener(TimerEvent.TIMER, checkProgress);
			_startTime = getTimer();
			log.debug("started at time " + time);
			_timer.start();
			_onLastSecondDispatched = false;
		}

		public function stop():void {
			if (!_timer) return;
			_timer.stop();
			_storedTime = time;
			log.debug("stopped at time " + _storedTime);
		}

		public function set time(value:Number):void {
			log.debug("setting time to " + value);
			_storedTime = value;
			_startTime = getTimer();
		}

		public function get time():Number {
			if (! _timer) return 0;
			
			var timeNow:Number = getTimer();
			var _timePassed:Number = _storedTime + (timeNow - _startTime)/1000;

			if (_clip.type == ClipType.VIDEO) {
				// this is a sanity check that we have played at least one second
				if (getTimer() - _startTime < 2000) {
					return _timePassed;
				}
				return _controller.time;
			}
			
			if (! _timer.running) return _storedTime;
			return _timePassed;
		}

		private function checkProgress(event:TimerEvent):void {
			if (!_timer) return;
			checkAndFireCuepoints();
			
			if (_clip.live) return;
			var timePassed:Number = time;
			if (! _clip.duration) {
				// The clip does not have a duration, wait a few seconds before stopping the _timer.
				// Duration may become available once it's loaded from metadata.
				if (timePassed > 5) {
					log.debug("durationless clip, stopping duration tracking");
					_timer.stop();					
				}
				return;
			}
			if (completelyPlayed(_clip)) {
				stop();
				log.info(this + " completely played, dispatching complete");
				log.info("clip.durationFromMetadata " + _clip.durationFromMetadata);
				log.info("clip.duration " + _clip.duration);
				dispatchEvent(new TimerEvent(TimerEvent.TIMER_COMPLETE));
			}
			
			if (! _onLastSecondDispatched && timePassed >= _clip.duration - 1) {
				_clip.dispatch(ClipEventType.LAST_SECOND);
				_onLastSecondDispatched = true;
			}
		}
		
		private function completelyPlayed(clip:Clip):Boolean {
			
			if (clip.durationFromMetadata > clip.duration) {
				return time >= clip.duration;
			}
			return clip.duration - time < 0.2;
		}

		private function checkAndFireCuepoints():void {
			var streamTime:Number = _controller.time;
			var timeRounded:Number = Math.round(streamTime*10) * 100;
//			log.debug("checkAndFireCuepoints, rounded stream time is " + timeRounded);			
			// clear previous cuepoint after 1 sec has passed from it
			if (Math.abs(streamTime*1000 - _previousCuePointTime) > 100) {
				_previousCuePointTime = -1;
			}
			
			var points:Array = _clip.getCuepoints(timeRounded);
			if (! points || points.length == 0) {
				return;
			}
//			log.debug("found cuepoints ", points);
			if (alreadyFired(points[0], streamTime)) {
//				log.debug("alreadyFired at " + streamTime);
				return;
			}
			for (var i:Number = 0; i < points.length; i++) {
				var cue:Cuepoint = points[i];
//				log.info("cuePointReached: " + cue);
				_clip.dispatch(ClipEventType.CUEPOINT, cue);
			}
			_previousCuePointTime = (points[points.length -1] as Cuepoint).time;
		}

		private function alreadyFired(currentCuePoint:Cuepoint, streamTime:Number):Boolean {
			if (_previousCuePointTime == -1) return false;
			return currentCuePoint.time == _previousCuePointTime && streamTime*1000 - currentCuePoint.time <= 100;
		}

		public function get durationReached():Boolean {
			return _clip.duration > 0 && time >= _clip.duration;
		}
		
	}
}
