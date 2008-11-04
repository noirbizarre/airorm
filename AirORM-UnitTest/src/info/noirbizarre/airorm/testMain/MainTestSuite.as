package info.noirbizarre.airorm.testMain
{	
	import net.digitalprimates.fluint.tests.TestSuite;

	public class MainTestSuite extends TestSuite
	{
		public function MainTestSuite()
		{
			addTestCase( new SchemaTranslationTest() );
			addTestCase( new ORMTest() );
			addTestCase( new RelationalOperationTest() );
			addTestCase( new ActiveRecordTest() );
		}
		
	}
}