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
	import org.flowplayer.controller.ResourceLoader;	
	import org.flowplayer.util.URLUtil;	
	import org.flowplayer.controller.ResourceLoaderImpl;
	import org.flowplayer.model.DisplayProperties;
	import org.flowplayer.model.Logo;
	import org.flowplayer.model.PlayerEvent;
	import org.flowplayer.util.Arrange;
	import org.flowplayer.view.AbstractSprite;
	
	import flash.display.DisplayObject;
	import flash.display.StageDisplayState;
	import flash.events.Event;
	import flash.events.FullScreenEvent;
	import flash.events.MouseEvent;
	import flash.events.TimerEvent;
	import flash.geom.Rectangle;
	import flash.net.URLRequest;
	import flash.net.navigateToURL;
	import flash.utils.Timer;	
	/**
	 * @author api
	 */
	public class LogoView extends AbstractSprite {

		private var _model:Logo;
		private var _player:Flowplayer;
		private var _image:DisplayObject;
		private var _panel:Panel;
		private var _originalProps:DisplayProperties;		public function LogoView(panel:Panel, model:Logo, player:Flowplayer) {
			_panel = panel;
			this.model = model;
			_originalProps = _model.clone() as DisplayProperties;
			log.debug("original model dimensions " + _originalProps.dimensions);
			_player = player;
			setEventListeners();

			CONFIG::commercialVersion {
				loadLogoImage();
			}

			CONFIG::freeVersion {
				createLogoImage(new FlowplayerLogo());
//				var logoTimer:Timer = new Timer(1000);
//				logoTimer.addEventListener(TimerEvent.TIMER, onLogoTimer);
//				logoTimer.start();
			}
			
		}
		
		CONFIG::freeVersion
		private function onLogoTimer(event:TimerEvent):void {
			if (! this.parent && _panel.stage.displayState == StageDisplayState.NORMAL) return;
			if (! this.parent) {
				show();
			}
			_panel.setChildIndex(this, _panel.numChildren -1);
		}
		
		override protected function onResize():void {
			if (_image) {
				log.debug("onResize, width " + width);
				if (_model.dimensions.width.hasValue() && _model.dimensions.height.hasValue()) {
					if (_image.height > _image.width) {
						_image.height = height;
						_image.scaleX = _image.scaleY;
					} else {
						_image.width = width;
						_image.scaleY = _image.scaleX;
					}
				}
				Arrange.center(_image, width, height);
			}
		}
		
//		override public function get width():Number {
//			return managedWidth;
//		}
//		
//		override public function get height():Number {
//			return managedHeight;
//		}

		CONFIG::commercialVersion
		private function loadLogoImage():void {
			if (_model.url) {
				log.debug("loading image from " + _model.url);
				_player.createLoader().load(_model.url, onImageLoaded);
			}
		}

		CONFIG::commercialVersion
		private function onImageLoaded(loader:ResourceLoader):void {
			log.debug("image loaded " + loader.getContent());
			createLogoImage(loader.getContent() as DisplayObject);
		}
		
		private function createLogoImage(image:DisplayObject):void {
			_image = image;
			addChild(_image);
			log.debug("logo shown in fullscreen only " + _model.fullscreenOnly);
			if (! _model.fullscreenOnly) {
				show();
			}
			onResize();

			// small hack to get the initial scaling correct
			show();
			if (_model.fullscreenOnly) {
				hide();
			}
		}

		private function setEventListeners():void {
			_panel.stage.addEventListener(FullScreenEvent.FULL_SCREEN, onFullscreen);
			
			if (_model.linkUrl) {
				addEventListener(MouseEvent.CLICK, 
					function(event:MouseEvent):void { navigateToURL(new URLRequest(_model.linkUrl), _model.linkWindow); });
				buttonMode = true;
			}
		}

		private function onFullscreen(event:FullScreenEvent):void {
			if (event.fullScreen) {
				show();
			} else {
				if (_model.fullscreenOnly) {
					hide(0);
				} else {
					update();
				}
			}
		}

		private function show():void {
			this.alpha = _model.opacity;
			this.visible = true;
			CONFIG::freeVersion {
				_model.zIndex = 100;
			}
			if (! this.parent) {
				log.debug("showing " + _model.dimensions);
				_panel.addView(this, null, _model);
				if (_model.displayTime > 0) {
					var timer:Timer = new Timer(_model.displayTime * 1000, 1);
					timer.addEventListener(TimerEvent.TIMER_COMPLETE, function(event:TimerEvent):void { hide(_model.fadeSpeed); });
					timer.start();
				}
			} else {
				update();
			}
		}

		private function update():void {
			log.debug("updating " + _model.dimensions);
			_panel.update(this, _model);
			_panel.draw(this);
		}
		
		private function hide(fadeSpeed:int = 0):void {
			log.debug("hiding logo");
			if (fadeSpeed > 0) {
				_player.animationEngine.fadeOut(this, fadeSpeed, removeFromPanel);
			} else {
				removeFromPanel();
			}
		}
		
		private function removeFromPanel():void {
			if (this.parent)
				_panel.removeChild(this);
		}
		
		CONFIG::freeVersion
		public function set model(model:Logo):void {
			// in the free version we ignore the supplied logo configuration
			_model = new Logo();
			_model.fullscreenOnly = model.fullscreenOnly;
			_model.height = "10%";
			_model.width = "10%";
			_model.top = "15";
			_model.right = "1";
			_model.linkUrl = "http://flowplayer.org";
			log.debug("initial model dimensions " + _model.dimensions);
		}
		
		CONFIG::commercialVersion
		public function set model(model:Logo):void {
			_model = model;
		}
	}
}
