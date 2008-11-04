package info.noirbizarre.airorm.testData
{
	import info.noirbizarre.airorm.ActiveRecord;
	
	import mx.collections.ArrayCollection;
	
	
	[HasOne("secretary",className="Secretary")];
	[HasMany("employees", className="Employee")]
	public dynamic class Employer extends ActiveRecord
	{
		public var name:String;
	}
}