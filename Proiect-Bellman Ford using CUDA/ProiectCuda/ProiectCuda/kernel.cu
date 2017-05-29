
#include "cuda_runtime.h"
#include "device_launch_parameters.h"

#include <stdio.h>
#include <vector>
#include <iostream>
#include <stdio.h>
#include <float.h>
#include <ctime>

#define BLOCK_SIZE 16

/*********************** GRAPH STRUCTURE ****************************************/

// --- The graph data structure is an adjacency list.
typedef struct {

	// --- Contains the integer offset to point to the edge list for each vertex
	int *vertexArray;

	// --- Overall number of vertices
	int numVertices;

	// --- Contains the "destination" vertices each edge is attached to
	int *edgeArray;

	// --- Overall number of edges
	int numEdges;

	// --- Contains the weight of each edge
	float *weightArray;

} GraphData;



/********************** GENERATE RANDOM GRAPH **********************************/

void generateRandomGraph(GraphData *graph, int numVertices, int neighborsPerVertex) {

	graph->numVertices = numVertices;
	graph->vertexArray = (int *)malloc(graph->numVertices * sizeof(int));
	graph->numEdges = numVertices * neighborsPerVertex;
	graph->edgeArray = (int *)malloc(graph->numEdges * sizeof(int));
	graph->weightArray = (float *)malloc(graph->numEdges * sizeof(float));

	for (int i = 0; i < graph->numVertices; i++)
		graph->vertexArray[i] = i * neighborsPerVertex;

	int *tempArray = (int *)malloc(neighborsPerVertex * sizeof(int));
	for (int k = 0; k < numVertices; k++) {
		for (int l = 0; l < neighborsPerVertex; l++)
			tempArray[l] = INT_MAX;
		for (int l = 0; l < neighborsPerVertex; l++) {
			bool goOn = false;
			int temp;
			while (goOn == false) {
				goOn = true;
				temp = (rand() % graph->numVertices);
				for (int t = 0; t < neighborsPerVertex; t++)
					if (temp == tempArray[t]) goOn = false;
				if (temp == k) goOn = false;
				if (goOn == true) tempArray[l] = temp;
			}
			graph->edgeArray[k * neighborsPerVertex + l] = temp;
			graph->weightArray[k * neighborsPerVertex + l] = (float)(rand() % 99 +1) ;
		}
	}
}



/************************* ARRAY INITIALIZATION KERNER *************************/

__global__ void initializeArray( float* __restrict__ d_shortestDistances,
	const int sourceVertex, const int numVertices) {

	int tid = blockIdx.x * blockDim.x + threadIdx.x;

	if (tid < numVertices) {

		if (sourceVertex == tid) {

			d_shortestDistances[tid] = 0.f;
		}

		else {

			d_shortestDistances[tid] = FLT_MAX;
		}
	}
}




/************************ Bellman Ford CPU FUNCTION ***********************/

void bellmanFordCPU(GraphData *graph, float *h_shortestDistances, int sourceVertex, const int N) {

	// --- Initialize h_shortestDistancesances as infinite 
	for (int i = 0; i < N; i++){
			h_shortestDistances[i] = FLT_MAX;
		}


	// --- h_shortestDistancesance of the source vertex from itself is always 0
	h_shortestDistances[sourceVertex] = 0.f;

	// ---Iterations
	for (int iterCount = 0; iterCount < N - 1; iterCount++) {

	// --- Relaxation loop
		for (int j = 0; j < N; j++)
		{
			for (int l = 0; l < graph->numEdges/graph->numVertices; l++) {
				if (h_shortestDistances[ graph->edgeArray[ graph->vertexArray[j] + l ] ] > h_shortestDistances[j] + graph->weightArray[graph->edgeArray[graph->vertexArray[j] + l]]) {
					h_shortestDistances[graph->edgeArray[graph->vertexArray[j] + l]] = h_shortestDistances[j] + graph->weightArray[graph->edgeArray[graph->vertexArray[j] + l]];
				}
			}
		}
	}
}




/************************** BELLMAN FORD GPU KERNEL  **************************/

__global__  void relax(const int * __restrict__ vertexArray, const int* __restrict__ edgeArray,
	const float * __restrict__ weightArray, float* __restrict__ shortestDistances,
	 const int numVertices, const int numEdges) {

	int tid = blockIdx.x*blockDim.x + threadIdx.x;

	if (tid < numVertices) {
		for (int i = 0; i <= numEdges / numVertices; i++) {
			if (shortestDistances[edgeArray[vertexArray[tid] + i]] > shortestDistances[tid] + weightArray[edgeArray[vertexArray[tid] + i]] ) {
				shortestDistances[edgeArray[vertexArray[tid] + i]] = shortestDistances[tid] + weightArray[edgeArray[vertexArray[tid] + i]];
			}
		}
	}
}




/************************ BELLMAN FORD GPU FUNCTION *************************/

void bellmanFordGPU(GraphData *graph, const int sourceVertex, float * __restrict__ h_shortestDistances, float & elapsedGPU) {

	// --- Create device-side adjacency-list, namely, vertex array Va, edge array Ea and weight array Wa from G(V,E,W)
	int     *d_vertexArray;         
	cudaMalloc(&d_vertexArray, sizeof(int)   * graph->numVertices);
	
	int     *d_edgeArray;           
	cudaMalloc(&d_edgeArray, sizeof(int)   * graph->numEdges);

	float   *d_weightArray;       
	cudaMalloc(&d_weightArray, sizeof(float) * graph->numEdges);

	// --- Copy adjacency-list to the device
	cudaMemcpy(d_vertexArray, graph->vertexArray, sizeof(int)   * graph->numVertices, cudaMemcpyHostToDevice);
	cudaMemcpy(d_edgeArray, graph->edgeArray, sizeof(int)   * graph->numEdges, cudaMemcpyHostToDevice);
	cudaMemcpy(d_weightArray, graph->weightArray, sizeof(float) * graph->numEdges, cudaMemcpyHostToDevice);

	
	float   *d_shortestDistances;          
	cudaMalloc(&d_shortestDistances, sizeof(float) * graph->numVertices);
	
	// Invoke kernel 
	int threadsPerBlock = 1024; 
	int blocksPerGrid = (graph->numVertices + threadsPerBlock - 1) / threadsPerBlock;
	initializeArray <<<blocksPerGrid, threadsPerBlock >> >(d_shortestDistances,sourceVertex, graph->numVertices);
	cudaPeekAtLastError();
	cudaDeviceSynchronize();

	clock_t beginGPU = clock();
		for (int asyncIter = 0; asyncIter < graph->numVertices-1; asyncIter++) {
			relax << <blocksPerGrid, threadsPerBlock >> >(d_vertexArray, d_edgeArray, d_weightArray, d_shortestDistances, graph->numVertices, graph->numEdges);
			cudaPeekAtLastError();
			cudaDeviceSynchronize();
			
		}
	clock_t endGPU = clock();
    elapsedGPU = float(endGPU - beginGPU) / CLOCKS_PER_SEC;

	// --- Copy the result to host
	cudaMemcpy(h_shortestDistances, d_shortestDistances, sizeof(float) * graph->numVertices, cudaMemcpyDeviceToHost);


	cudaFree(d_vertexArray);
	cudaFree(d_edgeArray);
	cudaFree(d_weightArray);
	cudaFree(d_shortestDistances);

}


int main() {
	srand(time(NULL));
	// --- Number of graph vertices
	int numVertices = 5000;

	// --- Number of edges per graph vertex
	int neighborsPerVertex = 100;

	// --- Source vertex
	int sourceVertex = 0;

	// --- Allocate memory for arrays
	GraphData graph;
	generateRandomGraph(&graph, numVertices, neighborsPerVertex);

	// --- From adjacency list to adjacency matrix.
	//     Initializing the adjacency matrix
	//float *weightMatrix = (float *)malloc(numVertices * numVertices * sizeof(float));
	//for (int k = 0; k < numVertices * numVertices; k++) weightMatrix[k] = FLT_MAX;

	// --- Displaying the adjacency list and constructing the adjacency matrix
	/*printf("Adjacency list\n");
	for (int k = 0; k < numVertices; k++) weightMatrix[k * numVertices + k] = 0.f;
	for (int k = 0; k < numVertices; k++)
		for (int l = 0; l < neighborsPerVertex; l++) {
			weightMatrix[k * numVertices + graph.edgeArray[graph.vertexArray[k] + l]] = graph.weightArray[graph.vertexArray[k] + l];
			printf("Vertex nr. %i; Edge nr. %i; Weight = %f\n", k, graph.edgeArray[graph.vertexArray[k] + l],
				graph.weightArray[graph.vertexArray[k] + l]);
		}
		*/
	// --- Displaying the adjacency matrix
	/*printf("\nAdjacency matrix\n");
	for (int k = 0; k < numVertices; k++) {
		for (int l = 0; l < numVertices; l++)
			if (weightMatrix[k * numVertices + l] < FLT_MAX)
				printf("%1.3f\t", weightMatrix[k * numVertices + l]);
			else
				printf("--\t");
		printf("\n");
	}
	*/

	// --- Running Bellman Ford on the CPU
	float *h_shortestDistancesCPU = (float *)malloc(numVertices * sizeof(float));
	clock_t beginCPU = clock();
	bellmanFordCPU(&graph, h_shortestDistancesCPU, sourceVertex, numVertices);
	clock_t endCPU = clock();

     printf("\nCPU results\n");
	for (int k = 0; k < numVertices; k++) printf("From vertex %i to vertex %i = %f\n", sourceVertex, k, h_shortestDistancesCPU[k]);

	// --- Running Bellman Ford on the GPU
	float elapsedGPU_secs;
	float *h_shortestDistancesGPU = (float*)malloc(sizeof(float) * graph.numVertices);
	bellmanFordGPU(&graph, sourceVertex, h_shortestDistancesGPU, elapsedGPU_secs);
	printf("\nGPU results\n");
	for (int k = 0; k < numVertices; k++) printf("From vertex %i to vertex %i = %f\n", sourceVertex, k, h_shortestDistancesGPU[k]);

	// --- Calculate time
	float elapsedCPU_secs = float(endCPU - beginCPU) / CLOCKS_PER_SEC;
	printf("\nTime using CPU:       %f sec\n", elapsedCPU_secs);
	printf("Time using Cuda(GPU):   %f sec\n", elapsedGPU_secs);
	
	free(h_shortestDistancesCPU);
	free(h_shortestDistancesGPU);

	printf("Blocks per Grid used:   %d \n",(numVertices + 1024 - 1) /1024);
	return 0;
}