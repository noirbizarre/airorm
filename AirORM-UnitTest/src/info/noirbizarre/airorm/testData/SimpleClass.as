package info.noirbizarre.airorm.testData
{
	[TestMetadata("Test",param="TestParam")]
	public class SimpleClass
	{
		
		public var myPublicVar:String;
		[TestMetadata] public var myOtherVar:String;
		protected var myProtectedVar:uint;
		private var myPrivateVar:String;
		
		public function SimpleClass() {
		}
		
		public function myFunction():void {
			
		}

	}
}