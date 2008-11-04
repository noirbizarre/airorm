package info.noirbizarre.airorm.testMain
{
	import flash.data.SQLColumnSchema;
	import flash.data.SQLConnection;
	import flash.data.SQLTableSchema;
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

	public class ORMTest extends TestCase
	{	
		private var dbFile:File;
		private var conn:SQLConnection;
		
		override protected function setUp():void {
			dbFile = File.createTempFile();
			DB.registerConnectionAlias(dbFile,"main");
			conn = DB.getConnection("main", true);
		}
		
		override protected function tearDown():void {
			DB.clear(conn);
			conn.close();
			dbFile.deleteFile();
		}
		
		public function testUpdateTableSimple():void {
			var obj:SimpleActiveRecord = new SimpleActiveRecord()
			ORM.updateTable(obj);
			var table:SQLTableSchema = DB.getTableSchema(conn,"SimpleActiveRecords");
			assertNotNull("Table should exists",table);
			assertEquals("Table should be correctly named","SimpleActiveRecords", table.name);
			var columns:ArrayCollection = new ArrayCollection();
			var types:Object = {};
			for each (var col:SQLColumnSchema in table.columns) {
				columns.addItem(col.name);
				types[col.name] = col.dataType;
				if (col.name == "id")
					assertTrue("id should be primary key",col.primaryKey);
			}
			
			assertTrue("id column should exists", columns.contains("id"));
			assertTrue("myString column should exists", columns.contains("myString"));
			assertTrue("myBool column should exists", columns.contains("myBool"));
			assertTrue("myInt column should exists", columns.contains("myInt"));
			assertTrue("myDate column should exists", columns.contains("myDate"));
			assertTrue("modified column should exists", columns.contains("modified"));
			assertTrue("created column should exists", columns.contains("created"));
			assertFalse("notPersisted should not exists", columns.contains("notPersisted"));
			
			assertEquals("id column should be INTEGER","INTEGER", types["id"]);
			assertEquals("myString column should be VARCHAR","VARCHAR", types["myString"]);
			assertEquals("myBool column should be BOOLEAN","BOOLEAN", types["myBool"]);
			assertEquals("myInt column should be INTEGER","INTEGER", types["myInt"]);
			assertEquals("myDate column should be DATETIME","DATETIME", types["myDate"]);
			assertEquals("modified column should be DATETIME","DATETIME", types["modified"]);
			assertEquals("created column should be DATETIME","DATETIME", types["created"]);
		}
		
		public function testUpdateTableSimpleByClass():void {
			ORM.updateTable(SimpleActiveRecord);
			var table:SQLTableSchema = DB.getTableSchema(conn,"SimpleActiveRecords");
			assertNotNull("Table should exists",table);
			assertEquals("Table should be correctly named","SimpleActiveRecords", table.name);
			var columns:ArrayCollection = new ArrayCollection();
			var types:Object = {};
			for each (var col:SQLColumnSchema in table.columns) {
				columns.addItem(col.name);
				types[col.name] = col.dataType;
				if (col.name == "id")
					assertTrue("id should be primary key",col.primaryKey);
			}
			
			assertTrue("id column should exists", columns.contains("id"));
			assertTrue("myString column should exists", columns.contains("myString"));
			assertTrue("myBool column should exists", columns.contains("myBool"));
			assertTrue("myInt column should exists", columns.contains("myInt"));
			assertTrue("myDate column should exists", columns.contains("myDate"));
			assertTrue("modified column should exists", columns.contains("modified"));
			assertTrue("created column should exists", columns.contains("created"));
			assertFalse("notPersisted should not exists", columns.contains("notPersisted"));
			
			assertEquals("id column should be INTEGER","INTEGER", types["id"]);
			assertEquals("myString column should be VARCHAR","VARCHAR", types["myString"]);
			assertEquals("myBool column should be BOOLEAN","BOOLEAN", types["myBool"]);
			assertEquals("myInt column should be INTEGER","INTEGER", types["myInt"]);
			assertEquals("myDate column should be DATETIME","DATETIME", types["myDate"]);
			assertEquals("modified column should be DATETIME","DATETIME", types["modified"]);
			assertEquals("created column should be DATETIME","DATETIME", types["created"]);
		}
		
		public function testUpdateTableHasMany():void {
			ORM.updateTable(Employer);
			var table:SQLTableSchema = DB.getTableSchema(conn,"Employers");
			assertNotNull("Table should exists",table);
			assertEquals("Table should be correctly named","Employers", table.name);
			var columns:ArrayCollection = new ArrayCollection();
			var types:Object = {};
			for each (var col:SQLColumnSchema in table.columns) {
				columns.addItem(col.name);
				types[col.name] = col.dataType;
				if (col.name == "id")
					assertTrue("id should be primary key",col.primaryKey);
			}
			
			assertTrue("id column should exists", columns.contains("id"));
			assertTrue("name column should exists", columns.contains("name"));
			assertFalse("employees column should not exists", columns.contains("employees"));
			
			assertEquals("id column should be INTEGER","INTEGER", types["id"]);
			assertEquals("namecolumn should be VARCHAR","VARCHAR", types["name"]);
		}
		
		public function testUpdateTableBelongsTo():void {
			ORM.updateTable(Employee);
			var table:SQLTableSchema = DB.getTableSchema(conn,"Employees");
			assertEquals("Table should be correctly named","Employees", table.name);
			var columns:ArrayCollection = new ArrayCollection();
			var types:Object = {};
			for each (var col:SQLColumnSchema in table.columns) {
				columns.addItem(col.name);
				types[col.name] = col.dataType;
				if (col.name == "id")
					assertTrue("id should be primary key",col.primaryKey);
			}
			
			assertTrue("id column should exists", columns.contains("id"));
			assertTrue("name column should exists", columns.contains("name"));
			assertTrue("position column should exists", columns.contains("position"));
			assertTrue("salary column should exists", columns.contains("salary"));
			assertTrue("hideDate column should exists", columns.contains("hireDate"));
			assertTrue("employer_id column should exists", columns.contains("employer_id"));
			assertFalse("employer column should not exists", columns.contains("employer"));
			
			assertEquals("id column should be INTEGER","INTEGER", types["id"]);
			assertEquals("employer_id column should be INTEGER","INTEGER", types["employer_id"]);
		}
		
		public function testUpdateTableOneToOne():void {
			ORM.updateTable(Secretary);
			var table:SQLTableSchema = DB.getTableSchema(conn,"Secretaries");
			assertEquals("Table should be correctly named","Secretaries", table.name);
			var columns:ArrayCollection = new ArrayCollection();
			var types:Object = {};
			for each (var col:SQLColumnSchema in table.columns) {
				columns.addItem(col.name);
				types[col.name] = col.dataType;
				if (col.name == "id")
					assertTrue("id should be primary key",col.primaryKey);
			}
			
			assertTrue("id column should exists", columns.contains("id"));
			assertTrue("name column should exists", columns.contains("name"));
			assertTrue("employer_id column should exists", columns.contains("employer_id"));
			assertFalse("employer column should not exists", columns.contains("employer"));
			
			assertEquals("id column should be INTEGER","INTEGER", types["id"]);
			assertEquals("employer_id column should be INTEGER","INTEGER", types["employer_id"]);
		}
		
		public function testUpdateTableManyToMany():void {
			ORM.updateTable(Employee);
			var table:SQLTableSchema = DB.getTableSchema(conn,"Employees");
			var joinTable:SQLTableSchema = DB.getTableSchema(conn,"Task_employees__Employee_tasks");
			if (!joinTable)
				joinTable = DB.getTableSchema(conn,"Employee_tasks__Task_employees");
			assertNotNull("Join table should exists", joinTable);
			var columns:ArrayCollection = new ArrayCollection();
			var types:Object = {};
			for each (var col:SQLColumnSchema in joinTable.columns) {
				columns.addItem(col.name);
				types[col.name] = col.dataType;
			}
			
			assertTrue("task_id column should exists", columns.contains("task_id"));
			assertTrue("employee_id column should exists", columns.contains("employee_id"));
			assertEquals("task_id column should be INTEGER","INTEGER", types["task_id"]);
			assertEquals("employee_id column should be INTEGER","INTEGER", types["employee_id"]);
		}
		
		public function testUpdateSchema():void {
			ORM.registerClass(Employee);
			ORM.registerClass(Employer);
			ORM.registerClass(Secretary);
			ORM.registerClass(Task);
			ORM.registerClass(SimpleActiveRecord);
			ORM.updateDB();
			var conn:SQLConnection = DB.getConnection("main",true);
			assertNotNull("Table Employees should exists", DB.getTableSchema(conn, "Employees"));
			assertNotNull("Table Employers should exists", DB.getTableSchema(conn, "Employers"));
			assertNotNull("Table Secretaries should exists", DB.getTableSchema(conn, "Secretaries"));
			assertNotNull("Table Tasks should exists", DB.getTableSchema(conn, "Tasks"));
			assertNotNull("Table SimpleActiveRecords should exists", DB.getTableSchema(conn, "SimpleActiveRecords"));
			var joinTable:SQLTableSchema = DB.getTableSchema(conn,"Task_employees__Employee_tasks");
			if (!joinTable)
				joinTable = DB.getTableSchema(conn,"Employee_tasks__Task_employees");
			assertNotNull("Join table should exists", joinTable);
		}
		
	}
}