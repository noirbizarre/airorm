package info.noirbizarre.airorm.utils
{
	import flash.data.SQLConnection;
	import flash.data.SQLSchemaResult;
	import flash.data.SQLTableSchema;
	import flash.errors.SQLError;
	import flash.filesystem.File;
	import flash.utils.Dictionary;
	
	import info.noirbizarre.airorm.AOError;
	
	public class DB
	{
		protected static var schemas:Dictionary = new Dictionary();
		protected static var aliases:Object = {};
		protected static var cache:Object = {};
		
		/**
		 * Returns a connection by the registered alias and with the appropriate synchronisation. This provides
		 * a cache for the connection objects to be used. The main.db database is preregistered under the alias
		 * "main", so a call to getConnection with no parameters will return the default application database.
		 */
		public static function getConnection(alias:String = "main", isSync:Boolean = false):SQLConnection
		{
			var conn:SQLConnection;
			var key:String = alias + " - " + (isSync ? "sync" : "async");
			
			if (key in cache) {
				conn = cache[key];
				if (!conn.connected) {
					reopenConnection(conn);
				}
				return conn;
			}
			
			if ( !(alias in aliases))
				return null;
			
			var file:File = aliases[alias] is File ? aliases[alias] as File : File.applicationStorageDirectory.resolvePath(aliases[alias]);
			conn = new SQLConnection();
			if (isSync)
				conn.open(file);
			else
				conn.openAsync(file);
			
			cache[key] = conn;
			
			return conn;
		}
		
		/**
		 * Registers a database file with an alias for the database. This allows connection objects
		 * to be created, retrieved, and cached by the getConnection method.
		 */
		public static function registerConnectionAlias(fileNameOrObject:Object, alias:String):void
		{
			aliases[alias] = fileNameOrObject is File ? fileNameOrObject.nativePath : fileNameOrObject;
		}
		
		// this private method pre-registers the main database to the system
		private static var init:* = function():void {
			registerConnectionAlias("main.db", "main");
		}();
		
		/**
		 * Returns and caches the schema for a connection to a database
		 */
		public static function getSchema(conn:SQLConnection):SQLSchemaResult
		{
			if (!conn.connected) {
				try {
					reopenConnection(conn);
				} catch (e:AOError) {
					throw new AOError("Connection should be opened");
				}
			}
			if ( !(conn in schemas))
			{	
				try {
					conn.loadSchema();
				} catch (e:SQLError) {
					return null
				}
				schemas[conn] = conn.getSchemaResult();
			}
			
			return schemas[conn];
		}
		
		/**
		 * Returns, if exists,  the table schema for a connection to a database.
		 */
		public static function getTableSchema(conn:SQLConnection, name:String):SQLTableSchema {
			var dbschema:SQLSchemaResult = getSchema(conn);
				
			// first, find the table this object represents
			if (dbschema)
			{
				for each (var tmpTable:SQLTableSchema in dbschema.tables)
				{
					if (tmpTable.name == name)
					{
						return tmpTable;
					}
				}
			}
			
			return null;
		}
		
		/**
		 * Forces a refresh of a schema, used when a table update has been made or tables have been added
		 */
		public static function refreshSchema(conn:SQLConnection):SQLSchemaResult
		{
			delete schemas[conn];
			// Workaround for non reloading schema in Adobe AIR: close and reopen connection
			reopenConnection(conn);
			return getSchema(conn);
		}
		
		/**
		 * Reopen connection from file if it is not connected
		 */
		public static function reopenConnection(conn:SQLConnection, force:Boolean=false):void {
			if (conn.connected && force) {
				conn.close();
			}
			
			if (!conn.connected) {
				var alias:String = null;
				var isSync:Boolean = false;
				for (var key:String in cache) {
					if (cache[key] == conn) {
						var parts:Array = key.split(" - ");
						isSync = (parts.pop() == "sync");
						alias = parts.join(" - ");
						delete cache[key];
						break;
					}
				}
				if (!alias) {
					throw new AOError("Connection not found");
				}
				// Fetch corresponding file and reopen it
				var file:File = aliases[alias] is File ? aliases[alias] as File : File.applicationStorageDirectory.resolvePath(aliases[alias]);
				if (isSync)
					conn.open(file);
				else
					conn.openAsync(file);
			}
		}
		
		/**
		 * Remove metadatas associated with conn
		 */
		public static function clear(conn:SQLConnection):void {
			if (schemas[conn])
				delete schemas[conn];
		}
		
	}
}