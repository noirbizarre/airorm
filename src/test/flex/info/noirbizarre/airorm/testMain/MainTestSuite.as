package info.noirbizarre.airorm.testMain
{	
	[Suite]
	[RunWith("org.flexunit.runners.Suite")]
	public class MainTestSuite
	{
		public var schemaTranslationTest:SchemaTranslationTest;
		public var ormTest:ORMTest;
		public var relationalOperationTest:RelationalOperationTest;
		public var activeRecordTest:ActiveRecordTest;
	}
}