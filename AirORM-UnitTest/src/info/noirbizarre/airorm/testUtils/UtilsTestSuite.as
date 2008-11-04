package info.noirbizarre.airorm.testUtils
{
	import net.digitalprimates.fluint.tests.TestSuite;

	public class UtilsTestSuite extends TestSuite
	{
		public function UtilsTestSuite()
		{
			addTestCase(new InflectorTest());
			addTestCase(new ReflectionTest());
			addTestCase(new DBTest());
		}
		
	}
}