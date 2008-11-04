package info.noirbizarre.airorm.testMain
{
	import flash.data.SQLConnection;
	import flash.data.SQLStatement;
	import flash.filesystem.File;
	
	import info.noirbizarre.airorm.ORM;
	import info.noirbizarre.airorm.testData.Employee;
	import info.noirbizarre.airorm.testData.Employer;
	import info.noirbizarre.airorm.testData.Secretary;
	import info.noirbizarre.airorm.testData.SimpleActiveRecord;
	import info.noirbizarre.airorm.testData.Task;
	import info.noirbizarre.airorm.utils.DB;
	
	import mx.collections.ArrayCollection;
	
	import net.digitalprimates.fluint.tests.TestCase;
	
	public class ActiveRecordTest extends TestCase
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
			dbFile.deleteFile();
		}
		
		public function testConstructor():void {
			var employee:Employee = new Employee();
			assertNotNull("Should be instanciated", employee);
			assertNotNull("Should have a valid connection", employee.connection);
			assertNotNull("Collections must be initialized", employee.tasks);
			assertTrue("Collection must be an Array", employee.tasks is Array);
			var employer:Employer = new Employer();
			assertNotNull("Should be instanciated", employer);
			assertNotNull("Should have a valid connection", employer.connection);
			assertNotNull("Collections must be initialized", employer.employees);
			assertTrue("Collection must be an Array", employer.employees is Array);
			var task:Task = new Task();
			assertNotNull("Should be instanciated", task);
			assertNotNull("Should have a valid connection", task.connection);
			assertNotNull("Collection must be initialized", task.employees);
			assertTrue("Collection must be an Array", task.employees is Array);
		}
		
		public function testUID():void {
			var employee:Employee = new Employee();
			var uid:String = employee.uid;
			assertNotNull("Should have a UID", uid);
			employee.save();
			assertNotNull("Should have a UID", employee.uid);
			assertFalse("Persisted UID should be different", employee.uid==uid);
		}
		
		public function testSave():void {
			var s:SimpleActiveRecord = new SimpleActiveRecord();
			assertEquals("Should have null ID", 0, s.id);
			s.save();
			assertTrue("Should have an ID>0", s.id>0);
			var stmt:SQLStatement = new SQLStatement();
			stmt.sqlConnection = DB.getConnection("main", true);
			stmt.text = "select * from SimpleActiveRecords where id="+s.id;
			stmt.execute();
			var data:Array = stmt.getResult().data;
			assertEquals("Should have only one result",1,data.length);
			s.myString = "Test";
			s.myBool = true;
			s.myInt = 5;
			s.myDate = new Date();
			s.save()
		}
		
		public function testLoad():void {
			var stmt:SQLStatement = new SQLStatement();
			stmt.sqlConnection = DB.getConnection("main", true);
			stmt.text = "insert into Employees(name,position) values ('Employee1', 'Developer')";
			stmt.execute();
			var employee:Employee = new Employee();
			employee.load(stmt.getResult().lastInsertRowID);
			assertEquals("Should have the correct name","Employee1",employee.name);
			assertEquals("Should have the correct position","Developer",employee.position);
		}
		
		public function testLoadBy():void {
			fail("No test implemented");
		}
		
		public function testFind():void {
			fail("No test implemented");
		}
		
		public function testFindAll():void {
			fail("No test implemented");
		}
		
		public function testFindBySQL():void {
			fail("No test implemented");
		}
		
		public function testExists():void {
			var stmt:SQLStatement = new SQLStatement();
			stmt.sqlConnection = DB.getConnection("main", true);
			stmt.text = "insert into Employees(name,position) values ('Employee1', 'Developer')";
			stmt.execute();
			var id:uint = stmt.getResult().lastInsertRowID;
			var employee:Employee = new Employee();
			assertTrue("Should exists",employee.exists(id));
			assertFalse("Should not exists",employee.exists(id + 1));
		}
		
		public function testCreate():void {
			fail("No test implemented");
		}
		
		public function testUpdate():void {
			fail("No test implemented");
		}
		
		public function testUpdateAll():void {
			fail("No test implemented");
		}
		
		public function testDeleteById():void {
			fail("No test implemented");
		}
		
		public function testDeleteAll():void {
			fail("No test implemented");
		}
		
		public function testCount():void {
			var stmt:SQLStatement = new SQLStatement();
			stmt.sqlConnection = DB.getConnection("main", true);
			stmt.text = "insert into Employees(name,position) values ('Employee1', 'Developer')";
			stmt.execute();
			var employee:Employee = new Employee();
			assertEquals("Should return the correct number of objects", 1, employee.count());
			stmt.text = "insert into Employees(name,position) values ('Employee2', 'Developer')";
			stmt.execute();
			assertEquals("Should return the correct number of objects", 2, employee.count());
		}
		
		public function testCountBySql():void {
			fail("No test implemented");
		}
		
		public function testIncrementCounter():void {
			fail("No test implemented");
		}
		
		public function testDecrementCounter():void {
			fail("No test implemented");
		}
		
		public function testLoadRelated():void {
			fail("No test implemented");
		}
		
		public function testCountRelated():void {
			fail("No test implemented");
		}
		
		public function testSaveRelated():void {
			fail("No test implemented");
		}
		
		public function testDeleteRelated():void {
			fail("No test implemented");
		}
		
		public function testClassName():void {
			var employee:Employee = new Employee();
			assertEquals("Should be the short class name", "Employee", employee.className);
			var employer:Employer = new Employer();
			assertEquals("Should be the short class name", "Employer", employer.className);
		}
		
		public function testQuery():void {
			fail("No test implemented");
		}
		
		public function testAsyncQuery():void {
			fail("No test implemented");
		}
		
		public function testLoadItems():void {
			fail("No test implemented");
		}
		
		public function testAssembleQuery():void {
			fail("No test implemented");
		}
		
		public function testDBProperties():void {
			fail("No test implemented");
		}
		
		public function testGetSchema():void {
			fail("No test implemented");
		}
		
		public function testGetFields():void {
			fail("No test implemented");
		}
		
		
	}
}