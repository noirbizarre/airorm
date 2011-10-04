package info.noirbizarre.airorm.testUtils
{
	import info.noirbizarre.airorm.utils.Inflector;
	
	import net.digitalprimates.fluint.tests.TestCase;

	public class InflectorTest extends TestCase
	{	
		/**
		 * Test the pluralize function
		 */
		public function testPluralize():void {
			assertEquals("Plural form of search should be searches",Inflector.pluralize("search"),"searches");
			assertEquals("Plural form of fix should be fixes",Inflector.pluralize("fix"),"fixes");
			assertEquals("Plural form of process should be processes",Inflector.pluralize("process"),"processes");
			assertEquals("Plural form of query should be queries",Inflector.pluralize("query"),"queries");
			assertEquals("Plural form of wife should be wives",Inflector.pluralize("wife"),"wives");
			assertEquals("Plural form of woman should be women",Inflector.pluralize("woman"),"women");
			assertEquals("Plural form of person should be people",Inflector.pluralize("person"),"people");
			assertEquals("Plural form of child should be children",Inflector.pluralize("child"),"children");
			assertEquals("Plural form of task should be tasks",Inflector.pluralize("task"),"tasks");
		}
		
		public function testSingularize():void {
			assertEquals("Singular form of searches should be search","search",Inflector.singularize("searches"));
			assertEquals("Singular form of fixes should be fix","fix",Inflector.singularize("fixes"));
			assertEquals("Singular form of processes should be process","process",Inflector.singularize("processes"));
			assertEquals("Singular form of queries should be query","query",Inflector.singularize("queries"));
			assertEquals("Singular form of wives should be wife","wife",Inflector.singularize("wives"));
			assertEquals("Singular form of women should be woman","woman",Inflector.singularize("women"));
			assertEquals("Singular form of people should be person","person",Inflector.singularize("people"));
			assertEquals("Singular form of children should be child","child",Inflector.singularize("children"));
			assertEquals("Singular form of tasks should be task","task",Inflector.singularize("tasks"));
		}
		
		public function testCamelize():void {
			assertEquals("Camelcase form of my_word should be MyWord", "MyWord", Inflector.camelize("my_word"));
			assertEquals("Camelcase form of my_two_words should be MyTwoWords", "MyTwoWords", Inflector.camelize("my_two_words"));
		}
		
		public function testUnderscore():void {
			assertEquals("Underscore form of myWord should be my_word", "my_word", Inflector.underscore("myWord"));
			assertEquals("Underscore form of myTwoWords should be my_two_words", "my_two_words", Inflector.underscore("myTwoWords"));
		}
		
		public function testHumanize():void {
			assertEquals("Human form of ThisIsMyTest should be this is my test", "this is my test", Inflector.humanize("ThisIsMyTest"));
			assertEquals("Capitalized human form of ThisIsMyTest should be This Is My Test", "This Is My Test", Inflector.humanize("ThisIsMyTest",true));
			assertEquals("Human form of this_is_my_test should be this is my test", "this is my test", Inflector.humanize("this_is_my_test"));
			assertEquals("Capitalized human form of this_is_my_test should be This Is My Test", "This Is My Test", Inflector.humanize("this_is_my_test",true));
		}
		
		public function testUpperWords():void {
			assertEquals("'This Is My Test' should be unchanged", "This Is My Test", Inflector.upperWords("This Is My Test"));
			assertEquals("Capitalized form of 'this is my test' should be 'This Is My Test'", "This Is My Test", Inflector.upperWords("this is my test"));
		}
		
		public function testLowerWords():void {
			assertEquals("'this is my test' should be unchanged", "this is my test", Inflector.lowerWords("this is my test"));
			assertEquals("Lower form of 'This Is My Test' should be 'this is my test'", "this is my test", Inflector.lowerWords("This Is My Test"));
		}
		
		public function testUpperFirst():void {
			assertEquals("First letter should be capitalized", "This is my test", Inflector.upperFirst("this is my test"));
		}
		
		public function testLowerFirst():void {
			assertEquals("First letter should be lower case", "this Is My Test", Inflector.lowerFirst("This Is My Test"));
		}
		
		
	}
}