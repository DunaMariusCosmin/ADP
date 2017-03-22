
#include <omp.h>
#include<stdlib.h>
#include <iostream>
#include <random>
using namespace std;



int main()
{
    int i,j;
	int rowsA = 10;
	int colsA = 5;
	int rowsB = 5;
	int colsB = 20;

	int a[rowsA][colsA];
	int b[rowsB][colsB];
    int c[rowsA][colsB];


    for(i = 0; i < rowsA; i++){
        for(j=0; j<colsA; j++)
            a[i][j] = rand() %10;
    }
     for(i = 0; i < rowsB; i++){
        for(j=0; j<colsB; j++)
            b[i][j] = rand() %10;
    }


    for(i = 0; i < rowsA; i++){
        for(j=0; j<colsB; j++)
            c[i][j] = 0;
    }

    #pragma omp parallel for
	for (int i = 0; i < rowsA; i++) {
		cout <<"Row:"<<i<< " thread:" <<omp_get_thread_num()endl;
		for (int j = 0; j < colsB; j++) {
			for (int k = 0; k < colsA; k++) {
				c[i][j] += a[i][k] * b[k][j];
			}
		}
	}

	cout << "\n" << endl;
	for (int i = 0; i < rowsA; i++) {
		for (int j = 0; j < colsB; j++) {
			cout << c[i][j] << "   ";
		}
		cout << endl;
	}
	cout << "\n" << endl;
}
