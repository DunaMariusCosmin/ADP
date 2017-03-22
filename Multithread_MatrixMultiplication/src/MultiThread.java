
public class MultiThread {

	 public static int[][] multiply(int[][] a, int[][] b) {

	        int aRows = a.length;
	        int aColumns = a[0].length;
	        int bRows = b.length;
	        int bColumns = b[0].length;

	        int[][] toReturn = new int[aRows][bColumns];
	        
	        for (int i = 0; i < aRows; i++) {
	            for (int j = 0; j < bColumns; j++) {
	                toReturn[i][j] = 0;
	            }
	        }

	        int nrThreads = 4;
	        Thread[] threads = new Thread[nrThreads];
	        
	        for (int th = 0; th < nrThreads; th++) {
	        	final int thNr = th; 
				int thread_cnt = th;
	        	threads[th] = new Thread(new Runnable() {
					@Override
					public void run() {
						
						int n = aRows / nrThreads;
						

						int max = (thread_cnt + 1) * n;
						
						if (thNr == (nrThreads-1)) {
							max = aRows;
						}
						
						for (int i = (n * thread_cnt); i < max; i++) { 
				            for (int j = 0; j < bColumns; j++) { 
				                for (int k = 0; k < aColumns; k++) { 
				                    toReturn[i][j] += a[i][k] * b[k][j];
				                }
				            }
				        }
					}
				});
	        }
	        
	        for (int i = 0; i < nrThreads; i++) {
	        	threads[i].run();
	        }

	        for (int i = 0; i < nrThreads; i++) {
	        	try {
					threads[i].join();
				} catch (InterruptedException e) {
					e.printStackTrace();
				}
	        }
	        

	        return toReturn;
	    }
}
