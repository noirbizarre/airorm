package info.noirbizarre.airorm.testData
{
	import info.noirbizarre.airorm.ActiveRecord;
	
	import mx.collections.ArrayCollection;
	
	[BelongsTo("employer",className="Employer")]
	[ManyToMany("tasks",className="Task",property="employees")]
	public dynamic class Employee extends ActiveRecord
	{
		public var name:String;
		public var position:String;
		public var hireDate:Date;
		public var salary:Number;
	}
}