package
{
	import de.polygonal.ds.NullIterator;
	
	import flash.display.LoaderInfo;
	import flash.display.Shape;
	import flash.display.Sprite;
	import flash.display.Stage;
	import flash.display.StageQuality;
	import flash.events.TransformGestureEvent;
	import flash.text.engine.SpaceJustifier;
	import flash.ui.Mouse;
	
	import net.daum.map.Map;
	import net.daum.map.controller.ExternalController;
	import net.daum.map.event.MapEvent;
	import net.daum.map.model.MapConfig;
	import net.daum.map.model.vo.AttitudeVO;
	import net.daum.map.model.vo.PointVO;
	import net.daum.map.model.vo.SizeVO;
	
	import org.tuio.ITuioListener;
	import org.tuio.TouchEvent;
	import org.tuio.TuioBlob;
	import org.tuio.TuioClient;
	import org.tuio.TuioCursor;
	import org.tuio.TuioObject;
	import org.tuio.connectors.LCConnector;
	import org.tuio.gestures.DragGesture;
	import org.tuio.gestures.GestureManager;
	import org.tuio.gestures.ZoomGesture;
	import org.tuio.osc.OSCManager;
	
	[SWF(width="1024", height="700", frameRate="12", backgroundColor="#111111")]
	public class FlashMapKinect extends Sprite implements ITuioListener
	{
		private var _map:Map;
		private var _config:MapConfig;
		private var _external:ExternalController;
		
		private var _panEnabled:Boolean = false;
		
		public function FlashMapKinect()
		{
			initialize();
		}
		
		private function initialize():void{
			_map = new Map();
			_map.key = null;
			_map.setSize(new SizeVO(1024, 700));
			_map.addEventListener(MapEvent.MAP_INIT, daumMapInitHandler);
			
			this.addChild(_map);
			
			//stage.quality = StageQuality.HIGH;
		}
		
		private function daumMapInitHandler(event:MapEvent):void{
			_config     = MapConfig.getInstance();
			_external   = ExternalController.getInstance();
			
			startDisplayMap(LoaderInfo(this.loaderInfo).parameters);
		}
		
		public function startDisplayMap(parameters:Object=null):void
		{			
			_external.initFlashVars(parameters);
			
			var wgtX:Number       = Number(_external.getFlashVars(ExternalController.STATION_WGTX));
			var wgtY:Number       = Number(_external.getFlashVars(ExternalController.STATION_WGTY));
			var lineId:String     = _external.getFlashVars(ExternalController.STATION_LINE);
			var stationId:String  = _external.getFlashVars(ExternalController.STATION_ID);
			
			_config.defaultPoint  = new PointVO(wgtX, wgtY);
			
			_map.setCenter(new PointVO(wgtX, wgtY), MapConfig.DEFAULT_ZOOM_LV, MapConfig.DEFAULT_MAP_TYPE);
			_map.setAttitude(new AttitudeVO(0, 0, MapConfig.DEFAULT_ROLL_ANGLE));
			
			initKinectConnection();
		}
		
		public function initKinectConnection():void{
			initTransformGesture();
			
			var lcConnector:LCConnector = new LCConnector();
			var client:KinectTUIOClient = new KinectTUIOClient(lcConnector);
			client.addListener(this);
			
			var gestureManager:GestureManager = GestureManager.init(stage, client);
			gestureManager.touchTargetDiscoveryMode = GestureManager.TOUCH_TARGET_DISCOVERY_MOUSE_ENABLED;
			GestureManager.addGesture(new DragGesture());
			//var oscManager:OSCManager = new OSCManager(null, lcConnector);
			//oscManager.start();
		}
		
		private function initTransformGesture():void{
			stage.addEventListener(TransformGestureEvent.GESTURE_PAN, panHandler);
			stage.addEventListener(TransformGestureEvent.GESTURE_ZOOM, zoomHandler);
			//stage.addEventListener(TransformGestureEvent.GESTURE_ROTATE, rotateHandler);
			//stage.addEventListener(TouchEvent.TOUCH_DOWN, handleDown);
		}
		
		public function addTuioObject(tuioObject : TuioObject) : void{
			trace("addTuioObject");
		}
		
		public function updateTuioObject(tuioObject : TuioObject) : void{
			trace("updateTuioObject");
		}
		
		public function removeTuioObject(tuioObject : TuioObject) : void{
			trace("removeTuioObject");
		}
		
		public function addTuioCursor(tuioCursor : TuioCursor) : void{
			//trace("addTuioCursor");
			new Ring(tuioCursor.sessionID.toString(), this, tuioCursor.x * stage.stageWidth, tuioCursor.y * stage.stageHeight, 30);
			
			_map.setEndPoint(tuioCursor.x * stage.stageWidth, tuioCursor.y * stage.stageHeight);
		}
		
		public function updateTuioCursor(tuioCursor : TuioCursor) : void{
			//trace("updateTuioCursor" + tuioCursor.sessionID.toString());
			try
			{
				var ring : Ring = getChildByName(tuioCursor.sessionID.toString()) as Ring;
				ring.moveTo(tuioCursor.x * stage.stageWidth, tuioCursor.y * stage.stageHeight);
				ring.scaleX = tuioCursor.z;
				ring.scaleY = tuioCursor.z;
				ring.updateActivate(tuioCursor.z);
				
				if(ring.activate){
					_map.panBy(new PointVO(tuioCursor.x * stage.stageWidth, tuioCursor.y * stage.stageHeight));
				}
				
				//trace(tuioCursor.x, tuioCursor.y);
			}
			catch(e : Error)
			{
			}
		}
		
		public function removeTuioCursor(tuioCursor : TuioCursor) : void{
			//trace("removeTuioCursor");
			try
			{
				var ring : Ring = getChildByName(tuioCursor.sessionID.toString()) as Ring;
				ring.destroy();				
			}
			catch(e : Error)
			{
			}
		}
		
		public function addTuioBlob(tuioBlob : TuioBlob) : void{
			trace("addTuioBlob");
		}
		
		public function updateTuioBlob(tuioBlob : TuioBlob) : void{
			trace("updateTuioBlob");
		}
		
		public function removeTuioBlob(tuioBlob : TuioBlob) : void{
			trace("removeTuioBlob");
		}
		
		public function newFrame(id : uint) : void{
			//trace("newFrame");
		}
		
		private function panHandler(event:TransformGestureEvent):void{
			//trace("panHandler"+event.offsetX);
			if(true){				
				//var x:Number = (event.offsetX < 0) ? event.offsetX * -1 : event.offsetX;
				//var y:Number = (event.offsetY < 0) ? event.offsetY * -1 : event.offsetY;
				trace("panHandler");
				//_map.panBy(new PointVO(-event.offsetX, -event.offsetY));				
			}
		}
		
		private function zoomHandler(event:TransformGestureEvent):void{
			trace("zoomHandler");
			trace(event.scaleX, event.scaleY);
			
			_map.zoomOut();
		}
		
		private function rotateHandler(event:TransformGestureEvent):void{
			trace("rotateHandler");
		}
		
		private var curID : int = -1;
		
		private function handleDown(e : org.tuio.TouchEvent) : void
		{
			trace("handleDown : " + curID);			
			if (curID == -1) {
				_panEnabled = true;
				stage.setChildIndex(this, stage.numChildren - 1);
				this.curID = e.tuioContainer.sessionID;
				stage.addEventListener(TouchEvent.TOUCH_UP, handleUp);
			}
		}
		
		private function handleUp(e : TouchEvent) : void
		{
			trace("handleUp : " + e.tuioContainer.sessionID, this.curID);
			if (e.tuioContainer.sessionID == this.curID) {
				_panEnabled = false;
				this.curID = -1;
				stage.removeEventListener(TouchEvent.TOUCH_UP, handleUp);
			}
		}
	}
}