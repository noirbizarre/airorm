package info.noirbizarre.airorm
{
	import flash.data.SQLColumnSchema;
	import flash.data.SQLConnection;
	import flash.data.SQLResult;
	import flash.data.SQLSchemaResult;
	import flash.data.SQLStatement;
	import flash.data.SQLTableSchema;
	import flash.events.Event;
	import flash.events.EventDispatcher;
	import flash.events.IEventDispatcher;
	import flash.events.SQLErrorEvent;
	import flash.events.SQLEvent;
	import flash.utils.Proxy;
	import flash.utils.flash_proxy;
	import flash.utils.getDefinitionByName;
	import flash.utils.getQualifiedClassName;
	
	import info.noirbizarre.airorm.utils.DB;
	import info.noirbizarre.airorm.utils.Inflector;
	import info.noirbizarre.airorm.utils.Reflection;
	import info.noirbizarre.airorm.utils.sql_db;
	
	import mx.core.IUID;
	import mx.utils.UIDUtil;
	
	use namespace sql_db;
	use namespace flash_proxy;
	
	public class ActiveRecord extends Proxy implements IEventDispatcher, IUID
	{
		sql_db static var tableSchemaCache:Object = {};
		sql_db static var columnSchemaCache:Object = {};
		
		/**
		 * Stores the runtime properties of related objects and arrays
		 */
		protected var relatedData:Object = {};
		
		/**
		 * The default SQLConnection alias used for this stored object 
		 */
		public static var defaultConnectionAlias:String = "main";
		
		/**
		 * The default object that can translate class names, properties, and keys for the database
		 */
		public static var schemaTranslation:SchemaTranslation = new SchemaTranslation();
		
		/**
		 * Stores the constructor of this class since it is not available to Proxied objects
		 */
		public var constructor:Object;
		
		/**
		 * This object's SQLConnection object, retrieved upon instantiation
		 */
		[NotPersisted]
		//public var connection:SQLConnection;
		public function get connection():SQLConnection { return DB.getConnection(defaultConnectionAlias, true); }
		public function set connection(value:SQLConnection):void { /* Read-only */ }
		
		/**
		 * Needed to implement IUID
		 */
		[NotPersisted]
		public function get uid():String {
			if (!id) {
				if (!_uid) {
					_uid = UIDUtil.createUID();
				}
				return _uid
			} else {
				return className +"_"+ id.toString();
			}
		}
		public function set uid(value:String):void { /* Read-only */ }
		private var _uid:String;
		
		/**
		 * Stores the properties name
		 */
		private var properties:Array;
		
		private var _className:String;
		private var eventDispatcher:EventDispatcher;
		
		[Bindable]
		public var id:uint;
		
		
		public function ActiveRecord()
		{
			constructor = getDefinitionByName(getQualifiedClassName(this));
			eventDispatcher = new EventDispatcher(this);
		}
		
		/**
		 * Loads the object from the database by the id passed
		 *
		 * @param The database id or primary key value
		 * @return Whether the object was successfully loaded
		 */
		public function load(id:uint):Boolean
		{
			var tableName:String = schemaTranslation.getTable(className);
			var primaryKey:String = schemaTranslation.getPrimaryKey(className);
			var stmt:SQLStatement = new SQLStatement();
			var result:Array = query("SELECT * FROM " + tableName + " WHERE " + primaryKey + " = ?", id) as Array;
			
			if (!result.length)
				return false;
			
			setDBProperties(result[0]);
			return true;
		}
		
		/**
		 * Loads the object from the database by the conditions passed
		 *
		 * @param Conditions to be passed
		 * @param The parameter replacements to replace the ?s
		 * @return Whether the object was succesfully loaded
		 */
		public function loadBy(conditions:String, ...parameters:Array):Boolean
		{
			var tableName:String = schemaTranslation.getTable(className);
			var result:Array = query("SELECT * FROM " + tableName + " WHERE " + conditions, parameters) as Array;
			
			if (!result.length)
				return false;
			
			setDBProperties(result[0]);
			return true;
		}
		
		/**
		 * Saves the object to the database.
		 * 
		 * @return Whether the object successfully saved
		 */
		public function save():Boolean
		{
			// dispatch the saving event and allow for the save to be canceled
			var savingEvent:ActiveRecordEvent = new ActiveRecordEvent(ActiveRecordEvent.SAVING, true);
			dispatchEvent(savingEvent);
			
			if (savingEvent.isDefaultPrevented())
				return false;
			
			// add timestamps if certain "created" and/or "modified" fields are defined
			if (!id && hasOwnProperty(schemaTranslation.getCreatedField(this)))
				this[schemaTranslation.getCreatedField(this)] = new Date();
			
			if (hasOwnProperty(schemaTranslation.getModifiedField(this)))
				this[schemaTranslation.getModifiedField(this)] = new Date();
			
			// set up the variables to save this object to the database
			var tableName:String = schemaTranslation.getTable(className);
			var primaryKey:String = schemaTranslation.getPrimaryKey(className);
			var parameters:Array = [];
			var sql:String;
			
			var data:Object = getDBProperties();
			delete data[primaryKey];
			var fields:Array = [];
			for (var fieldName:String in data)
			{
				fields.push(fieldName);
				parameters.push(data[fieldName]);
			}
			
			if (id) // this is an update statement
			{
				sql = "UPDATE " + tableName + " SET " + fields.join(" = ?, ") + " = ? WHERE " + primaryKey + " = ?";
				parameters.push(id);
			}
			else
			{
				sql = "INSERT INTO " + tableName + " (" + fields.join(", ") + ") VALUES (?";
				for (var j:uint = 0; j < fields.length - 1; j++)
					sql += ", ?";
				sql += ")";
			}
			
			var result:Object = query(sql, parameters);
			
			if (!result)
				return false;
			
			if (!id)
				id = connection.lastInsertRowID;
			
			// dispatch the save event
			var saveEvent:ActiveRecordEvent = new ActiveRecordEvent(ActiveRecordEvent.SAVE);
			dispatchEvent(saveEvent);
			
			return true;
		}
		
		//////////// These are ideally static methods that would work with a subclass, however, since we
		//////////// cannot get the class of the item calling these methods statically we must make
		//////////// them not static.
		
		 /**
		 * Return object found based on id
		 * 
		 * @param The id of the object in the database
		 */
		public function find(id:uint):ActiveRecord
		{
			var primaryKey:String = schemaTranslation.getPrimaryKey(className);
			var result:Array = findAll(primaryKey + " = ?", [id]);
			return result ? result[0] : null;
		}
		
		/**
		 * Returns first object found based on parameters
		 */
		 public function findFirst(conditions:String = null, conditionParams:Array = null, order:String = null):ActiveRecord
		 {
		 	var result:Array = findAll(conditions, conditionParams, order, 1);
			return result ? result[0] : null;
		 }
		
		/**
		 * Returns array of objects based on parameters
		 */
		public function findAll(conditions:String = null, conditionParams:Array = null, order:String = null, limit:uint = 0, offset:uint = 0, joins:String = null):Array
		{
			var tableName:String = schemaTranslation.getTable(className);
			var primaryKey:String = schemaTranslation.getPrimaryKey(className);
			
			var sql:String = "SELECT *, " + tableName + "." + primaryKey + " FROM " + tableName;
			sql += assembleQuery(conditions, order, limit, offset, joins);
			
			var items:Array = loadItems(constructor as Class, sql, conditionParams);
			return (items == null ? [] : items);
		}
		
		/**
		 * Returns array of objects based on the full sql statement
		 */
		public function findBySQL(sql:String, ...params:Array):Array
		{
			return loadItems(constructor as Class, sql, params);
		}
		
				/**
		 * Returns array of objects based on the full sql statement
		 * without parameters
		 */
		public function findBySQLWithoutParams(sql:String):Array
		{
			return loadItemsWithoutParams(constructor as Class, sql);
		}
		
		/**
		 * Returns whether or not the object exists in the database
		 */
		public function exists(id:uint):Boolean
		{
			var primaryKey:String = schemaTranslation.getPrimaryKey(className);
			return (count(primaryKey + " = ?", [id]) > 0);
		}
		
		/**
		 * Creates new object, populates the attributes from the array, 
		 * saves it if it validates, and returns it
		 */
		public function create(properties:Object = null):ActiveRecord
		{
			var obj:ActiveRecord = new constructor();
			obj.setDBProperties(properties);
			obj.save();
			return obj;
		}
		
		/**
		 * Updates an object already stored in the database with the properties passed
		 * @return Whether it was successfully updated
		 */
		public function update(id:uint, updates:String, updateParams:Array = null):Boolean
		{
			var tableName:String = schemaTranslation.getTable(className);
			var primaryKey:String = schemaTranslation.getPrimaryKey(className);
			
			if (!updateParams)
				updateParams = [id];
			else
				updateParams.push(id);
			
			return query("UPDATE " + tableName + " SET " + updates + " WHERE " + primaryKey + " = ?", updateParams) as uint > 0;
		}
		
		/**
		 * Updates all records' properties matching conditions
		 * @return Number of successful updates
		 */
		public function updateAll(conditions:String = null, conditionParams:Array = null, updates:String = null, updateParams:Array = null):uint
		{
			var tableName:String = schemaTranslation.getTable(className);
			
			var params:Array = conditionParams ?
					(
						updateParams ? conditionParams.concat(updateParams) : conditionParams
					)
				: updateParams;
			
			return query("UPDATE " + tableName + " SET " + updates, params) as uint;
		}
		
		/**
		 * Delete object by id
		 * 
		 * @param The id of the object in the database
		 * @return Whether object was deleted
		 */
		public function deleteById(id:uint):Boolean
		{
			var tableName:String = schemaTranslation.getTable(className);
			var primaryKey:String = schemaTranslation.getPrimaryKey(className);
			return query("DELETE FROM " + tableName + " WHERE " + primaryKey + " = ?", id) > 0;
		}
		
		/**
		 * Deletes all records by conditions
		 * 
		 * @return Number of successful deletes
		 */
		public function deleteAll(conditions:String = null, conditionParams:Array = null):uint
		{
			var tableName:String = schemaTranslation.getTable(className);
			
			var sql:String = "DELETE FROM " + tableName;
			sql += assembleQuery(conditions);
			return query(sql, conditionParams) as uint;
		}
		
		/**
		 * Returns the number of records that meet the conditions
		 */
		public function count(conditions:String = null, conditionParams:Array = null, joins:String = null):uint
		{
			var tableName:String = schemaTranslation.getTable(className);
			var sql:String = "SELECT COUNT(*) FROM " + tableName;
			sql += assembleQuery(conditions, null, 0, 0, joins);
			var result:Array; 
			if (conditionParams) {
				result = query(sql, conditionParams) as Array;
			} else {
				result = query(sql) as Array;
			}
			return result ? result[0]["COUNT(*)"] : 0;
		}
		
		/**
		 * Returns the number of records returned by the sql statement
		 */
		public function countBySql(sql:String, params:Array = null):uint
		{
			var result:Array = query(sql, params) as Array;
			return result ? result[0][0] : 0;
		}
		
		/**
		 * Increment a property in the database
		 * 
		 * @param The id of the class to be incremented
		 * @param The property of the class to be incremented
		 */
		public function incrementCounter(id:uint, counter:String):void
		{
			update(id, counter + " = " + counter + " + 1");
		}
		
		/**
		 * Decrements a counter in a record
		 * 
		 * @param The id of the class to be incremented
		 * @param The property of the class to be decremented
		 */
		public function decrementCounter(id:uint, counter:String):void
		{
			update(id, counter + " = " + counter + " - 1");
		}
		
		
		flash_proxy override function getProperty(name:*):*
		{
			name = name.toString();
			
			if (name == "className")
				return className;
			
			var relation:XML = Reflection.getMetadataByArg(this, "", name)[0];
			
			if (!relation || name in relatedData)
				return relatedData[name];
			
			relatedData[name] = loadRelated(name);
			return relatedData[name];
		}
		
		flash_proxy override function setProperty(name:*, value:*):void
		{
			name = name.toString();
			
			relatedData[name] = value;
		}
		
		flash_proxy override function hasProperty(name:*):Boolean
		{
			name = name.toString();
			
			var relation:XML = Reflection.getMetadataByArg(this, "", name)[0];
			
			return relation != null;
		}
		
		
		flash_proxy override function callProperty(name:*, ...params:Array):*
		{
			var matches:Array = name.toString().match(/^([a-z]+)(.+)/);
			var prop:QName = new QName(sql_db, matches[1] + "Related");
			if (!matches || !(this[prop] is Function) )
				return;
			
			var relationalMethod:Function = this[prop];
			var propertyName:String = Inflector.lowerFirst(matches[2]);
			var relation:XML = Reflection.getMetadataByArg(this, "", propertyName)[0];
			
			if (!relation)
				return;
			
			params.unshift(propertyName);
			
			if (relationalMethod == loadRelated)
				return relatedData[name] = relationalMethod.apply(this, params);
			else
				return relationalMethod.apply(this, params);
		}
		
		/*
	     override flash_proxy function nextNameIndex (index:int):int {
	         // initial call
	         if (index == 0) {
	             properties = new Array();
	             var relations:XMLList = Reflection.getMetadata(this, "RelatedTo");
	             for each(var x:XML in relations) {
	                properties.push(x.arg.(@key="name").@value);
	             }
	         }
	     
	         if (index < properties.length) {
	             return index + 1;
	         } else {
	             return 0;
	         }
	     }
	     
	     override flash_proxy function nextName(index:int):String {
	         return properties[index - 1];
	     }
	     
	     override flash_proxy function nextValue(index:int):* {
	     	return getProperty(properties[index - 1]);
	     }
	     */


		
		
		sql_db function loadRelated(name:String, conditions:String = null, conditionParams:Array = null, order:String = null, limit:uint = 0, offset:uint = 0):Object
		{
			var r:RelationalOperation = new RelationalOperation(this, name);
			return r.loadRelated(conditions, conditionParams, order, limit, offset);
		}
		
		sql_db function countRelated(name:String, conditions:String = null, conditionParams:Array = null):uint
		{
			var r:RelationalOperation = new RelationalOperation(this, name);
			return r.countRelated(conditions, conditionParams);
		}
		
		sql_db function saveRelated(name:String):Boolean
		{
			var r:RelationalOperation = new RelationalOperation(this, name);
			return r.saveRelated();
		}
		
		sql_db function deleteRelated(name:String, conditions:String = null, conditionParams:Array = null, joinOnly:Boolean = true):uint
		{
			var r:RelationalOperation = new RelationalOperation(this, name);
			return r.deleteRelated(conditions, conditionParams, joinOnly);
		}
		
		
		/**
		 * Gives the class name for this object without the package info
		 */
		sql_db function get className():String
		{
			if (!_className)
			{
				_className = Reflection.getShortClassName(this);
			}
			return _className;
		}
		
		sql_db function set className(value:String):void {
			// Read-Only
		}
		
		public function query(sql:String, ...params:Array):Object
		{
			var stmt:SQLStatement = new SQLStatement();
			stmt.sqlConnection = connection;
			stmt.text = sql;
			
			if (params.length == 1 && params[0] is Array)
				params = params[0];	
			
			if (params is Array) {
				for (var i:int = 0; i < params.length; i++)
					stmt.parameters[i] = params[i];	
			}
			
			stmt.execute();
			var result:SQLResult = stmt.getResult();
			
			return sql.toUpperCase().indexOf("SELECT ") == 0 ? result.data || [] : result.rowsAffected;
		}
		
		public function asyncQuery(sql:String, resultFunction:Function, ...params:Array):void
		{
			var stmt:SQLStatement = new SQLStatement();
			stmt.sqlConnection = DB.getConnection(defaultConnectionAlias);
			stmt.text = sql;
			
			if (params.length == 1 && params[0] is Array)
				params = params[0];
			
			for (var i:int = 0; i < params.length; i++)
				stmt.parameters[i] = params[i];
			
			var listener:Function = function(event:SQLEvent):void
			{
				var result:SQLResult = stmt.getResult();
				resultFunction(sql.toUpperCase().indexOf("SELECT ") == 0 ? result.data || [] : result.rowsAffected);
				stmt.removeEventListener(SQLEvent.RESULT, listener);
			};
			stmt.addEventListener(SQLEvent.RESULT, listener);
			stmt.execute();
		}
		
		sql_db function loadItems(clazz:Class, sql:String, ...params:Array):Array
		{
			var stmt:SQLStatement = new SQLStatement();
			stmt.sqlConnection = connection;
			stmt.text = sql;
			stmt.itemClass = clazz;
			
			if (params.length == 1 && params[0] is Array)
				params = params[0];
			
			for (var i:int = 0; i < params.length; i++)
				stmt.parameters[i] = params[i];
			
			stmt.execute();
			var result:SQLResult = stmt.getResult();
			
			return result ? result.data : null;
		}
		
		sql_db function loadItemsWithoutParams(clazz:Class, sql:String):Array
		{
			var stmt:SQLStatement = new SQLStatement();
			stmt.sqlConnection = connection;
			stmt.text = sql;
			stmt.itemClass = clazz;
			stmt.addEventListener(SQLErrorEvent.ERROR, queryErrorHandler);
			stmt.execute();
			var result:SQLResult = stmt.getResult();
			
			return result ? result.data : null;
		}
		
		private function queryErrorHandler(event:SQLErrorEvent):void { 
	        var err:String = "Query Error id: " + event.error.errorID + "\nDetails:" +
	                         event.error.message;           
	    }
	      
		sql_db function assembleQuery(conditions:String = null, order:String = null, limit:uint = 0, offset:uint = 0, joins:String = null):String
		{
			var sql:String = "";
			
			if (joins)
				sql += joins;
			
			if (conditions)
				sql += " WHERE " + conditions;
			
			if (limit)
			{
				sql += " LIMIT " + limit;
				if (offset)
					sql += " OFFSET " + offset;
			}
			
			return sql;
		}
		
		sql_db function setDBProperties(data:Object):void
		{
			var columns:Array = getSchema().columns;
			
			for each (var column:SQLColumnSchema in columns)
			{
				if (column.primaryKey)
				{
					if (column.name in data)
						id = data[column.name];
				}
				else if (column.name in data)
				{
					this[column.name] = data[column.name];
				}
			}
		}
		
		sql_db function getDBProperties():Object
		{
			var tableName:String = schemaTranslation.getTable(className);
			var columns:Array = getSchema().columns;
			
			var data:Object = {};
			
			// Build dynamicly generated foreign keys array 
			var foreignKeys:XMLList = Reflection.getMetadata(this, "BelongsTo") + Reflection.getMetadata(this, "HasOne");
			var dynamics:Object = {};
			for each (var fkDef:XML in foreignKeys) {
				var otherClassName:String = fkDef.arg.(@key=="className")[0].@value;
				var propName:String = fkDef.arg.(@key=="")[0].@value;
				var fk:String = ActiveRecord.schemaTranslation.getForeignKey(otherClassName, propName);
				dynamics[fk] = propName;
			}
			
			for each (var column:SQLColumnSchema in columns)
			{
				if (column.primaryKey)
					data[column.name] = id;
				else if (column.name in this)
					data[column.name] = this[column.name];
				else if (column.name in dynamics) {
					var ar:ActiveRecord = getProperty(dynamics[column.name]);
					if (ar)
						data[column.name] = ar.id;
					else
						data[column.name] = null;
				}
			}
			
			return data;
		}
		
		/**
		 * Creates a new table for this object if one does not already exist. In addition, will
		 * add new fields to existing tables if an object has changed
		 */
		sql_db function getSchema(tableName:String = null, updateTable:Boolean = false):SQLTableSchema
		{
			if (!tableName)
				tableName = schemaTranslation.getTable(className);
			
			if (tableName in tableSchemaCache)
				return tableSchemaCache[tableName];
			
			var schema:SQLSchemaResult = DB.getSchema(connection);
			
			var table:SQLTableSchema;
			
			// first, find the table this object represents
			if (schema)
			{
				for each (var tmpTable:SQLTableSchema in schema.tables)
				{
					if (tmpTable.name == tableName)
					{
						table = tmpTable;
						break;
					}
				}
			}
			
			if (updateTable)
				ORM.updateTable(this, table);
			
			var fields:Object;
			
			if (table && table.columns.length)
			{
				fields = {};
				for each (var column:SQLColumnSchema in table.columns)
					fields[column.name] = column;
			}
			
			columnSchemaCache[tableName] = fields;
			tableSchemaCache[tableName] = table;
			
			return table;
		}
		
		sql_db function getFields(tableName:String = null):Object
		{
			if (!tableName)
				tableName = schemaTranslation.getTable(className);
			
			if (!(tableName in columnSchemaCache))
				getSchema(tableName);
			
			return columnSchemaCache[tableName];
		}
		
		
		/** EVENT DISPATCHER STUFF **/
		
		public function hasEventListener(type:String):Boolean
		{
			return eventDispatcher.hasEventListener(type);
		}
		
		public function willTrigger(type:String):Boolean
		{
			return eventDispatcher.willTrigger(type);
		}
		
		public function addEventListener(type:String, listener:Function, useCapture:Boolean=false, priority:int=0.0, useWeakReference:Boolean=false):void
		{
			eventDispatcher.addEventListener(type, listener, useCapture, priority, useWeakReference);
		}
		
		public function removeEventListener(type:String, listener:Function, useCapture:Boolean=false):void
		{
			eventDispatcher.removeEventListener(type, listener, useCapture);
		}
		
		public function dispatchEvent(event:Event):Boolean
		{
			return eventDispatcher.dispatchEvent(event);
		}
	}
}