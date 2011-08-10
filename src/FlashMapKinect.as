package
{
	import de.polygonal.ds.NullIterator;
	
	import flash.display.LoaderInfo;
	import flash.display.Sprite;
	
	import net.daum.map.Map;
	import net.daum.map.controller.ExternalController;
	import net.daum.map.event.MapEvent;
	import net.daum.map.model.MapConfig;
	import net.daum.map.model.vo.AttitudeVO;
	import net.daum.map.model.vo.PointVO;
	import net.daum.map.model.vo.SizeVO;
	
	[SWF(width="1024", height="700", frameRate="12", backgroundColor="#111111")]
	public class FlashMapKinect extends Sprite
	{
		private var _map:Map;
		private var _config:MapConfig;
		private var _external:ExternalController;
		
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
			
			//initControls();
		}
	}
}