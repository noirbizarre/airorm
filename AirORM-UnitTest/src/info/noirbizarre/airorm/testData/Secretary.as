package info.noirbizarre.airorm.testData
{
	import info.noirbizarre.airorm.ActiveRecord;

	[HasOne("employer",className="Employer")]
	public dynamic class Secretary extends ActiveRecord
	{
		public var name:String;
	}
}