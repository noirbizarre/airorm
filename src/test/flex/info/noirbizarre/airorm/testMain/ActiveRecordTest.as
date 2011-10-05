package info.noirbizarre.airorm.testMain {
	import org.flexunit.asserts.*;
	
	import flash.data.SQLConnection;
	import flash.data.SQLStatement;
	import flash.filesystem.File;
	import flash.system.Capabilities;
	
	import info.noirbizarre.airorm.ORM;
	import info.noirbizarre.airorm.testData.Employee;
	import info.noirbizarre.airorm.testData.Employer;
	import info.noirbizarre.airorm.testData.Secretary;
	import info.noirbizarre.airorm.testData.SimpleActiveRecord;
	import info.noirbizarre.airorm.testData.Task;
	import info.noirbizarre.airorm.utils.DB;
	import info.noirbizarre.airorm.utils.sql_db;
	
	import mx.collections.ArrayCollection;
	
	
	use namespace sql_db;
	
	public class ActiveRecordTest
	{
		protected var dbFile:File;
		
		[Before]
		protected function initORM():void {
			dbFile = File.createTempFile();
			DB.registerConnectionAlias(dbFile,"main");
			ORM.registerClass(Employee);
			ORM.registerClass(Employer);
			ORM.registerClass(Secretary);
			ORM.registerClass(Task);
			ORM.registerClass(SimpleActiveRecord);
			ORM.updateDB();
		}
		
		[After]
		protected function cleanup():void {
			var conn:SQLConnection = DB.getConnection("main", true);
			DB.clear(conn);
			conn.close();
			if (Capabilities.os.substr(0, 3).toLowerCase() != "win") {
			 	// Crash on windows
				dbFile.deleteFile();
			}
		}
		
		[Test]
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
		
		[Test]
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
			stmt.execute();
			data = stmt.getResult().data;
			assertEquals("Should have only one result",1,data.length);
			assertEquals("Test",data[0]["myString"]);
			assertEquals(true,data[0]["myBool"]);
			assertEquals(5,data[0]["myInt"]);
			assertNotNull(data[0]["myDate"]);
			assertNotNull(data[0]["modified"]);
			assertNotNull(data[0]["created"]);
			
			var employer:Employer = new Employer();
			employer.save();
			var employee:Employee = new Employee();
			employee.employer = employer;
			employee.save();
			stmt.text = "select * from Employees where id="+employee.id;
			stmt.execute();
			data = stmt.getResult().data;
			assertEquals(employer.id, data[0]["employer_id"]);
			
			var secretary:Secretary = new Secretary();
			secretary.save();
			employer.secretary = secretary;
			employer.save();
			stmt.text = "select * from Employers where id="+employer.id;
			stmt.execute();
			data = stmt.getResult().data;
			assertEquals(secretary.id, data[0]["secretary_id"]);
			secretary.employer = employer;
			secretary.save();
			stmt.text = "select * from Secretaries where id="+secretary.id;
			stmt.execute();
			data = stmt.getResult().data;
			assertEquals(employer.id, data[0]["employer_id"]);
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
			var s:SimpleActiveRecord = new SimpleActiveRecord();
			var res:Object = s.getDBProperties();
			var columns:ArrayCollection = new ArrayCollection();
			var col:String;
			for (col in res) {
				columns.addItem(col);
			}
			assertTrue("id column should exists", columns.contains("id"));
			assertTrue("myString column should exists", columns.contains("myString"));
			assertTrue("myBool column should exists", columns.contains("myBool"));
			assertTrue("myInt column should exists", columns.contains("myInt"));
			assertTrue("myDate column should exists", columns.contains("myDate"));
			assertTrue("modified column should exists", columns.contains("modified"));
			assertTrue("created column should exists", columns.contains("created"));
			assertFalse("connection should not exists", columns.contains("connection"));
			assertFalse("uid should not exists", columns.contains("uid"));
			assertFalse("notPersisted should not exists", columns.contains("notPersisted"));
			
			var employee:Employee = new Employee();
			res = employee.getDBProperties();
			columns = new ArrayCollection();
			for (col in res) {
				columns.addItem(col);
			}
			assertTrue("id column should exists", columns.contains("id"));
			assertTrue("name column should exists", columns.contains("name"));
			assertTrue("position column should exists", columns.contains("position"));
			assertTrue("hireDate column should exists", columns.contains("hireDate"));
			assertTrue("salary column should exists", columns.contains("salary"));
			assertFalse("connection should not exists", columns.contains("connection"));
			assertFalse("uid should not exists", columns.contains("uid"));
			assertTrue("employer_id column should exists", columns.contains("employer_id"));
			
			var employer:Employer = new Employer();
			res = employer.getDBProperties();
			columns = new ArrayCollection();
			for (col in res) {
				columns.addItem(col);
			}
			assertTrue("id column should exists", columns.contains("id"));
			assertTrue("name column should exists", columns.contains("name"));
			assertFalse("connection should not exists", columns.contains("connection"));
			assertFalse("uid should not exists", columns.contains("uid"));
			assertTrue("secretary_id column should exists", columns.contains("secretary_id"));
			assertFalse("employees_id column should not exists", columns.contains("employees_id"));
			
			var secretary:Secretary = new Secretary();
			res = secretary.getDBProperties();
			columns = new ArrayCollection();
			for (col in res) {
				columns.addItem(col);
			}
			assertTrue("id column should exists", columns.contains("id"));
			assertTrue("name column should exists", columns.contains("name"));
			assertFalse("connection should not exists", columns.contains("connection"));
			assertFalse("uid should not exists", columns.contains("uid"));
			assertTrue("employer_id column should exists", columns.contains("employer_id"));
			
			var task:Task = new Task();
			res = task.getDBProperties();
			columns = new ArrayCollection();
			for (col in res) {
				columns.addItem(col);
			}
			assertTrue("id column should exists", columns.contains("id"));
			assertTrue("name column should exists", columns.contains("name"));
			assertFalse("connection should not exists", columns.contains("connection"));
			assertFalse("uid should not exists", columns.contains("uid"));
		}
		
		public function testGetSchema():void {
			fail("No test implemented");
		}
		
		public function testGetFields():void {
			fail("No test implemented");
		}
		
		
	}
}