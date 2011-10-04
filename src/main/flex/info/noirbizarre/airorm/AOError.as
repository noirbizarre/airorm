package info.noirbizarre.airorm
{
	public class AOError extends Error
	{
		public function AOError(message:String="", id:int=0)
		{
			super(message, id);
		}
		
	}
}