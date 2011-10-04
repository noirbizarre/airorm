package info.noirbizarre.airorm.testMain
{
	import flash.data.SQLConnection;
	import flash.filesystem.File;
	import flash.system.Capabilities;
	
	import info.noirbizarre.airorm.AOError;
	import info.noirbizarre.airorm.ORM;
	import info.noirbizarre.airorm.RelationalOperation;
	import info.noirbizarre.airorm.testData.Employee;
	import info.noirbizarre.airorm.testData.Employer;
	import info.noirbizarre.airorm.testData.Secretary;
	import info.noirbizarre.airorm.testData.SimpleActiveRecord;
	import info.noirbizarre.airorm.testData.SimpleClass;
	import info.noirbizarre.airorm.testData.Task;
	import info.noirbizarre.airorm.utils.DB;
	
	import net.digitalprimates.fluint.tests.TestCase;

	public class RelationalOperationTest extends TestCase
	{
		protected var dbFile:File;
		
		override protected function setUp():void {
			dbFile = File.createTempFile();
			DB.registerConnectionAlias(dbFile,"main");
			ORM.registerClass(Employee);
			ORM.registerClass(Employer);
			ORM.registerClass(Secretary);
			ORM.registerClass(Task);
			ORM.registerClass(SimpleActiveRecord);
			ORM.updateDB();
		}
		
		override protected function tearDown():void {
			var conn:SQLConnection = DB.getConnection("main", true);
			DB.clear(conn);
			conn.close();
			if (Capabilities.os.substr(0, 3).toLowerCase() != "win") {
			 	// Crash on windows
				dbFile.deleteFile();
			}
		}
		
		public function testConstructorFromClass():void {
			// Test hasOne RelationalOperation from class
			var ro:RelationalOperation = new RelationalOperation(Secretary, 'employer');
			assertNotNull("RelationalOperation should be instanciated", ro);
			assertEquals("Relation type should be 'hasOne'", RelationalOperation.HAS_ONE, ro.relationship);
			
			// Test hasMany RelationalOperation
			ro = new RelationalOperation(Employer, 'employees');
			assertNotNull("RelationalOperation should be instanciated", ro);
			assertEquals("Relation type should be 'hasMany'", RelationalOperation.HAS_MANY, ro.relationship);
			
			// Test belongsTo RelationalOperation
			ro = new RelationalOperation(Employee, 'employer');
			assertNotNull("RelationalOperation should be instanciated", ro);
			assertEquals("Relation type should be 'belongsTo'", RelationalOperation.BELONGS_TO, ro.relationship);
			
			// Test manyToMany RelationalOperation
			ro = new RelationalOperation(Employee, 'tasks');
			assertNotNull("RelationalOperation should be instanciated", ro);
			assertEquals("Relation type should be 'manyToMany'", RelationalOperation.MANY_TO_MANY, ro.relationship);
			
			// Error test
			var errorThrown:Boolean = false;
			try {
				ro = new RelationalOperation(SimpleClass, 'myPublicVar');
			} catch(e:AOError) {
				errorThrown = true;
			}
			assertTrue("Should have failed",errorThrown);
		}
		
		public function testConstructorFromString():void {
			// Test hasOne RelationalOperation
			var ro:RelationalOperation = new RelationalOperation("Secretary", "employer");
			assertNotNull("RelationalOperation should be instanciated", ro);
			assertEquals("Relation type should be 'hasOne'", RelationalOperation.HAS_ONE, ro.relationship);
			
			// Test hasMany RelationalOperation
			ro = new RelationalOperation("Employer", 'employees');
			assertNotNull("RelationalOperation should be instanciated", ro);
			assertEquals("Relation type should be 'hasMany'", RelationalOperation.HAS_MANY, ro.relationship);
			
			// Test belongsTo RelationalOperation
			ro = new RelationalOperation("Employee", 'employer');
			assertNotNull("RelationalOperation should be instanciated", ro);
			assertEquals("Relation type should be 'belongsTo'", RelationalOperation.BELONGS_TO, ro.relationship);
			
			// Test manyToMany RelationalOperation
			ro = new RelationalOperation("Employee", 'tasks');
			assertNotNull("RelationalOperation should be instanciated", ro);
			assertEquals("Relation type should be 'manyToMany'", RelationalOperation.MANY_TO_MANY, ro.relationship);
			
			// Error test
			var errorThrown:Boolean = false;
			try {
				ro = new RelationalOperation("SimpleClass", 'myPublicVar');
			} catch(e:AOError) {
				errorThrown = true;
			}
			assertTrue("Should have failed",errorThrown);
		}
		
		public function testConstructorFromInstance():void {
			// Test hasOne RelationalOperation
			var ro:RelationalOperation = new RelationalOperation(new Secretary(), 'employer');
			assertNotNull("RelationalOperation should be instanciated", ro);
			assertEquals("Relation type should be 'hasOne'", RelationalOperation.HAS_ONE, ro.relationship);
			
			// Test hasMany RelationalOperation
			ro = new RelationalOperation(new Employer(), 'employees');
			assertNotNull("RelationalOperation should be instanciated", ro);
			assertEquals("Relation type should be 'hasMany'", RelationalOperation.HAS_MANY, ro.relationship);
			
			// Test belongsTo RelationalOperation
			ro = new RelationalOperation(new Employee(), 'employer');
			assertNotNull("RelationalOperation should be instanciated", ro);
			assertEquals("Relation type should be 'belongsTo'", RelationalOperation.BELONGS_TO, ro.relationship);
			
			// Test manyToMany RelationalOperation
			ro = new RelationalOperation(new Employee(), 'tasks');
			assertNotNull("RelationalOperation should be instanciated", ro);
			assertEquals("Relation type should be 'manyToMany'", RelationalOperation.MANY_TO_MANY, ro.relationship);
			
			// Error test
			var errorThrown:Boolean = false;
			try {
				ro = new RelationalOperation(new SimpleClass(), 'myPublicVar');
			} catch(e:AOError) {
				errorThrown = true;
			}
			assertTrue("Should have failed",errorThrown);
		}
		
		public function testLoadRelated():void {
			fail("No test implemented");
		}
		
		public function countConstructor():void {
			fail("No test implemented");
		}
		
		public function testSaveRelated():void {
			fail("No test implemented");
		}
		
		public function testDeleteRelated():void {
			fail("No test implemented");
		}
		
		public function testMergeConditions():void {
			fail("No test implemented");
		}
		
	}
}