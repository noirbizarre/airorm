package info.noirbizarre.airorm.testData
{
	import info.noirbizarre.airorm.ActiveRecord;
	
	import mx.collections.ArrayCollection;

	[ManyToMany("employees", className="Employee",property="tasks")]
	public dynamic class Task extends ActiveRecord
	{
		public var name:String;
	}
}