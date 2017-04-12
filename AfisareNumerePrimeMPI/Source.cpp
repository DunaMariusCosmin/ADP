# include <iostream>
#include "mpi.h"

using namespace std;



int main(int argc, char *argv[])
{
	int nrTotalElemente = 0;
	int nrThreaduri;
	int idThread;
	int init;
	int lungimeInterval;
	int start;
	int stop;


	init = MPI_Init(&argc, &argv);

	if (init != MPI_SUCCESS) {
		cout << "Nu s-a facut initializarea MPI";
		MPI_Abort(MPI_COMM_WORLD, init);
	}

	MPI_Comm_size(MPI_COMM_WORLD, &nrThreaduri);
	MPI_Comm_rank(MPI_COMM_WORLD, &idThread);
	
	if (idThread == 0) {
		cout << "Introduceti numarul de elemente:";
		cin >> nrTotalElemente;
	}

	MPI_Bcast(&nrTotalElemente, 1, MPI_INT, 0, MPI_COMM_WORLD);
	
	if (idThread != 0) {
		lungimeInterval = nrTotalElemente / (nrThreaduri-1);

		if (lungimeInterval * (idThread-1) == 0)
			start = 2;
		else
			start = lungimeInterval * (idThread-1);

		if (idThread == (nrThreaduri - 1)) {
			stop = nrTotalElemente;
		}
		else {
			stop = lungimeInterval * (idThread - 1) + lungimeInterval;
		}
		for (int nr = start; nr < stop; ++nr)
		{
			bool nrPrim = true;
			for (int div = 2; div <= nr / 2; div++)
				if (nr % div == 0)
				{
					nrPrim = false;
					break;
				}
			if (nrPrim)
				cout << "Numarul prim: " << nr << "  thread-ul : " << idThread << endl;
		}
	}
	MPI_Finalize();
	return 0;
}

