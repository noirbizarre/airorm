package info.noirbizarre.airorm.testUtils
{
	import org.flexunit.asserts.*;
	import flash.data.SQLConnection;
	import flash.data.SQLSchemaResult;
	import flash.data.SQLStatement;
	import flash.filesystem.File;
	import flash.system.Capabilities;
	
	import info.noirbizarre.airorm.AOError;
	import info.noirbizarre.airorm.utils.DB;
	
	public class DBTest
	{	
		private var dbFile:File;
		
		[Before]
		protected function init():void {
			dbFile = File.createTempFile();
		}
		
		[After]
		protected function cleanup():void {
			 if (Capabilities.os.substr(0, 3).toLowerCase() != "win") {
			 	// Crash on windows
				dbFile.deleteFile();
			 }
		} 
		
		[Test]
		public function getConnection():void {
			DB.registerConnectionAlias(dbFile,"other");
			assertEquals("Second call should returns the cached connection",DB.getConnection("other", true), DB.getConnection("other", true));
		}
		
		[Test]
		public function registerConnectionAlias():void {
			DB.registerConnectionAlias(dbFile,"other");
			assertNotNull("New alias should be registered", DB.getConnection("other",true));
			assertEquals("Second call should returns the cached connection",DB.getConnection("other",true),DB.getConnection("other",true));
			DB.getConnection("other").close();
		}
		
		[Test]
		public function getSchema():void {
			var conn:SQLConnection = new SQLConnection();
			conn.open(dbFile);
			assertNull("Schema for empty database is null", DB.getSchema(conn));
			var stmt:SQLStatement = new SQLStatement();
			stmt.sqlConnection = conn;
			stmt.text = "create table test('COL1' VARCHAR, 'COL2' NUMBER, 'COL3' BOOLEAN)";
			stmt.execute();
			assertNotNull("", DB.getSchema(conn));
			conn.close();
			var errorThrown:Boolean = false;
			try {
				DB.getSchema(new SQLConnection());
			} catch(e:AOError) {
				errorThrown = true;
			}
			assertTrue("Should have failed",errorThrown);
		}
		
		[Test]
		public function getTableSchema():void {
			var conn:SQLConnection = new SQLConnection();
			conn.open(dbFile);
			assertNull("Schema for non existant table is null", DB.getTableSchema(conn, "test"));
			var stmt:SQLStatement = new SQLStatement();
			stmt.sqlConnection = conn;
			stmt.text = "create table test('col1' VARCHAR, 'col2' NUMBER, 'col3' BOOLEAN)";
			stmt.execute();
			assertNotNull("", DB.getTableSchema(conn, "test"));
			conn.close();
		}
		
		[test]
		public function refreshSchema():void {
			DB.registerConnectionAlias(dbFile,"other");
			var conn:SQLConnection = DB.getConnection("other", true);
			var schema:SQLSchemaResult = DB.getSchema(conn);
			assertNull("DB should be empty",schema);
			
			var stmt:SQLStatement = new SQLStatement();
			stmt.sqlConnection = conn;
			stmt.text = "create table test('col1' VARCHAR, 'col2' NUMBER, 'col3' BOOLEAN)";
			stmt.execute();
			
			schema = DB.refreshSchema(conn); 
			assertNotNull("Refresh schema should reload the cached connection", schema.tables);
			DB.getConnection("other", true).close();
			
			// Error test: connection not found
			var errorThrown:Boolean = false;
			try {
				DB.refreshSchema(new SQLConnection());
			} catch(e:AOError) {
				errorThrown = true;
			}
			assertTrue("Should have failed",errorThrown);
		}
		
		[Test]
		public function reopenConnection():void {
			DB.registerConnectionAlias(dbFile,"other");
			var conn:SQLConnection = DB.getConnection("other", true);
			conn.close();
			assertFalse("Connection should be closed", conn.connected);
			DB.reopenConnection(conn);
			assertTrue("Connection should be open", conn.connected);
		}
		
	}
}