package info.noirbizarre.airorm
{
	import flash.events.Event;

	public class ActiveRecordEvent extends Event
	{
		public static const SAVING:String = "saving";
		public static const SAVE:String = "save";
		
		public function ActiveRecordEvent(type:String, cancelable:Boolean = false)
		{
			super(type, false, cancelable);
		}
	}
}