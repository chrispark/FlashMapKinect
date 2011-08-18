package
{
	import com.adobe.serialization.json.JSON;
	
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.geom.Point;
	import flash.utils.ByteArray;
	
	import org.tuio.ITuioListener;
	import org.tuio.TuioClient;
	import org.tuio.TuioCursor;
	import org.tuio.connectors.LCConnector;
	import org.tuio.osc.OSCMessage;
	
	public class KinectTUIOClient extends TuioClient
	{
		
		private var fseq:uint = 0;
		private var frameHelper:Sprite;
		
		//private var connection:DatagramSocket;
		
		private var listeners:Array;
		private var _tuioCursors:Array;
		
		//
		private var _connector:LCConnector; 
		
		public function KinectTUIOClient(connector:LCConnector)
		{
			super(null);
			
			_connector = connector;
			_connector.addClient(this);
			
			frameHelper = new Sprite();
			frameHelper.addEventListener(Event.ENTER_FRAME, frameHandler);
			
			this.listeners = new Array();
			
			this._tuioCursors = new Array();
		}
		
		private function frameHandler(event:Event):void
		{
			fseq++;
			dispatchNewFseq();
		}
		
		private function dispatchNewFseq():void {
			for each(var l:ITuioListener in this.listeners) {
				l.newFrame(this.fseq);
			}
		}
		
		override public function acceptOSCMessage(message:OSCMessage):void
		{
			//we do nothing here, as we listen for JSON encoded UDP traffic
		}
		
		public function acceptJSONData(bytes:ByteArray):void{
			var data:String = bytes.readUTFBytes(bytes.bytesAvailable);
			var decoded:Object = JSON.decode(data);
			
			
			//decoded.UserIndex
			//decoded.TrackingID
			//decoded.EnrollmentIndex
			//decoded.Joints[0].ID;
			//decoded.Joints[0].TrackingState;
			//decoded.Joints[0].Position
			
			
			if(decoded.Joints != null && decoded.Joints.length >= JointID.Count)
			{
				for each(var jointData:Object in decoded.Joints)
				{
					normalizeJointData(jointData);
				}
				handleJoint(decoded, JointID.HandLeft);
				handleJoint(decoded, JointID.HandRight);
			}
		}
		/*
		public function startListening(port:uint):void
		{
			stopListing();
			
			connection = new DatagramSocket();
			connection.addEventListener(DatagramSocketDataEvent.DATA, dataHandler, false, 0, true);
			connection.bind(port);
			connection.receive();
		}
		
		public function stopListing():void
		{
			if(connection != null)
			{
				if(connection.connected)
				{
					connection.close();
				}
				connection.removeEventListener(DatagramSocketDataEvent.DATA, dataHandler);
			}
			connection = null;
		}
		
		private function dataHandler(event:DatagramSocketDataEvent):void
		{
			var data:String = event.data.readUTFBytes(event.data.bytesAvailable);
			var decoded:Object = JSON.decode(data);
			
			
			//decoded.UserIndex
			//decoded.TrackingID
			//decoded.EnrollmentIndex
			//decoded.Joints[0].ID;
			//decoded.Joints[0].TrackingState;
			//decoded.Joints[0].Position
			
			
			if(decoded.Joints != null && decoded.Joints.length >= JointID.Count)
			{
				for each(var jointData:Object in decoded.Joints)
				{
					normalizeJointData(jointData);
				}
				handleJoint(decoded, JointID.HandLeft);
				handleJoint(decoded, JointID.HandRight);
			}
		}*/
		
		private function normalizeJointData(jointData:Object):void
		{
			jointData.Position.X += .5;
			jointData.Position.Y *= -1;
			jointData.Position.Y += .5;
			//jointData.Position.X *= .5;
			//jointData.Position.Y *= .5;
		}
		
		private function handleJoint(userData:Object, jointID:uint):void
		{
			var targetCursorId:int = -1;
			var jointData:Object = userData.Joints[jointID];
			switch(jointID)
			{
				case JointID.HandLeft:
					targetCursorId = Number("" + userData.UserIndex + "0");
					break;
				case JointID.HandRight:
					targetCursorId = Number("" + userData.UserIndex + "1");
					break;
			}
			if(targetCursorId > -1)
			{
				var now:Date = new Date();
				var cursor:JointCursor = getCursorBySessionID(targetCursorId);
				var cursorUpdate:Boolean = (cursor != null);
				
				var s:Number = targetCursorId;
				var x:Number = jointData.Position.X;
				var y:Number = jointData.Position.Y;
				var z:Number = jointData.Position.Z;
				var X:Number = 0;
				var Y:Number = 0;
				var Z:Number = 0;
				var m:Number = 0;
				var dt:Number = 1;
				
				//check the z-distance of targetJoint with torso
				var diff:Number = userData.Joints[JointID.Spine].Position.Z - jointData.Position.Z;				
				var remove:Boolean = (diff < 0.3);
				
				if(remove)
				{
					if(cursorUpdate)
					{
						var index:int = this._tuioCursors.indexOf(cursor);
						if(index > -1)
						{
							this._tuioCursors.splice(index, 1);
						}
						dispatchRemoveCursor(cursor);
					}
				}
				else
				{
					if(cursorUpdate)
					{
						dt = (now.time - cursor.previousUpdate.time) / 1000;
						if(dt > 0)
						{
							X = (cursor.x - x) / dt;
							Y = (cursor.y - y) / dt;
							Z = (cursor.z - z) / dt;
							
							var distance:Number = Point.distance(new Point(cursor.x, cursor.y), new Point(x, y));
							
							m = (distance - cursor.previousDistance) / dt;
							cursor.previousDistance = distance;
						}						
						cursor.update(x, y, z, X, Y, Z, m, fseq);
						dispatchUpdateCursor(cursor);
					}
					else
					{
						cursor = new JointCursor("cursor", s, x, y, z, X, Y, Z, m, fseq);
						this._tuioCursors.push(cursor);
						dispatchAddCursor(cursor);
					}
				}
			}
		}
		
		private function getCursorBySessionID(sessionID:uint):JointCursor
		{
			for each(var cursor:JointCursor in _tuioCursors)
			{
				if(cursor.sessionID == sessionID)
				{
					return cursor;
				}
			}
			return null;
		}
		
		/**
		 * @return A copy of the list of currently active tuioCursors
		 */
		override public function get tuioCursors():Array {
			return this._tuioCursors.concat();
		}
		
		/**
		 * Adds a listener to the callback stack. The callback functions of the listener will be called on incoming TUIOEvents.
		 * 
		 * @param	listener Object of a class that implements the callback functions defined in the ITuioListener interface.
		 */
		override public function addListener(listener:ITuioListener):void {
			if (this.listeners.indexOf(listener) > -1) return;
			this.listeners.push(listener);
		}
		
		/**
		 * Removes the given listener from the callback stack.
		 * 
		 * @param	listener
		 */
		override public function removeListener(listener:ITuioListener):void {
			var temp:Array = new Array();
			for each(var l:ITuioListener in this.listeners) {
				if (l != listener) temp.push(l);
			}
			this.listeners = temp.concat();
		}
		
		private function dispatchAddCursor(tuioCursor:TuioCursor):void {
			for each(var l:ITuioListener in this.listeners) {
				l.addTuioCursor(tuioCursor);
			}
		}
		
		private function dispatchUpdateCursor(tuioCursor:TuioCursor):void {
			for each(var l:ITuioListener in this.listeners) {
				l.updateTuioCursor(tuioCursor);
			}
		}
		
		private function dispatchRemoveCursor(tuioCursor:TuioCursor):void {
			for each(var l:ITuioListener in this.listeners) {
				l.removeTuioCursor(tuioCursor);
			}
		}
	}
}
import org.tuio.TuioCursor;

internal class JointCursor extends TuioCursor
{
	public var previousUpdate:Date;
	public var previousDistance:Number = 0;
	
	public function JointCursor(type:String, sID:Number, x:Number, y:Number, z:Number, X:Number, Y:Number, Z:Number, m:Number, frameID:uint)
	{
		super(type, sID, x, y, z, X, Y, Z, m, frameID);
		previousUpdate = new Date();
	}
	
	override public function update(x:Number, y:Number, z:Number, X:Number, Y:Number, Z:Number, m:Number, frameID:uint):void
	{
		super.update(x, y, z, X, Y, Z, m, frameID);
		previousUpdate = new Date();
	}
}