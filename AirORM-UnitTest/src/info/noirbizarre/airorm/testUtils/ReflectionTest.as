package info.noirbizarre.airorm.testUtils
{
	import flash.utils.getQualifiedClassName;
	
	import info.noirbizarre.airorm.testData.SimpleClass;
	import info.noirbizarre.airorm.utils.Reflection;
	
	import net.digitalprimates.fluint.tests.TestCase;

	public class ReflectionTest extends TestCase
	{
		private var obj:SimpleClass;
		
		override protected function setUp():void {
			obj = new SimpleClass();
		}
		
		public function testDescribe():void {
			var description:XML = Reflection.describe(obj);
			assertTrue("Should give ancestor class", description.extendsClass.@type == "Object");
			assertTrue("Should list all public variables", description.variable.length() == 2);
			assertTrue("Should list all public methods", description.method.length() == 1);
			assertTrue("Should give the correct type", description.variable.(@name == "myPublicVar").@type == "String");
		}
		
		public function testDescribeClass():void {
			var description:XML = Reflection.describe(SimpleClass);
			assertTrue("Should give ancestor class", description.extendsClass.@type == "Object");
			assertTrue("Should list all public variables", description.variable.length() == 2);
			assertTrue("Should list all public methods", description.method.length() == 1);
			assertTrue("Should give the correct type", description.variable.(@name == "myPublicVar").@type == "String");
		}
		
		public function testGetMember():void {
			var member:XML = Reflection.getMember(obj,"myPublicVar");
			var expected:XML = <variable name="myPublicVar" type="String"/>;
			assertEquals("Should return the correct member",expected,member);
			
			member = Reflection.getMember(obj,"myOtherVar");
			expected = <variable name="myOtherVar" type="String">
				<metadata name="TestMetadata" />
			</variable>;
			assertEquals("Should return the correct member with all its descendants",expected,member);
		}
		
		public function testGetMetadata():void {
			var metadata:XMLList = Reflection.getMetadata(obj,"TestMetadata");
			var expected:XMLList = new XMLList();
			expected += <metadata name="TestMetadata">
				<arg key="" value ="Test"/>
				<arg key="param" value ="TestParam"/>
			</metadata>;
			expected += <metadata name="TestMetadata"/>;
			assertEquals("Should return the XMLList TestMedata",expected,metadata);
		}
		
		public function testGetByMetadata():void {
			var metadata:XMLList = Reflection.getByMetadata(obj,"TestMetadata");
			var expected:XMLList = XMLList(<variable name="myOtherVar" type="String">
			    <metadata name="TestMetadata"/>
			  </variable>);
			assertEquals("Should return the XMLList of members containing TestMedata",expected,metadata);
		}
		
		public function testGetMetadataByArg():void {
			var metadata:XMLList = Reflection.getMetadataByArg(obj,"param", "TestParam");
			var expected:XMLList = XMLList(<metadata name="TestMetadata">
				<arg key="" value ="Test"/>
				<arg key="param" value ="TestParam"/>
			</metadata>);
			assertEquals("Should return the XMLList of members containing TestMedata",expected,metadata);
			metadata = Reflection.getMetadataByArg(obj,"", "Test");
			assertEquals("Should return the XMLList of members containing TestMedata",expected,metadata);
		}
		
		public function testGetShortClassName():void {
			assertEquals("Should returns the last part of class name", "SimpleClass", Reflection.getShortClassName(SimpleClass));
			assertEquals("Should returns the last part of class name", "SimpleClass", Reflection.getShortClassName(new SimpleClass()));
			assertEquals("Should returns the last part of class name", "SimpleClass", Reflection.getShortClassName(getQualifiedClassName(new SimpleClass())));
			assertEquals("Should returns the last part of class name", "SimpleClass", Reflection.getShortClassName("SimpleClass"));
		}
		
	}
}