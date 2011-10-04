package info.noirbizarre.airorm.testData
{
	import info.noirbizarre.airorm.ActiveRecord;
	
	public dynamic class SimpleActiveRecord extends ActiveRecord
	{
		public var myString:String;
		public var myInt:uint;
		public var myBool:Boolean;
		public var myDate:Date;
		[NotPersisted] public var notPersisted:String;
		[Timestamp("creation")] public var created:Date;
		[Timestamp("modification")] public var modified:Date;
	}
}