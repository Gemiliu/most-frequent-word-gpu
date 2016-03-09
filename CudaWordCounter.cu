/**
 * Copyright 1993-2012 NVIDIA Corporation.  All rights reserved.
 *
 * Please refer to the NVIDIA end user license agreement (EULA) associated
 * with this source code for terms and conditions that govern your use of
 * this software. Any use, reproduction, disclosure, or distribution of
 * this software and related documentation outside the terms of the EULA
 * is strictly prohibited.
 *
 * Modifications to run Trie Min Heap done by Jeremy Villalobos (2015)
 * https://www.elance.com/s/jfvillal/
 */
#include <stdio.h>
#include <stdlib.h>

#include <string.h>
#include <ctype.h>

# define MAX_CHARS 26
# define MAX_WORD_SIZE 30
#include<stdbool.h>

// A Trie node
typedef struct TrieNode TrieNode;
struct TrieNode {
	bool isEnd; // indicates end of word
	unsigned frequency;  // the number of occurrences of a word
	int indexMinHeap; // the index of the word in minHeap
	TrieNode* child[MAX_CHARS]; // represents 26 slots each for 'a' to 'z'.
};
//typedef struct TrieNode TrieNode;

// A Min Heap node
struct MinHeapNode {
	TrieNode* root; // indicates the leaf node of TRIE
	unsigned frequency; //  number of occurrences
	char* word; // the actual word stored
};
typedef struct MinHeapNode MinHeapNode;
// A Min Heap
typedef struct MinHeap MinHeap;
struct MinHeap {
	unsigned capacity; // the total size a min heap
	int count; // indicates the number of slots filled.
	MinHeapNode* array; //  represents the collection of minHeapNodes
};

//void printKMostFreq(FILE* fp, int k);
__device__ size_t mystrlen(const char* str);
__device__ char* mystrcpy(char *s1, const char *s2);
//__device__ char getLetter(int id);
__device__ void displayMinHeap(MinHeap* minHeap, char* ans, int buff_size,
		unsigned* count, int thread_id, int* lineup, int* win, char* top_words,
		unsigned int* top_words_count);
__device__ void insertTrieAndHeap(const char *word, TrieNode** root,
		MinHeap* minHeap);
__device__ void insertUtil(TrieNode** root, MinHeap* minHeap, const char* word,
		const char* dupWord);
__device__ void insertUtil(TrieNode** root, MinHeap* minHeap, const char* word,
		const char* dupWord);
__device__ void insertInMinHeap(MinHeap* minHeap, TrieNode** root,
		const char* word);
__device__ void buildMinHeap(MinHeap* minHeap);
__device__ void minHeapify(MinHeap* minHeap, int idx);
__device__ void swapMinHeapNodes(MinHeapNode* a, MinHeapNode* b);
__device__ MinHeap* createMinHeap(int capacity);
__device__ TrieNode* newTrieNode();

/**
 * This macro checks return value of the CUDA runtime call and exits
 * the application if the call failed.
 */
#define CUDA_CHECK_RETURN(value) {											\
	cudaError_t _m_cudaStat = value;										\
	if (_m_cudaStat != cudaSuccess) {										\
		fprintf(stderr, "Error %s at line %d in file %s\n",					\
				cudaGetErrorString(_m_cudaStat), __LINE__, __FILE__);		\
		exit(1);															\
	} }

#define WORKERS 12
#define BUFF_SIZE 16
#define K_WORDS 5

__global__ void k_words(char * data, int size, char* ans, unsigned * counts,
		int* lineup, int* win, char* top_words, unsigned int* top_words_count) {

//	if (threadIdx.x == 0) {
	// Create a Min Heap of Size k
	MinHeap* minHeap = createMinHeap(K_WORDS);

	// Create an empty Trie
	TrieNode* root = NULL;

	// A buffer to store one word at a time
	char buffer[BUFF_SIZE];

	// Read words one by one from file.  Insert the word in Trie and Min Heap
	int m = 0;
	for (int i = 0; i < size; i++) {
		if (data[i] == ' ') {
			if (m > 1) {
				//process word
				buffer[m] = '\0';
				/***
				 * The letters are distributed among the processors.
				 * There can only be up to 28 workers for this implementation
				 */
				if (threadIdx.x == (buffer[0] - 97) % WORKERS) {
					insertTrieAndHeap(buffer, &root, minHeap);
				}
			}
			m = 0;
		} else {
			buffer[m] = data[i];
			++m;
			/**
			 * ignore words longer than  BUFF_SIZE bytes
			 */
			if (m >= BUFF_SIZE - 1) {
				m = 0;
			}
		}

//	    	while( fscanf( fp, "%s", buffer ) != EOF )
//	    		insertTrieAndHeap(buffer, &root, minHeap);

		// The Min Heap will have the k most frequent words, so print Min Heap nodes

	}

	displayMinHeap(minHeap, ans, BUFF_SIZE, counts, threadIdx.x, lineup, win,
			top_words, top_words_count);

//	}
}

//__device__ char getLetter(int id) {
//	return id + 97;
//}

/**
 * Host function that prepares data array and passes it to the CUDA kernel.
 */
int main(int argc, char** argv) {
	char *d = NULL;
	char *ans = NULL;
	unsigned *counts = NULL;
	int *lineup = NULL;
	int *win = NULL;
	char* top_words;
	unsigned int* top_words_count;

	char *host_ans = new char[K_WORDS * BUFF_SIZE * WORKERS];
	unsigned *host_counts = new unsigned[K_WORDS * WORKERS];

	char * host_top_words = new char[K_WORDS * BUFF_SIZE];
	unsigned *host_top_words_count = new unsigned[K_WORDS];

	int *host_win = new int[K_WORDS];

	clock_t begin, end;
	double time_spent;

	begin = clock();

	FILE *fp =
			fopen(	argv[1],
					"r");
	if (fp == NULL)
		printf("File doesn't exist ");
	else {

		fseek(fp, 0, SEEK_END);
		long fsize = ftell(fp);
		fseek(fp, 0, SEEK_SET);

		char *string = (char*) malloc(fsize + 1);
		fread(string, fsize, 1, fp);
		fclose(fp);

		string[fsize] = 0;

//		printf("file characters:\n%s\n", string);

		CUDA_CHECK_RETURN(cudaMalloc((char** ) &d, sizeof(char) * fsize));

		CUDA_CHECK_RETURN(
				cudaMalloc((char** ) &ans, sizeof(char) * K_WORDS * BUFF_SIZE * WORKERS));

		CUDA_CHECK_RETURN(
				cudaMalloc((int** ) &counts, sizeof(unsigned) * K_WORDS * WORKERS));

		CUDA_CHECK_RETURN(cudaMalloc((int** ) &lineup, sizeof(int) * WORKERS));

		CUDA_CHECK_RETURN(cudaMalloc((int** ) &win, sizeof(int) * K_WORDS));

		CUDA_CHECK_RETURN(
				cudaMalloc((char** ) &top_words, sizeof(char) * K_WORDS * BUFF_SIZE));

		CUDA_CHECK_RETURN(
				cudaMalloc((unsigned int** ) &top_words_count, sizeof(int) * K_WORDS ));

		CUDA_CHECK_RETURN(
				cudaMemcpy(d, string, sizeof(char) * fsize,
						cudaMemcpyHostToDevice));

		for (int m = 0; m < WORKERS * K_WORDS * BUFF_SIZE; m++) {
			host_ans[m] = ' ';
		}
		for (int m = 0; m < WORKERS * K_WORDS; m++) {
			host_counts[m] = 0;
		}
		CUDA_CHECK_RETURN(
				cudaMemcpy(ans, host_ans, sizeof(char) * K_WORDS *BUFF_SIZE, cudaMemcpyHostToDevice));
		CUDA_CHECK_RETURN(
				cudaMemcpy(counts, host_counts, sizeof(unsigned) * K_WORDS , cudaMemcpyHostToDevice));
//		printf("Size %d \n");
		k_words<<<1, WORKERS>>>(d, fsize, ans, counts, lineup, win, top_words,
				top_words_count);

		CUDA_CHECK_RETURN(cudaThreadSynchronize());	// Wait for the GPU launched work to complete
		CUDA_CHECK_RETURN(cudaGetLastError());
		CUDA_CHECK_RETURN(
				cudaMemcpy(string, d, sizeof(char) * fsize,
						cudaMemcpyDeviceToHost));

		CUDA_CHECK_RETURN(
				cudaMemcpy(host_ans, ans, sizeof(char) * K_WORDS * BUFF_SIZE * WORKERS, cudaMemcpyDeviceToHost));

		CUDA_CHECK_RETURN(
				cudaMemcpy(host_counts, counts, sizeof(unsigned) * K_WORDS * WORKERS, cudaMemcpyDeviceToHost));

		CUDA_CHECK_RETURN(
				cudaMemcpy(host_win,win, sizeof(int) * K_WORDS, cudaMemcpyDeviceToHost));

		CUDA_CHECK_RETURN(
				cudaMemcpy(host_top_words, top_words, sizeof(char) * K_WORDS * BUFF_SIZE, cudaMemcpyDeviceToHost));
		CUDA_CHECK_RETURN(
				cudaMemcpy(host_top_words_count, top_words_count, sizeof(int) * K_WORDS, cudaMemcpyDeviceToHost));

//		for (int m = 0; m < WORKERS; m++) {
//			printf("\nworker: %d  \n", m);
//			for (int i = 0; i < K_WORDS; i++) {
//				printf("\n%u ", host_counts[m * K_WORDS + i]);
//				for (int j = 0; j < BUFF_SIZE; j++) {
//					printf("%c",
//							host_ans[m * (BUFF_SIZE * K_WORDS) + (i * BUFF_SIZE)
//									+ j]);
//				}
//				printf("");
//			}
//		}

		printf("\n***Result***\n");

		int k_words = 0;
		for (int k = 0; k < K_WORDS; k++) {
			unsigned max = 0;

			for (int m = 0; m < WORKERS; m++) {
				for (int i = 0; i < K_WORDS; i++) {
					if (max < host_counts[m * K_WORDS + i]) {
						max = host_counts[m * K_WORDS + i];
					}
				}
			}

			for (int m = 0; m < WORKERS; m++) {
				for (int i = 0; i < K_WORDS; i++) {
					if (max == host_counts[m * K_WORDS + i]) {
						printf("%u word: ", host_counts[m * K_WORDS + i]);
						host_counts[m * K_WORDS + i] = 0;
						for (int j = 0; j < BUFF_SIZE; j++) {
							printf("%c",
									host_ans[m * (BUFF_SIZE * K_WORDS)
											+ i * BUFF_SIZE + j]);
						}
						printf("\n");
						++k_words;
					}
					if (k_words == K_WORDS) {
						break;
					}

				}
				if (k_words == K_WORDS) {
					break;
				}
			}
			if (k_words == K_WORDS) {
				break;
			}
		}

//		for (int i = 0; i < K_WORDS; i++) {
//			printf("\ni %d win %d ", i, host_win[i]);
//		}

		CUDA_CHECK_RETURN(cudaFree((void* ) d));
		CUDA_CHECK_RETURN(cudaDeviceReset());

		/* here, do your time-consuming job */
		end = clock();
		time_spent = (double) (end - begin) ;/// CLOCKS_PER_SEC;

		printf("\nTime: %f \n", time_spent);
	}
	return 0;
}

// A utility function to create a new Trie node
__device__ TrieNode* newTrieNode() {
	// Allocate memory for Trie Node
	TrieNode* trieNode = (TrieNode *) malloc(sizeof(TrieNode));

	// Initialize values for new node
	trieNode->isEnd = 0;
	trieNode->frequency = 0;
	trieNode->indexMinHeap = -1;
	int i;
	for (i = 0; i < MAX_CHARS; ++i)
		trieNode->child[i] = NULL;

	return trieNode;
}

// A utility function to create a Min Heap of given capacity
__device__ MinHeap* createMinHeap(int capacity) {
	MinHeap* minHeap = (MinHeap *) malloc(sizeof(MinHeap*));

	minHeap->capacity = capacity;
	minHeap->count = 0;

	// Allocate memory for array of min heap nodes
	minHeap->array = (MinHeapNode *) malloc(sizeof(MinHeapNode) * capacity);//new MinHeapNode [ minHeap->capacity ];

	return minHeap;
}

// A utility function to swap two min heap nodes. This function
// is needed in minHeapify
__device__ void swapMinHeapNodes(MinHeapNode* a, MinHeapNode* b) {
	MinHeapNode temp = *a;
	*a = *b;
	*b = temp;
}

// This is the standard minHeapify function. It does one thing extra.
// It updates the minHapIndex in Trie when two nodes are swapped in
// in min heap
__device__ void minHeapify(MinHeap* minHeap, int idx) {
	int left, right, smallest;

	left = 2 * idx + 1;
	right = 2 * idx + 2;
	smallest = idx;
	if (left < minHeap->count
			&& minHeap->array[left].frequency
					< minHeap->array[smallest].frequency)
		smallest = left;

	if (right < minHeap->count
			&& minHeap->array[right].frequency
					< minHeap->array[smallest].frequency)
		smallest = right;

	if (smallest != idx) {
		// Update the corresponding index in Trie node.
		minHeap->array[smallest].root->indexMinHeap = idx;
		minHeap->array[idx].root->indexMinHeap = smallest;

		// Swap nodes in min heap
		swapMinHeapNodes(&minHeap->array[smallest], &minHeap->array[idx]);

		minHeapify(minHeap, smallest);
	}
}

// A standard function to build a heap
__device__ void buildMinHeap(MinHeap* minHeap) {
	int n, i;
	n = minHeap->count - 1;

	for (i = (n - 1) / 2; i >= 0; --i)
		minHeapify(minHeap, i);
}

// Inserts a word to heap, the function handles the 3 cases explained above
__device__ void insertInMinHeap(MinHeap* minHeap, TrieNode** root,
		const char* word) {
	// Case 1: the word is already present in minHeap
	if ((*root)->indexMinHeap != -1) {
		++(minHeap->array[(*root)->indexMinHeap].frequency);

		// percolate down
		minHeapify(minHeap, (*root)->indexMinHeap);
	}

	// Case 2: Word is not present and heap is not full
	else if (minHeap->count < minHeap->capacity) {
		int count = minHeap->count;
		minHeap->array[count].frequency = (*root)->frequency;
		minHeap->array[count].word = (char *) malloc(
				sizeof(char) * mystrlen(word) + 1);
		mystrcpy(minHeap->array[count].word, word);

		minHeap->array[count].root = *root;
		(*root)->indexMinHeap = minHeap->count;

		++(minHeap->count);
		buildMinHeap(minHeap);
	}

	// Case 3: Word is not present and heap is full. And frequency of word
	// is more than root. The root is the least frequent word in heap,
	// replace root with new word
	else if ((*root)->frequency > minHeap->array[0].frequency) {

		minHeap->array[0].root->indexMinHeap = -1;
		minHeap->array[0].root = *root;
		minHeap->array[0].root->indexMinHeap = 0;
		minHeap->array[0].frequency = (*root)->frequency;

		// delete previously allocated memoory and
		free(minHeap->array[0].word);
		minHeap->array[0].word = (char *) malloc(
				sizeof(char) * mystrlen(word) + 1);
		mystrcpy(minHeap->array[0].word, word);

		minHeapify(minHeap, 0);
	}
}

__device__ size_t mystrlen(const char *str) {
	register const char *s;

	for (s = str; *s; ++s)
		;
	return (s - str);
}

__device__ char* mystrcpy(char *s1, const char *s2) {
	char *s = s1;
	while ((*s++ = *s2++) != 0)
		;
	return (s1);
}

// Inserts a new word to both Trie and Heap
__device__ void insertUtil(TrieNode** root, MinHeap* minHeap, const char* word,
		const char* dupWord) {
	// Base Case
	if (*root == NULL)
		*root = newTrieNode();

	//  There are still more characters in word
	if (*word != '\0')
		insertUtil(&((*root)->child[*word - 97]), minHeap, word + 1, dupWord);
	else // The complete word is processed
	{
		// word is already present, increase the frequency
		if ((*root)->isEnd)
			++((*root)->frequency);
		else {
			(*root)->isEnd = 1;
			(*root)->frequency = 1;
		}

		// Insert in min heap also
		insertInMinHeap(minHeap, root, dupWord);
	}
}

// add a word to Trie & min heap.  A wrapper over the insertUtil
__device__ void insertTrieAndHeap(const char *word, TrieNode** root,
		MinHeap* minHeap) {
	insertUtil(root, minHeap, word, word);
}

// A utility function to show results, The min heap
// contains k most frequent words so far, at any time
//
__device__ void displayMinHeap(MinHeap* minHeap, char* ans, int buff_size,
		unsigned* count, const int thread_id, int* lineup, int* win,
		char* top_words, unsigned int* top_words_count) {

	int i;

	for (i = 0; i < minHeap->count; ++i) {
		for (int j = 0; j < buff_size; j++) {
			ans[(thread_id * K_WORDS * BUFF_SIZE) + (i * buff_size) + j] =
					minHeap->array[i].word[j];
		}
		count[thread_id * K_WORDS + i] = minHeap->array[i].frequency;
		//		printf("%s : %d\n", minHeap->array[i].word,
		//				minHeap->array[i].frequency);
	}

	for (i = minHeap->count; i < K_WORDS; ++i) {
		ans[(thread_id * K_WORDS * BUFF_SIZE) + (i * buff_size)] = '\0';
		count[thread_id * K_WORDS + i] = 0;
	}

}

