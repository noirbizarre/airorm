package info.noirbizarre.airorm.utils
{
	import flash.net.getClassByAlias;
	import flash.utils.Dictionary;
	import flash.utils.describeType;
	import flash.utils.getDefinitionByName;
	import flash.utils.getQualifiedClassName;
	
	public class Reflection
	{
		protected static var cache:Dictionary = new Dictionary();
		
		public function Reflection()
		{
		}
		
		/**
		 * Returns the XML description of obj.
		 */
		public static function describe(obj:Object):XML
		{
			if (obj is String || obj is XML || obj is XMLList)
				try {
					obj = getDefinitionByName(obj.toString());
				} catch (e:ReferenceError) {
					obj = getClassByAlias(obj.toString());
				}
			else if ( !(obj is Class) )
				obj = obj.constructor;
			
			if (obj in cache)
				return cache[obj];
			
			var info:XML = describeType(obj).factory[0];
			cache[obj] = info;
			return info;
		}
		
		public static function getMember(obj:Object, name:String):XML
		{
			var info:XML = describe(obj);
			var member:XML = info..*.(hasOwnProperty("@name") && @name == name)[0];
			
			if (!member && info.extendsClass.length())
				member = getMember(info.extendsClass[0].@type, name);
			
			return member;
		}
		
		public static function getMetadata(obj:Object, metadataType:String, includeSuperClasses:Boolean = false):XMLList
		{
			var info:XML = describe(obj);
			var metadata:XMLList = info..metadata.(@name == metadataType);
			
			if (includeSuperClasses && info.extendsClass.length())
				metadata += getMetadata(info.extendsClass[0].@type, metadataType, true);
			
			return metadata;
		}
		
		public static function getByMetadata(obj:Object, metadataType:String, includeSuperClasses:Boolean = false):XMLList
		{
			var info:XML = describe(obj);
			var metadata:XMLList = info.*.(hasOwnProperty("metadata") && elements("metadata").(@name == metadataType).length() > 0);
			
			if (includeSuperClasses && info.extendsClass.length())
				metadata += getByMetadata(info.extendsClass[0].@type, metadataType, true);
			
			return metadata;
		}
		
		public static function getMetadataByArg(obj:Object, argKey:String, argValue:String, includeSuperClasses:Boolean = false):XMLList
		{
			var info:XML = describe(obj);
			var metadata:XMLList = info..metadata.(hasOwnProperty("arg") && elements("arg").(@key == argKey && @value == argValue).length() > 0);
			
			if (includeSuperClasses && info.extendsClass.length())
				metadata += getMetadataByArg(info.extendsClass[0].@type, argKey, argValue, true);
			
			return metadata;
		}
		
		public static function getShortClassName(obj:Object):String {
			var classParts:Array
			if (obj is String) {
				var tmp:Array = (obj as String).split(".");
				classParts = (tmp.pop() as String).split("::");
			} else {
				classParts = getQualifiedClassName(obj).split("::");
			}
			 
			return (classParts.length == 1 ? classParts[0] : classParts[1]);
		}
		
	}
}