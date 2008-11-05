package info.noirbizarre.airorm
{
	import flash.utils.getQualifiedClassName;
	
	import info.noirbizarre.airorm.utils.Inflector;
	import info.noirbizarre.airorm.utils.Reflection;
	
	/**
	 * Retrieve database metadata from class name
	 */
	public class SchemaTranslation
	{
		
		/**
		 * Return the name of the table associated with obj.
		 */
		public function getTable(obj:Object):String
		{
			if (obj is String) { 
				//It must be a class name
				return Inflector.pluralize(obj as String);
			} else if (obj is ActiveRecord) {
				return Inflector.pluralize(obj.className);
			} else if (obj is Class) {
				return Inflector.pluralize(Reflection.getShortClassName(obj));
			} else {
				throw new AOError("Unhandled object type " + getQualifiedClassName(obj));
			}
		}
		
		/**
		 * Return the primary key field name for obj.
		 */
		public function getPrimaryKey(obj:Object):String
		{
			return "id";
		}
		
		/**
		 * Returns the foreign key field name of obj.
		 * If name is set, returns the foreign key field name of property into obj
		 */
		public function getForeignKey(obj:Object, property:String=null):String
		{
			if (property) {
				return property + "_id";
			} else {
				if (obj is String) { 
					//It must be a class name
					return Inflector.lowerFirst(Reflection.getShortClassName(obj as String)) + "_id";
				} else if (obj is ActiveRecord) {
					return Inflector.lowerFirst(obj.className) + "_id";
				} else if (obj is Class) {
					return Inflector.lowerFirst(Reflection.getShortClassName(obj)) + "_id";
				} else {
					throw new AOError("Unhandled object type " + getQualifiedClassName(obj));
				}
			}
		}
		
		/**
		 * Return the join table name for the association obj1.prop1-obj2.prop2
		 */ 
		public function getJoinTable(obj1:Object, prop1:String, obj2:Object, prop2:String):String
		{
			var part1:String;
			var part2:String;
			
			if (obj1 is String) { 
				//It must be a class name
				part1 = (obj1 as String) + "_" + prop1;
			} else if (obj1 is ActiveRecord) {
				part1 = obj1.className + "_" + prop1;
			} else if (obj1 is Class) {
				part1 = Reflection.getShortClassName(obj1) + "_" + prop1;
			}  else {
				throw new AOError("Unhandled object type " + getQualifiedClassName(obj1));
			}
			
			if (obj2 is String) { 
				//It must be a class name
				part2 = (obj2 as String) + "_" + prop2;
			} else if (obj2 is ActiveRecord) {
				part2 = obj2.className + "_" + prop2;
			} else if (obj2 is Class) {
				part2 = Reflection.getShortClassName(obj2) + "_" + prop2;
			} else {
				throw new AOError("Unhandled object type " + getQualifiedClassName(obj2));
			}
			return (part1 < part2) ? part1 + "__" + part2 : part2 + "__" + part1;
		}
		
		/**
		 * Return the field name for property
		 */
		public function getField(property:String):String
		{
			return property;
		}
		
		/**
		 * Return the creation field name
		 */
		public function getCreatedField(obj:Object):String
		{
			var members:XMLList = Reflection.getByMetadata(obj,"Timestamp");
			for each (var member:XML in members) {
				if (member.metadata.(@name == "Timestamp" && elements("arg").(@value == "creation").length()).length()) {
					return member.@name
				}
			} 
			return null;
		}
		
		/**
		 * Return the last modification field name
		 */
		public function getModifiedField(obj:Object):String
		{
			var members:XMLList = Reflection.getByMetadata(obj,"Timestamp");
			for each (var member:XML in members) {
				if (member.metadata.(@name == "Timestamp" && elements("arg").(@value == "modification").length()).length()) {
					return member.@name
				}
			} 
			return null;
		}
	}
}