package
{
	import com.greensock.TweenMax;
	import com.greensock.easing.Quad;
	
	import flash.display.CapsStyle;
	import flash.display.JointStyle;
	import flash.display.LineScaleMode;
	import flash.display.Shape;
	import flash.display.Sprite;
	
	/**
	 * @author silvio paganini | s2paganini.com
	 */
	public class Ring extends Sprite
	{
		private var rings : Vector.<Shape>;
		
		public var activate:Boolean = false;
		
		public function Ring(name : String, parent : Sprite, _x : int, _y : int, size : int)
		{
			x = _x;
			y = _y;
			
			this.name = name;
			
			parent.addChild(this);
			
			rings = new Vector.<Shape>();
			
			for (var i : int = 0; i < 1; i++)
			{
				var ring : Shape = new Shape();
				ring.alpha = 0;
				
				var color : uint = 0xFFFFFF;
				
				with(ring)
				{
					graphics.clear();
					graphics.lineStyle(3, color, 1, true, LineScaleMode.NORMAL, CapsStyle.ROUND, JointStyle.ROUND);
					graphics.beginFill(color, 0);
					graphics.drawCircle(0, 0, size);
					graphics.endFill();
				}
				
				addChild(ring);
				
				rings.push(ring);
				
				TweenMax.to(ring, .005, {alpha:1, delay:i / 100});
			}
		}
		
		public function destroy() : void
		{
			for(var i : uint = 0; i<rings.length; i++){
				TweenMax.to(rings[i], .005, {alpha:0, delay:i / 100});
				if (parent) parent.removeChild(this);
			}
			
			TweenMax.delayedCall(rings.length * .5, parent.removeChild, [this]);
			
		}
		
		public function moveTo(_x : Number, _y: Number) : void
		{
			TweenMax.to(this, .3, {x : _x, y: _y, ease: Quad.easeOut});
		}
		
		public function updateActivate(z:Number):void{
			trace(z);
			if(z >= 1 && z < 1.2){
				activate = true;
				graphics.clear();
				graphics.lineStyle(3, 0x003399, 1, true, LineScaleMode.NORMAL, CapsStyle.ROUND, JointStyle.ROUND);
				graphics.beginFill(0xFFFFFF, 0.5);
				graphics.drawCircle(0, 0, 30);
				graphics.endFill();
			}else{
				activate = false;
				graphics.clear();
				graphics.lineStyle(3, 0xFFFFFF, 1, true, LineScaleMode.NORMAL, CapsStyle.ROUND, JointStyle.ROUND);
				graphics.beginFill(0xFFFFFF, 0);
				graphics.drawCircle(0, 0, 30);
				graphics.endFill();
			}
		}
	}
}

