import java.util.Random;

public class Main {
	
	public static void main(String[] args)
	{
		Matrix matrix = new Matrix();
		MultiThread mThread = new MultiThread();
				
		int[][] a = new int[10][4];
		int[][] b = new int [4][10];
		int [][] c = new int [10][10];
		
		
		 a = matrix.generate(10, 4);
		 b = matrix.generate(4, 10);
		
	
		
		c = mThread.multiply(a,b);
		matrix.print(c);

	
	}
}
