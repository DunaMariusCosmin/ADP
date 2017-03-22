import java.util.Random;

public class Main {
	
	public static void main(String[] args)
	{
		Matrix matrix = new Matrix();
		MultiThread mThread = new MultiThread();
				
		int[][] a = new int[8][4];
		int[][] b = new int [4][8];
		int [][] c = new int [8][8];
		
		
		 a = matrix.generate(8, 4);
		 b = matrix.generate(4, 8);
		
	
		
		c = mThread.multiply(a,b);
		matrix.print(c);

	
	}
}
