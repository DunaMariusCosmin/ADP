import java.util.Random;

public class Matrix {
	
	public void print(int[][] a) {

        int aRows = a.length;
        int aColumns = a[0].length;
        
        for (int i = 0; i < aRows; i++) {
            for (int j = 0; j < aColumns; j++) {
            	System.out.print(a[i][j] + "\t");
            }
            System.out.println();
        }
	}
	
	public  int[][] generate( int r, int c) {
		 int[][] toReturn = new int[r][c];
	
		 Random rand = new Random();
	
	
		 for (int i = 0; i < r; i++) {
			 for (int j = 0; j < c; j++) {
				 toReturn[i][j] = rand.nextInt(10);
			 }
		 }
		 return toReturn;
	}
}
