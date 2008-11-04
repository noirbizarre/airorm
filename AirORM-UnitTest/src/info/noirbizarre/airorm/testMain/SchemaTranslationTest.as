package info.noirbizarre.airorm.testMain
{
	import net.digitalprimates.fluint.tests.TestCase;
	
	import info.noirbizarre.airorm.AOError;
	import info.noirbizarre.airorm.SchemaTranslation;
	import info.noirbizarre.airorm.testData.Employee;
	import info.noirbizarre.airorm.testData.SimpleActiveRecord;
	import info.noirbizarre.airorm.testData.SimpleClass;
	import info.noirbizarre.airorm.testData.Task;

	public class SchemaTranslationTest extends TestCase
	{
		private static var st:SchemaTranslation = new SchemaTranslation();
		
		public function testGetTable():void {
			var simpleAR:SimpleActiveRecord = new SimpleActiveRecord();
			assertEquals("Table name should be the plural form of class name","SimpleActiveRecords",st.getTable(simpleAR.className));
			assertEquals("Table name should be the plural form of class name","SimpleActiveRecords",st.getTable(simpleAR));
			assertEquals("Table name should be the plural form of class name","SimpleActiveRecords",st.getTable(SimpleActiveRecord));
			var errorThrown:Boolean = false;
			try {
				st.getTable(new SimpleClass());
			} catch(e:AOError) {
				errorThrown = true;
			}
			assertTrue("Should have failed",errorThrown);
		}
		
		public function testGetPrimaryKey():void {
			var simpleAR:SimpleActiveRecord = new SimpleActiveRecord();
			assertEquals("Default primary key should be 'id'","id",st.getPrimaryKey(simpleAR.className));
			assertEquals("Default primary key should be 'id'","id",st.getPrimaryKey(simpleAR));
			assertEquals("Default primary key should be 'id'","id",st.getPrimaryKey(SimpleActiveRecord));
		}
		
		public function testGetForeignKey():void {
			var simpleAR:SimpleActiveRecord = new SimpleActiveRecord();
			var emp:Employee = new Employee();
			assertEquals("Default foreign key should be 'simpleActiveRecord_id'","simpleActiveRecord_id",st.getForeignKey(simpleAR));
			assertEquals("Default foreign key should be 'simpleActiveRecord_id'","simpleActiveRecord_id",st.getForeignKey(simpleAR.className));
			assertEquals("Default foreign key should be 'simpleActiveRecord_id'","simpleActiveRecord_id",st.getForeignKey(SimpleActiveRecord));
			assertEquals("property foreign key should be 'employer_id'","employer_id",st.getForeignKey(emp,"employer"));
			assertEquals("property foreign key should be 'employer_id'","employer_id",st.getForeignKey(emp.className,"employer"));
			assertEquals("property foreign key should be 'employer_id'","employer_id",st.getForeignKey(Employee,"employer"));
			var errorThrown:Boolean = false;
			try {
				st.getForeignKey(new SimpleClass());
			} catch(e:AOError) {
				errorThrown = true;
			}
			assertTrue("Should have failed",errorThrown);
		}
		
		public function testGetJoinTable():void {
			var task:Task = new Task();
			var employee:Employee = new Employee();
			assertEquals("should match the class1_prop1__class2_prop2","Employee_tasks__Task_employees", st.getJoinTable(Employee, "tasks", Task, "employees"));
			assertEquals("should match the class1_prop1__class2_prop2","Employee_tasks__Task_employees", st.getJoinTable(employee, "tasks", task, "employees"));
			assertEquals("should match the class1_prop1__class2_prop2","Employee_tasks__Task_employees", st.getJoinTable("Employee", 'tasks', "Task", "employees"));
		}
		
		public function testGetField():void {
			assertEquals("Should returns the property name","myPropertie",st.getField("myPropertie"));
		}
		
		public function testGetCreatedField():void {
			var simpleAR:SimpleActiveRecord = new SimpleActiveRecord();
			var employee:Employee = new Employee();
			assertEquals("Should be 'created'","created",st.getCreatedField(simpleAR));
			assertNull("Should not have 'created' field",st.getCreatedField(employee));
		}
		
		public function testGetModifiedField():void {
			var simpleAR:SimpleActiveRecord = new SimpleActiveRecord();
			var employee:Employee = new Employee();
			assertEquals("Should be 'modified'","modified",st.getModifiedField(simpleAR));
			assertNull("Should not have 'modified' field",st.getModifiedField(employee));
		}
		
	}
}