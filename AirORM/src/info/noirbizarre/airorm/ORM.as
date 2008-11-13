package info.noirbizarre.airorm
{
	import flash.data.SQLColumnSchema;
	import flash.data.SQLConnection;
	import flash.data.SQLSchemaResult;
	import flash.data.SQLStatement;
	import flash.data.SQLTableSchema;
	import flash.net.registerClassAlias;
	import flash.utils.getDefinitionByName;
	import flash.utils.getQualifiedClassName;
	
	import info.noirbizarre.airorm.utils.DB;
	import info.noirbizarre.airorm.utils.Reflection;
	import info.noirbizarre.airorm.utils.sql_db;
	
	use namespace sql_db;
	
	
	public class ORM
	{
		private static var tablesUpdated:Object = {};
		private static var registeredClasses:Object = {};
		
		public static function registerClass(c:Class):void {
			if (!registeredClasses[getQualifiedClassName(c)]) {
				registerClassAlias(getQualifiedClassName(c), c);
				registerClassAlias(Reflection.getShortClassName(c), c);
				registeredClasses[getQualifiedClassName(c)] = c;
			}
		}
		
		public static function updateDB():void {
			for each (var c:Class in registeredClasses) {
				updateTable(c);
			}
		}
		
		/**
		 * Creates a new table for this object if one does not already exist. In addition, will
		 * add new fields to existing tables if an object has changed
		 */
		public static function updateTable(obj:Object, schema:SQLTableSchema = null):void
		{
			var conn:SQLConnection;
			if (obj is ActiveRecord) {
				conn = (obj as ActiveRecord).connection;
				registerClassAlias(getQualifiedClassName(obj), getDefinitionByName(getQualifiedClassName(obj)) as Class);
				registerClassAlias(obj.className, getDefinitionByName(getQualifiedClassName(obj)) as Class);
			} else if (obj is Class) {
				conn = DB.getConnection("main", true);
				registerClassAlias(getQualifiedClassName(obj), obj as Class);
				registerClassAlias(Reflection.getShortClassName(obj), obj as Class);
			}
			
			var tableName:String = ActiveRecord.schemaTranslation.getTable(obj);
			var primaryKey:String = ActiveRecord.schemaTranslation.getPrimaryKey(obj);
			
			var stmt:SQLStatement = new SQLStatement();
			stmt.sqlConnection = conn;
			var sql:String;
			
			// get all this object's properties we want to store in the database
			var def:XML = Reflection.describe(obj).copy();
		
			// Append generated foreign keys 
			var foreignKeys:XMLList = Reflection.getMetadata(obj, "BelongsTo") + Reflection.getMetadata(obj, "HasOne");
			for each (var fkDef:XML in foreignKeys) {
				var otherClassName:String = fkDef.arg.(@key=="className")[0].@value;
				var propName:String = fkDef.arg.(@key=="")[0].@value;
				var fk:XML = <variable type="uint" />;
				fk.@name = ActiveRecord.schemaTranslation.getForeignKey(otherClassName, propName);
				def.appendChild(fk);
			}
			
			var publicVars:XMLList = def.*.(
					(
						localName() == "variable" ||
						(localName() == "accessor" && @access == "readwrite")
					)
					&&
					(
						@type == "String" ||
						@type == "Number" ||
						@type == "Boolean" ||
						@type == "uint" ||
						@type == "int" ||
						@type == "Date" ||
						@type == "flash.utils.ByteArray"
					)
					&& !(
						hasOwnProperty("metadata")
						&& elements("metadata").(@name == "NotPersisted").length() > 0
					)
				);
			
			var field:XML;
			var fieldDef:Array
			var external:String;
			var column:SQLColumnSchema;
			
			if (!schema) {
				schema = DB.getTableSchema(conn, tableName);
			}
			
			conn.begin();
			
			// if no table was found, create it, otherwise, update any missing fields
			if (!schema)
			{
				var fields:Array = [];
				
				for each (field in publicVars)
				{
					fieldDef = [field.@name, dbTypes[field.@type]];
					
					if (field.@name == primaryKey)
						fieldDef.push("PRIMARY KEY AUTOINCREMENT");
					
					fields.push(fieldDef.join(" "));
				}
				
				sql = "CREATE TABLE " + tableName + " (" + fields.join(", ") + ")";
				stmt.text = sql;
				stmt.execute();
			} else {
			// check if any fields differ or have been added
				var found:Boolean;
				for each (field in publicVars) {
					found = false;
					for each (column in schema.columns) {
						if (column.name == field.@name) {
							found = true;
							break;
						}
					}
					
					if (found)
						continue;
					
					// add the field to be created
					fieldDef = ["ADD", field.@name, dbTypes[field.@type]];
					
					sql = "ALTER TABLE " + tableName + " " + fieldDef.join(" ");
					stmt.text = sql;
					stmt.execute();
				}
			}
				
			//Check join tables
			var joinVars:XMLList = Reflection.getMetadata(obj, "ManyToMany");
				
			for each (field in joinVars) {
				var dbschema:SQLSchemaResult = DB.getSchema(conn);
				var other:String = field.arg.(@key == "className").@value;
				var prop:String = field.arg.(@key=="").@value;
				var objFK:String = ActiveRecord.schemaTranslation.getForeignKey(obj);
				var otherFK:String = ActiveRecord.schemaTranslation.getForeignKey(other);
				var otherProp:String = field.arg.(@key == "property").@value; 
				tableName = ActiveRecord.schemaTranslation.getJoinTable(obj, prop, other, otherProp);
				sql = "CREATE TABLE IF NOT EXISTS " + tableName + " (" + objFK + " INTEGER, " + otherFK + " INTEGER, ";
				sql += "PRIMARY KEY (" + objFK + " , " + otherFK + "))";
				stmt.text = sql;
				stmt.execute();
			}
			
			if (conn.inTransaction)
				conn.commit();
			
			DB.refreshSchema(conn);
		}
		
		sql_db static var dbTypes:Object = {
			"String": "VARCHAR",
			"Number": "DOUBLE",
			"Boolean": "BOOLEAN",
			"uint": "INTEGER",
			"int": "INTEGER",
			"Date": "DATETIME",
			"flash.utils.ByteArray": "BLOB"
		};
	}
}