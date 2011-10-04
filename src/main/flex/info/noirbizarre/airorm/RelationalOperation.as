package info.noirbizarre.airorm
{
	import flash.data.SQLStatement;
	import flash.net.getClassByAlias;
	import flash.utils.getQualifiedClassName;
	
	import info.noirbizarre.airorm.utils.Reflection;
	import info.noirbizarre.airorm.utils.sql_db;
	
	use namespace sql_db;
	
	/**
	 * Build SQL operations for relational operations between ActiveRecords.
	 * Each ActiveRecord class need to be registered to ORM before (or using registerClassAlias() method)
	 */
	public class RelationalOperation
	{
		public static const BELONGS_TO:String = "BelongsTo";
		public static const HAS_ONE:String = "HasOne";
		public static const HAS_MANY:String = "HasMany";
		public static const MANY_TO_MANY:String = "ManyToMany";
		
		public var relationship:String = "";
		protected var thisObj:ActiveRecord;
		protected var thatObj:ActiveRecord;
		protected var thisProp:String;
		protected var thatProp:String;
		protected var thisClass:String;
		protected var thatClass:String;
		protected var thisTable:String;
		protected var thatTable:String;
		protected var thisPrimaryKey:String;
		protected var thatPrimaryKey:String;
		protected var thisForeignKey:String;
		protected var thatForeignKey:String;
		protected var thisFields:Object;
		protected var thatFields:Object;
		protected var cond:Object;
		protected var joinTable:String;
		protected var joins:String;
		
		public var error:String;
		
		/**
		 * Retrieve needed informations from the two involved classes.
		 */
		public function RelationalOperation(obj:Object, prop:String)
		{
			if (obj is String) { 
				//It must be a class name
				thisClass = Reflection.getShortClassName(obj);
				try {
					var clazz:Class = getClassByAlias(thisClass);
					thisObj = new clazz();
				} catch (e:Error) {
					throw new AOError("Unhandled object type " + thisClass);
				}
			} else if (obj is ActiveRecord) {
				thisClass = obj.className;
				thisObj = obj as ActiveRecord;
			} else if (obj is Class) {
				thisClass = Reflection.getShortClassName(obj);
				try {
					thisObj = new obj();
				} catch (e:Error) {
					throw new AOError("Error instanciating  " + thisClass);
				}
				if (! thisObj is ActiveRecord)
					throw new AOError("Unhandled object type " + thisClass);
			} else {
				throw new AOError("Unhandled object type " + getQualifiedClassName(obj));
			}
			
			var schTran:SchemaTranslation = ActiveRecord.schemaTranslation;
			
			// get all information needed to find and load the relationship
			var propDesc:XML = Reflection.getMetadataByArg(obj,"",prop)[0];
			if (!propDesc) {
				throw new AOError("Property not found: "+thisClass+"."+prop);
			}else if (propDesc.@name == HAS_ONE) {
				relationship = HAS_ONE;
			} else if (propDesc.@name == HAS_MANY) {
				relationship = HAS_MANY;
			} else if (propDesc.@name == BELONGS_TO) {
				relationship = BELONGS_TO;
			} else if (propDesc.@name == MANY_TO_MANY) {
				relationship = MANY_TO_MANY;
			} else {
				throw new AOError("Unknow relationship: Metadata not found on"+thisClass+"."+prop);
			}
			
			thatClass = propDesc.arg.(@key=="className").@value;
			thatObj = new (getClassByAlias(thatClass) as Class)();
			
			thisTable = schTran.getTable(thisClass);
			thatTable = schTran.getTable(thatClass);
			
			thisPrimaryKey = schTran.getPrimaryKey(thisClass);
			thatPrimaryKey = schTran.getPrimaryKey(thatClass);
			
			thisFields = thisObj.getFields();
			thatFields = thatObj.getFields();
			
			if (!thisFields)
				throw new Error("Cannot find table or columns in '" + thisTable + "' for ActiveRecord class '" + thisClass + "'");
			
			if (!thatFields)
				throw new Error("Cannot find table or columns in '" + thatTable + "' for ActiveRecord class '" + thatClass + "'");
			
			thisProp = prop;
			if (propDesc.arg.(@key=="property").length) {
				thatProp = propDesc.arg.(@key=="property").@value
			}
			
			switch (relationship) {
				case HAS_ONE:
					if (thatProp) {
						thisForeignKey = schTran.getForeignKey(thatClass, thatProp);
					} else {
						thisForeignKey = schTran.getForeignKey(thisClass);
					}
					thatForeignKey = schTran.getForeignKey(thisClass, thisProp);
					break;
				case HAS_MANY:
					if (thatProp) {
						thisForeignKey = schTran.getForeignKey(thatClass, thatProp);
					} else {
						thisForeignKey = schTran.getForeignKey(thisClass);
					}
					thatForeignKey = schTran.getForeignKey(thisClass, thisProp);
					break;
				case BELONGS_TO:
					if (thatProp) {
						thisForeignKey = schTran.getForeignKey(thatClass, thatProp);
					} else {
						thisForeignKey = schTran.getForeignKey(thisClass);
					}
					thatForeignKey = schTran.getForeignKey(thisClass, thisProp);
					break;
				case MANY_TO_MANY:
					thisForeignKey = schTran.getForeignKey(thisClass);
					thatForeignKey = schTran.getForeignKey(thatClass);
					joinTable = schTran.getJoinTable(thisClass, prop, thatClass, thatProp);
					var joinFields:Object = thisObj.getFields(joinTable);
					if (!joinFields) {
						joinTable = schTran.getJoinTable(thatClass, thatProp, thisClass, prop);
						joinFields = thisObj.getFields(joinTable);
						if (!joinFields)
							throw new Error("Join not found");	// Cannot find the relationship
					}
					joins = " JOIN " + joinTable + " ON " + thatTable + "." + thatPrimaryKey + " = " + joinTable + "." + thatForeignKey;
					break;
			}
		}
		
		/**
		 * Load related objects from relation.
		 */
		public function loadRelated(conditions:String = null, conditionParams:Array = null, order:String = null, limit:uint = 0, offset:uint = 0):Object
		{
			switch (relationship)
			{
				case BELONGS_TO:
					return thatObj.findFirst(thatPrimaryKey + " = ?", [thisObj[thatForeignKey]]);
				case HAS_ONE:
					cond = mergeConditions(conditions, conditionParams, thisForeignKey + " = ?", [thisObj.id]);
					return thatObj.findFirst(cond.conditions, cond.params, order);
				case HAS_MANY:
					cond = mergeConditions(conditions, conditionParams, thisForeignKey + " = ?", [thisObj.id]);
					return thatObj.findAll(cond.conditions, cond.params, order, limit, offset);
				case MANY_TO_MANY:
					cond = mergeConditions(conditions, conditionParams, joinTable + "." + thisForeignKey + " = ?", [thisObj.id]);
					return thatObj.findAll(cond.conditions, cond.params, order, limit, offset, joins);
				default:
					return null;
			}
		}
		
		/**
		 * Count related objects in relation.
		 */
		public function countRelated(conditions:String = null, conditionParams:Array = null):uint
		{
			switch (relationship)
			{
				case BELONGS_TO:
					return thatObj.count(thatPrimaryKey + " = ?", [thisObj[thatForeignKey]]);
				case HAS_ONE:
					cond = mergeConditions(conditions, conditionParams, thisForeignKey + " = ?", [thisObj.id]);
					return thatObj.count(cond.conditions, cond.params);
				case HAS_MANY:
					cond = mergeConditions(conditions, conditionParams, thisForeignKey + " = ?", [thisObj.id]);
					return thatObj.count(cond.conditions, cond.params);
				case MANY_TO_MANY:
					cond = mergeConditions(conditions, conditionParams, joinTable + "." + thisForeignKey + " = ?", [thisObj.id]);
					return thatObj.count(cond.conditions, cond.params, joins);
				default:
					return 0;
			}
		}
		
		/**
		 * Save related objects in relation.
		 */
		public function saveRelated():Boolean
		{
			var obj:ActiveRecord;
			var result:Boolean;
			thisObj.connection.begin();
			
			if (relationship != BELONGS_TO && !thisObj.id)
				thisObj.save();
			
			try
			{
				switch (relationship)
				{
					case BELONGS_TO:
						thatObj.save();
						thisObj[thatForeignKey] = thatObj.id;
						result = thisObj.save();
						break;
					case HAS_ONE:
						thatObj[thisForeignKey] = thisObj.id;
						result = thatObj.save();
						break;
					case HAS_MANY:
						for each (obj in thisObj[thisProp])
						{
							obj[thisForeignKey] = thisObj.id;
							obj.save();
						}
						result = true;
						break;
					case MANY_TO_MANY:
						var insStmt:SQLStatement = new SQLStatement();
						insStmt.sqlConnection = thisObj.connection;
						insStmt.text = "INSERT OR REPLACE INTO " + joinTable + " (" + thisForeignKey + ", " + thatForeignKey + ") VALUES (?, ?)";
						insStmt.parameters[0] = thisObj.id;
						
						for each (obj in thisObj[thisProp])
						{
							obj.save();
							insStmt.parameters[1] = obj.id;
							insStmt.execute();
						}
						result = true;
						break;
					default:
						result = false;
				}
				
				thisObj.connection.commit();
			}
			catch(e:Error)
			{
				thisObj.connection.rollback();
			}
			
			return result;
		}
		
		/**
		 * Delete related objects in relation.
		 */
		public function deleteRelated(conditions:String = null, conditionParams:Array = null, joinOnly:Boolean = true):uint
		{
			switch (relationship)
			{
				case BELONGS_TO:
					return thatObj.deleteAll(thatPrimaryKey + " = ?", [thisObj[thatForeignKey]]);
				case HAS_ONE:
					cond = mergeConditions(conditions, conditionParams, thisForeignKey + " = ?", [thisObj.id]);
					return thatObj.deleteAll(cond.conditions, cond.params);
				case HAS_MANY:
					cond = mergeConditions(conditions, conditionParams, thisForeignKey + " = ?", [thisObj.id]);
					return thatObj.deleteAll(cond.conditions, cond.params);
				case MANY_TO_MANY:
					cond = mergeConditions(conditions, conditionParams, joinTable + "." + thisForeignKey + " = ?", [thisObj.id]);
					
					var all:Array = thatObj.findAll(cond.conditions, cond.params, joins);
					for (var i:int = 0; i < all.length; i++)
						all[i] = all[i].id;
					
					var allIds:String = "(" + all.join(",") + ")";
					thisObj.query("DELETE FROM " + joinTable + " WHERE " + thatForeignKey + " IN " + allIds);
					
					if (!joinOnly)
						thisObj.query("DELETE FROM " + thatTable + " WHERE " + thatPrimaryKey + " IN " + allIds);
					
					return all.length;
				default:
					return 0;
			}
		}
		
		/**
		 * Compute conditions for relational operations.
		 */
		sql_db function mergeConditions(conditions1:String, conditions1Params:Array, conditions2:String, conditions2Params:Array):Object
		{
			var result:Object = {
				conditions: "",
				params: []
			};
			
			// merge text
			if (conditions1 && conditions2)
				result.conditions = conditions1 + " AND " + conditions2;
			else if (conditions1)
				result.conditions = conditions1;
			else if (conditions2)
				result.conditions = conditions2;
			
			// merge parameters
			if (conditions1Params && conditions1Params.length && conditions2Params && conditions2Params.length)
				result.params = conditions1Params.concat(conditions2Params);
			else if (conditions1Params && conditions1Params.length)
				result.params = conditions1Params;
			else if (conditions2Params && conditions2Params.length)
				result.params = conditions2Params;
			
			return result;
		}
	}
}