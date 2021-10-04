/*
	To use this source, cite the paper with the following bibtex:

	@inproceedings{DBLP:conf/crypto/SongLG17,
	author    = {Ling Song and Guohong Liao and Jian Guo},
	title     = {{Non-full Sbox Linearization: Applications to Collision Attacks on Round-Reduced Keccak}},
	booktitle = {Advances in Cryptology - {CRYPTO} 2017 - 37th Annual International Cryptology Conference, Santa Barbara, CA, USA, August 20-24, 2017, Proceedings, Part {II}},
	pages     = {428--451},
	year      = {2017},
	crossref  = {DBLP:conf/crypto/2017-2},
	url       = {https://doi.org/10.1007/978-3-319-63715-0_15},
	doi       = {10.1007/978-3-319-63715-0_15},
	timestamp = {Tue, 15 Aug 2017 07:01:19 +0200},
	biburl    = {http://dblp.org/rec/bib/conf/crypto/SongLG17},
	bibsource = {dblp computer science bibliography, http://dblp.org}
	}
	@proceedings{DBLP:conf/crypto/2017-2,
	editor    = {Jonathan Katz and Hovav Shacham},
	title     = {Advances in Cryptology - {CRYPTO} 2017 - 37th Annual International Cryptology Conference, Santa Barbara, CA, USA, August 20-24, 2017, Proceedings, Part {II}},
	series    = {Lecture Notes in Computer Science},
	volume    = {10402},
	publisher = {Springer},
	year      = {2017},
	url       = {https://doi.org/10.1007/978-3-319-63715-0},
	doi       = {10.1007/978-3-319-63715-0},
	isbn      = {978-3-319-63714-3},
	timestamp = {Mon, 14 Aug 2017 14:37:57 +0200},
	biburl    = {http://dblp.org/rec/bib/conf/crypto/2017-2},
	bibsource = {dblp computer science bibliography, http://dblp.org}
	}
*/
#include <cstdio>
#include <cstring>
#include <iostream>
#include <cstdlib>
#include <sys/time.h>
#include <cmath>

using namespace std;

typedef unsigned long long int uint64_t;
typedef unsigned char uint8_t;
typedef unsigned int uint32_t;
#define R 1088
#define B 1600
#define W 64
#define C 512
#define DATA_BLOCK_SIZE (R/W)
#define BLOCK_SIZE (B/W)
#define HASH_SIZE (C/2/8)
#define Nr 24
#define SUFFIX 0x01

#define BLOCKNUM 30000
#define BLOCKX (128)

texture<unsigned int,1,cudaReadModeElementType> texreference_input;


__constant__ uint64_t RC[24] = {
	0x0000000000000001, 0x0000000000008082, 0x800000000000808A,
	0x8000000080008000, 0x000000000000808B, 0x0000000080000001,
	0x8000000080008081, 0x8000000000008009, 0x000000000000008A,
	0x0000000000000088, 0x0000000080008009, 0x000000008000000A,
	0x000000008000808B, 0x800000000000008B, 0x8000000000008089,
	0x8000000000008003, 0x8000000000008002, 0x8000000000000080,
	0x000000000000800A, 0x800000008000000A, 0x8000000080008081,
	0x8000000000008080, 0x0000000080000001, 0x8000000080008008
};


#define ROL(x, n) (((x) << (n)) | ((x) >> ((uint64_t)64-(n))))


void checkCUDAError(const char *msg)
{
	cudaError_t err = cudaGetLastError();
	if( cudaSuccess != err)
	{
		fprintf(stderr, "Cuda error: %s: %s.\n", msg,
				cudaGetErrorString( err) );
		exit(EXIT_FAILURE);
	}
}


//assume each inputs have the same input length

__global__ void Keccak1600(const int inputByte, uint8_t *output, const int outputByte){

	uint32_t num_keccak_blocks = inputByte/(DATA_BLOCK_SIZE<<1);

	uint64_t state00 = 0, state01 = 0, state02 = 0, state03 = 0, state04 = 0,
				state10 = 0, state11 = 0, state12 = 0, state13 = 0, state14 = 0,
				state20 = 0, state21 = 0, state22 = 0, state23 = 0, state24 = 0,
				state30 = 0, state31 = 0, state32 = 0, state33 = 0, state34 = 0,
				state40 = 0, state41 = 0, state42 = 0, state43 = 0, state44 = 0;
	uint64_t tmpState00 = 0, tmpState01 = 0, tmpState02 = 0, tmpState03 = 0, tmpState04 = 0,
				tmpState10 = 0, tmpState11 = 0, tmpState12 = 0, tmpState13 = 0, tmpState14 = 0,
				tmpState20 = 0, tmpState21 = 0, tmpState22 = 0, tmpState23 = 0, tmpState24 = 0,
				tmpState30 = 0, tmpState31 = 0, tmpState32 = 0, tmpState33 = 0, tmpState34 = 0,
				tmpState40 = 0, tmpState41 = 0, tmpState42 = 0, tmpState43 = 0, tmpState44 = 0;
	uint64_t Csum0, Csum1, Csum2, Csum3, Csum4, D0, D1, D2, D3, D4;

	//absoring phase
	for(int k=0; k<num_keccak_blocks; k++){
#if 0 < DATA_BLOCK_SIZE
		// state00 ^= input[(blockIdx.x*BLOCKX + threadIdx.x)*inputByte+ DATA_BLOCK_SIZE*k];
		state00 ^= (uint64_t)tex1Dfetch(texreference_input, (blockIdx.x*BLOCKX + threadIdx.x)*inputByte+ DATA_BLOCK_SIZE*k) ^ ((uint64_t)tex1Dfetch(texreference_input, (blockIdx.x*BLOCKX + threadIdx.x)*inputByte+ DATA_BLOCK_SIZE*k+1) << 32);
		// printf("%016llX\n", state00);
#endif

#if 1 < DATA_BLOCK_SIZE
		// state01 ^= input[(blockIdx.x*BLOCKX + threadIdx.x)*inputByte+ DATA_BLOCK_SIZE*k+1];
		state01 ^= (uint64_t)tex1Dfetch(texreference_input, (blockIdx.x*BLOCKX + threadIdx.x)*inputByte+ DATA_BLOCK_SIZE*k+2) ^ ((uint64_t)tex1Dfetch(texreference_input, (blockIdx.x*BLOCKX + threadIdx.x)*inputByte+ DATA_BLOCK_SIZE*k+3) << 32);

#endif

#if 2 < DATA_BLOCK_SIZE
		// state02 ^= input[(blockIdx.x*BLOCKX + threadIdx.x)*inputByte+ DATA_BLOCK_SIZE*k+2];
		state02 ^= (uint64_t)tex1Dfetch(texreference_input, (blockIdx.x*BLOCKX + threadIdx.x)*inputByte+ DATA_BLOCK_SIZE*k+4) ^ ((uint64_t)tex1Dfetch(texreference_input, (blockIdx.x*BLOCKX + threadIdx.x)*inputByte+ DATA_BLOCK_SIZE*k+5) << 32);

#endif

#if 3 < DATA_BLOCK_SIZE
		// state03 ^= input[(blockIdx.x*BLOCKX + threadIdx.x)*inputByte+ DATA_BLOCK_SIZE*k+3];
		state03 ^= (uint64_t)tex1Dfetch(texreference_input, (blockIdx.x*BLOCKX + threadIdx.x)*inputByte+ DATA_BLOCK_SIZE*k+6) ^ ((uint64_t)tex1Dfetch(texreference_input, (blockIdx.x*BLOCKX + threadIdx.x)*inputByte+ DATA_BLOCK_SIZE*k+7) << 32);

#endif

#if 4 < DATA_BLOCK_SIZE
		// state04 ^= input[(blockIdx.x*BLOCKX + threadIdx.x)*inputByte+ DATA_BLOCK_SIZE*k+4];
		state04 ^= (uint64_t)tex1Dfetch(texreference_input, (blockIdx.x*BLOCKX + threadIdx.x)*inputByte+ DATA_BLOCK_SIZE*k+8) ^ ((uint64_t)tex1Dfetch(texreference_input, (blockIdx.x*BLOCKX + threadIdx.x)*inputByte+ DATA_BLOCK_SIZE*k+9) << 32);

#endif

#if 5 < DATA_BLOCK_SIZE
		// state10 ^= input[(blockIdx.x*BLOCKX + threadIdx.x)*inputByte+ DATA_BLOCK_SIZE*k+5];
		state10 ^= (uint64_t)tex1Dfetch(texreference_input, (blockIdx.x*BLOCKX + threadIdx.x)*inputByte+ DATA_BLOCK_SIZE*k+10) ^ ((uint64_t)tex1Dfetch(texreference_input, (blockIdx.x*BLOCKX + threadIdx.x)*inputByte+ DATA_BLOCK_SIZE*k+11) << 32);

#endif

#if 6 < DATA_BLOCK_SIZE
		// state11 ^= input[(blockIdx.x*BLOCKX + threadIdx.x)*inputByte+ DATA_BLOCK_SIZE*k+6];
		state11 ^= (uint64_t)tex1Dfetch(texreference_input, (blockIdx.x*BLOCKX + threadIdx.x)*inputByte+ DATA_BLOCK_SIZE*k+12) ^ ((uint64_t)tex1Dfetch(texreference_input, (blockIdx.x*BLOCKX + threadIdx.x)*inputByte+ DATA_BLOCK_SIZE*k+13) << 32);

#endif

#if 7 < DATA_BLOCK_SIZE
		// state12 ^= input[(blockIdx.x*BLOCKX + threadIdx.x)*inputByte+ DATA_BLOCK_SIZE*k+7];
		state12 ^= (uint64_t)tex1Dfetch(texreference_input, (blockIdx.x*BLOCKX + threadIdx.x)*inputByte+ DATA_BLOCK_SIZE*k+14) ^ ((uint64_t)tex1Dfetch(texreference_input, (blockIdx.x*BLOCKX + threadIdx.x)*inputByte+ DATA_BLOCK_SIZE*k+15) << 32);

#endif

#if 8 < DATA_BLOCK_SIZE
		// state13 ^= input[(blockIdx.x*BLOCKX + threadIdx.x)*inputByte+ DATA_BLOCK_SIZE*k+8];
		state13 ^= (uint64_t)tex1Dfetch(texreference_input, (blockIdx.x*BLOCKX + threadIdx.x)*inputByte+ DATA_BLOCK_SIZE*k+16) ^ ((uint64_t)tex1Dfetch(texreference_input, (blockIdx.x*BLOCKX + threadIdx.x)*inputByte+ DATA_BLOCK_SIZE*k+17) << 32);

#endif

#if 9 < DATA_BLOCK_SIZE
		// state14 ^= input[(blockIdx.x*BLOCKX + threadIdx.x)*inputByte+ DATA_BLOCK_SIZE*k+9];
		state14 ^= (uint64_t)tex1Dfetch(texreference_input, (blockIdx.x*BLOCKX + threadIdx.x)*inputByte+ DATA_BLOCK_SIZE*k+18) ^ ((uint64_t)tex1Dfetch(texreference_input, (blockIdx.x*BLOCKX + threadIdx.x)*inputByte+ DATA_BLOCK_SIZE*k+19) << 32);

#endif

#if 10 < DATA_BLOCK_SIZE
		// state20 ^= input[(blockIdx.x*BLOCKX + threadIdx.x)*inputByte+ DATA_BLOCK_SIZE*k+10];
		state20 ^= (uint64_t)tex1Dfetch(texreference_input, (blockIdx.x*BLOCKX + threadIdx.x)*inputByte+ DATA_BLOCK_SIZE*k+20) ^ ((uint64_t)tex1Dfetch(texreference_input, (blockIdx.x*BLOCKX + threadIdx.x)*inputByte+ DATA_BLOCK_SIZE*k+21) << 32);

#endif

#if 11 < DATA_BLOCK_SIZE
		// state21 ^= input[(blockIdx.x*BLOCKX + threadIdx.x)*inputByte+ DATA_BLOCK_SIZE*k+11];
		state21 ^= (uint64_t)tex1Dfetch(texreference_input, (blockIdx.x*BLOCKX + threadIdx.x)*inputByte+ DATA_BLOCK_SIZE*k+22) ^ ((uint64_t)tex1Dfetch(texreference_input, (blockIdx.x*BLOCKX + threadIdx.x)*inputByte+ DATA_BLOCK_SIZE*k+23) << 32);

#endif

#if 12 < DATA_BLOCK_SIZE
		// state22 ^= input[(blockIdx.x*BLOCKX + threadIdx.x)*inputByte+ DATA_BLOCK_SIZE*k+12];
		state22 ^= (uint64_t)tex1Dfetch(texreference_input, (blockIdx.x*BLOCKX + threadIdx.x)*inputByte+ DATA_BLOCK_SIZE*k+24) ^ ((uint64_t)tex1Dfetch(texreference_input, (blockIdx.x*BLOCKX + threadIdx.x)*inputByte+ DATA_BLOCK_SIZE*k+25) << 32);

#endif

#if 13 < DATA_BLOCK_SIZE
		// state23 ^= input[(blockIdx.x*BLOCKX + threadIdx.x)*inputByte+ DATA_BLOCK_SIZE*k+13];
		state23 ^= (uint64_t)tex1Dfetch(texreference_input, (blockIdx.x*BLOCKX + threadIdx.x)*inputByte+ DATA_BLOCK_SIZE*k+26) ^ ((uint64_t)tex1Dfetch(texreference_input, (blockIdx.x*BLOCKX + threadIdx.x)*inputByte+ DATA_BLOCK_SIZE*k+27) << 32);

#endif

#if 14 < DATA_BLOCK_SIZE
		// state24 ^= input[(blockIdx.x*BLOCKX + threadIdx.x)*inputByte+ DATA_BLOCK_SIZE*k+14];
		state24 ^= (uint64_t)tex1Dfetch(texreference_input, (blockIdx.x*BLOCKX + threadIdx.x)*inputByte+ DATA_BLOCK_SIZE*k+28) ^ ((uint64_t)tex1Dfetch(texreference_input, (blockIdx.x*BLOCKX + threadIdx.x)*inputByte+ DATA_BLOCK_SIZE*k+29) << 32);

#endif

#if 15 < DATA_BLOCK_SIZE
		// state30 ^= input[(blockIdx.x*BLOCKX + threadIdx.x)*inputByte+ DATA_BLOCK_SIZE*k+15];
		state30 ^= (uint64_t)tex1Dfetch(texreference_input, (blockIdx.x*BLOCKX + threadIdx.x)*inputByte+ DATA_BLOCK_SIZE*k+30) ^ ((uint64_t)tex1Dfetch(texreference_input, (blockIdx.x*BLOCKX + threadIdx.x)*inputByte+ DATA_BLOCK_SIZE*k+31) << 32);

#endif

#if 16 < DATA_BLOCK_SIZE
		// state31 ^= input[(blockIdx.x*BLOCKX + threadIdx.x)*inputByte+ DATA_BLOCK_SIZE*k+16];
		state31 ^= (uint64_t)tex1Dfetch(texreference_input, (blockIdx.x*BLOCKX + threadIdx.x)*inputByte+ DATA_BLOCK_SIZE*k+32) ^ ((uint64_t)tex1Dfetch(texreference_input, (blockIdx.x*BLOCKX + threadIdx.x)*inputByte+ DATA_BLOCK_SIZE*k+33) << 32);

#endif

#if 17 < DATA_BLOCK_SIZE
		// state32 ^= input[(blockIdx.x*BLOCKX + threadIdx.x)*inputByte+ DATA_BLOCK_SIZE*k+17];
		state32 ^= (uint64_t)tex1Dfetch(texreference_input, (blockIdx.x*BLOCKX + threadIdx.x)*inputByte+ DATA_BLOCK_SIZE*k+34) ^ ((uint64_t)tex1Dfetch(texreference_input, (blockIdx.x*BLOCKX + threadIdx.x)*inputByte+ DATA_BLOCK_SIZE*k+35) << 32);

#endif

#if 18 < DATA_BLOCK_SIZE
		// state33 ^= input[(blockIdx.x*BLOCKX + threadIdx.x)*inputByte+ DATA_BLOCK_SIZE*k+18];
		state33 ^= (uint64_t)tex1Dfetch(texreference_input, (blockIdx.x*BLOCKX + threadIdx.x)*inputByte+ DATA_BLOCK_SIZE*k+36) ^ ((uint64_t)tex1Dfetch(texreference_input, (blockIdx.x*BLOCKX + threadIdx.x)*inputByte+ DATA_BLOCK_SIZE*k+37) << 32);

#endif

#if 19 < DATA_BLOCK_SIZE
		// state34 ^= input[(blockIdx.x*BLOCKX + threadIdx.x)*inputByte+ DATA_BLOCK_SIZE*k+19];
		state34 ^= (uint64_t)tex1Dfetch(texreference_input, (blockIdx.x*BLOCKX + threadIdx.x)*inputByte+ DATA_BLOCK_SIZE*k+38) ^ ((uint64_t)tex1Dfetch(texreference_input, (blockIdx.x*BLOCKX + threadIdx.x)*inputByte+ DATA_BLOCK_SIZE*k+39) << 32);

#endif

#if 20 < DATA_BLOCK_SIZE
		// state40 ^= input[(blockIdx.x*BLOCKX + threadIdx.x)*inputByte+ DATA_BLOCK_SIZE*k+20];
		state40 ^= (uint64_t)tex1Dfetch(texreference_input, (blockIdx.x*BLOCKX + threadIdx.x)*inputByte+ DATA_BLOCK_SIZE*k+40) ^ ((uint64_t)tex1Dfetch(texreference_input, (blockIdx.x*BLOCKX + threadIdx.x)*inputByte+ DATA_BLOCK_SIZE*k+41) << 32);

#endif

#if 21 < DATA_BLOCK_SIZE
		// state41 ^= input[(blockIdx.x*BLOCKX + threadIdx.x)*inputByte+ DATA_BLOCK_SIZE*k+21];
		state41 ^= (uint64_t)tex1Dfetch(texreference_input, (blockIdx.x*BLOCKX + threadIdx.x)*inputByte+ DATA_BLOCK_SIZE*k+42) ^ ((uint64_t)tex1Dfetch(texreference_input, (blockIdx.x*BLOCKX + threadIdx.x)*inputByte+ DATA_BLOCK_SIZE*k+43) << 32);

#endif

#if 22 < DATA_BLOCK_SIZE
		// state42 ^= input[(blockIdx.x*BLOCKX + threadIdx.x)*inputByte+ DATA_BLOCK_SIZE*k+22];
		state42 ^= (uint64_t)tex1Dfetch(texreference_input, (blockIdx.x*BLOCKX + threadIdx.x)*inputByte+ DATA_BLOCK_SIZE*k+44) ^ ((uint64_t)tex1Dfetch(texreference_input, (blockIdx.x*BLOCKX + threadIdx.x)*inputByte+ DATA_BLOCK_SIZE*k+45) << 32);

#endif

#if 23 < DATA_BLOCK_SIZE
		// state43 ^= input[(blockIdx.x*BLOCKX + threadIdx.x)*inputByte+ DATA_BLOCK_SIZE*k+23];
		state43 ^= (uint64_t)tex1Dfetch(texreference_input, (blockIdx.x*BLOCKX + threadIdx.x)*inputByte+ DATA_BLOCK_SIZE*k+46) ^ ((uint64_t)tex1Dfetch(texreference_input, (blockIdx.x*BLOCKX + threadIdx.x)*inputByte+ DATA_BLOCK_SIZE*k+47) << 32);

#endif

#if 24 < DATA_BLOCK_SIZE
		// state44 ^= input[(blockIdx.x*BLOCKX + threadIdx.x)*inputByte+ DATA_BLOCK_SIZE*k+24];
		state44 ^= (uint64_t)tex1Dfetch(texreference_input, (blockIdx.x*BLOCKX + threadIdx.x)*inputByte+ DATA_BLOCK_SIZE*k+48) ^ ((uint64_t)tex1Dfetch(texreference_input, (blockIdx.x*BLOCKX + threadIdx.x)*inputByte+ DATA_BLOCK_SIZE*k+49) << 32);
#endif

#pragma unroll 4
		for(int i=0; i<Nr; i++){
			Csum0 = state00 ^ state10 ^ state20 ^ state30 ^ state40;
			Csum1 = state01 ^ state11 ^ state21 ^ state31 ^ state41;
			Csum2 = state02 ^ state12 ^ state22 ^ state32 ^ state42;
			Csum3 = state03 ^ state13 ^ state23 ^ state33 ^ state43;
			Csum4 = state04 ^ state14 ^ state24 ^ state34 ^ state44;
			//
			D0 = Csum4 ^ ROL(Csum1, 1);
			D1 = Csum0 ^ ROL(Csum2, 1);
			D2 = Csum1 ^ ROL(Csum3, 1);
			D3 = Csum2 ^ ROL(Csum4, 1);
			D4 = Csum3 ^ ROL(Csum0, 1);

			state00 ^= D0;
			state01 ^= D1;
			state02 ^= D2;
			state03 ^= D3;
			state04 ^= D4;
			tmpState00 = state00;
			tmpState20 = ROL(state01, 1);
			tmpState40 = ROL(state02, 62);
			tmpState10 = ROL(state03, 28);
			tmpState30 = ROL(state04, 27);

			state10 ^= D0;
			state11 ^= D1;
			state12 ^= D2;
			state13 ^= D3;
			state14 ^= D4;

			tmpState31 = ROL(state10, 36);
			tmpState01 = ROL(state11, 44);
			tmpState21 = ROL(state12, 6);
			tmpState41 = ROL(state13, 55);
			tmpState11 = ROL(state14, 20);

			state20 ^= D0;
			state21 ^= D1;
			state22 ^= D2;
			state23 ^= D3;
			state24 ^= D4;

			tmpState12 = ROL(state20, 3);
			tmpState32 = ROL(state21, 10);
			tmpState02 = ROL(state22, 43);
			tmpState22 = ROL(state23, 25);
			tmpState42 = ROL(state24, 39);

			state30 ^= D0;
			state31 ^= D1;
			state32 ^= D2;
			state33 ^= D3;
			state34 ^= D4;

			tmpState43 = ROL(state30, 41);
			tmpState13 = ROL(state31, 45);
			tmpState33 = ROL(state32, 15);
			tmpState03 = ROL(state33, 21);
			tmpState23 = ROL(state34, 8);

			state40 ^= D0;
			state41 ^= D1;
			state42 ^= D2;
			state43 ^= D3;
			state44 ^= D4;

			//
			tmpState24 = ROL(state40, 18);
			tmpState44 = ROL(state41, 2);
			tmpState14 = ROL(state42, 61);
			tmpState34 = ROL(state43, 56);
			tmpState04 = ROL(state44, 14);


			//
			state00 = tmpState00 ^ ((~tmpState01) & tmpState02);
			state10 = tmpState10 ^ ((~tmpState11) & tmpState12);
			state20 = tmpState20 ^ ((~tmpState21) & tmpState22);
			state30 = tmpState30 ^ ((~tmpState31) & tmpState32);
			state40 = tmpState40 ^ ((~tmpState41) & tmpState42);

			state01 = tmpState01 ^ ((~tmpState02) & tmpState03);
			state11 = tmpState11 ^ ((~tmpState12) & tmpState13);
			state21 = tmpState21 ^ ((~tmpState22) & tmpState23);
			state31 = tmpState31 ^ ((~tmpState32) & tmpState33);
			state41 = tmpState41 ^ ((~tmpState42) & tmpState43);

			state02 = tmpState02 ^ ((~tmpState03) & tmpState04);
			state12 = tmpState12 ^ ((~tmpState13) & tmpState14);
			state22 = tmpState22 ^ ((~tmpState23) & tmpState24);
			state32 = tmpState32 ^ ((~tmpState33) & tmpState34);
			state42 = tmpState42 ^ ((~tmpState43) & tmpState44);

			state03 = tmpState03 ^ ((~tmpState04) & tmpState00);
			state13 = tmpState13 ^ ((~tmpState14) & tmpState10);
			state23 = tmpState23 ^ ((~tmpState24) & tmpState20);
			state33 = tmpState33 ^ ((~tmpState34) & tmpState30);
			state43 = tmpState43 ^ ((~tmpState44) & tmpState40);

			state04 = tmpState04 ^ ((~tmpState00) & tmpState01);
			state14 = tmpState14 ^ ((~tmpState10) & tmpState11);
			state24 = tmpState24 ^ ((~tmpState20) & tmpState21);
			state34 = tmpState34 ^ ((~tmpState30) & tmpState31);
			state44 = tmpState44 ^ ((~tmpState40) & tmpState41);

			state00 ^= RC[i];

		}

	}


	//squeezing phase;
#if 0 < HASH_SIZE
	memcpy(output+(blockIdx.x*BLOCKX + threadIdx.x)*HASH_SIZE, &state00, 8);
#endif

#if 8 < HASH_SIZE
	memcpy(output+(blockIdx.x*BLOCKX + threadIdx.x)*HASH_SIZE+8, &state01, 8);
#endif

#if 16 < HASH_SIZE
	memcpy(output+(blockIdx.x*BLOCKX + threadIdx.x)*HASH_SIZE+16, &state02, 8);
#endif

#if 24 < HASH_SIZE
	memcpy(output+(blockIdx.x*BLOCKX + threadIdx.x)*HASH_SIZE+24, &state03, 8);
#endif

#if 32 < HASH_SIZE
	memcpy(output+(blockIdx.x*BLOCKX + threadIdx.x)*HASH_SIZE+32, &state04, 8);
#endif
}

int Padding(uint8_t input[], int inputByte, uint8_t output[]){
	int outputByte = R/8 -(inputByte+1)%(R/8) + inputByte+1;
	memcpy(output, input, inputByte);
	memset(output+inputByte, 0, sizeof(uint8_t)*(outputByte-inputByte));
	output[inputByte] = SUFFIX;
	output[outputByte-1] ^= 0x80;
	return outputByte;
}

//byte
#define BLOCKSIZE (DATA_BLOCK_SIZE*8)
#define SUMDATASIZE (BLOCKSIZE*BLOCKNUM*BLOCKX)
uint8_t m[] = {0x22, 0x23, 0x3E, 0x5F, 0xCC, 0x4E, 0xFC, 0x0E, 0xEB, 0x03, 0x0C, 0x72, 0xF9, 0x7A, 0x4E, 0x8A, 0x9D, 0xC4, 0xBB, 0x96, 0x18, 0x33, 0xDA, 0xE8, 0xEF, 0xED, 0xCF, 0xFD, 0xE2, 0xA3, 0xC0, 0x37, 0x00, 0x69, 0xCE, 0x65, 0xB3, 0x32, 0x38, 0xAC, 0x43, 0xD6, 0x47, 0x64, 0xFB, 0xDA, 0xDE, 0xDC, 0x6A, 0x22, 0xA3, 0x0C, 0x15, 0xCC, 0x01, 0x0D, 0x7F, 0xC3, 0xA4, 0x45, 0xE3, 0x5E, 0xDA, 0xB7, 0x69, 0x29, 0xD0, 0xAB, 0x6C, 0x48, 0x35, 0xF2, 0x1F, 0xA7, 0x2D, 0x20, 0xC3, 0x3E, 0x5F, 0xCC, 0x4E, 0xFC, 0x0E, 0xEB, 0x03, 0x0C, 0x72, 0xF9, 0x7A, 0x4E, 0x8A, 0x9D, 0xC4, 0xBB, 0x96, 0x18, 0x33, 0xDA, 0xE8, 0xEF, 0xED, 0xCF, 0xFD, 0xE2, 0xA3, 0xC0, 0x37, 0x00, 0x69, 0xCE, 0x65, 0xB3, 0x32, 0x38, 0xAC, 0x43, 0xD6, 0x47, 0x64, 0xFB, 0xDA, 0xDE, 0xDC};
uint8_t output[BLOCKNUM*BLOCKX][HASH_SIZE];
uint8_t input[BLOCKSIZE];
uint8_t host_input[SUMDATASIZE];

#define STREAMNUM 5
cudaStream_t stream[STREAMNUM];
uint32_t *device_input[STREAMNUM];
uint8_t *device_output[STREAMNUM];

void init(){
	Padding(m, sizeof(m), input);
	for(int i=0; i<STREAMNUM; i++){
		cudaStreamCreate(&stream[i]);
	}
	checkCUDAError("create stream error");
	for(int i=0; i<BLOCKX*BLOCKNUM; i++){
		memcpy(host_input + i*BLOCKSIZE, input, BLOCKSIZE);
	}
}

void GetCudaMalloc(int length){
	for(int i=0; i<STREAMNUM; i++){
		cudaMalloc(&device_input[i], BLOCKNUM*BLOCKX*BLOCKSIZE);
		checkCUDAError("malloc for device_input");
		cudaMalloc(&device_output[i], BLOCKX*BLOCKNUM*HASH_SIZE);
		checkCUDAError("malloc for device_output");
	}

}

void FreeAll(){
	for(int i=0; i<STREAMNUM; i++){
		cudaStreamDestroy(stream[i]);
		cudaFree(&device_input[i]);
		cudaFree(&device_output[i]);
	}

}

#define TESTROUND 100

int main(){
	init();
	GetCudaMalloc(BLOCKSIZE);

	timeval tpstart, tpend;
	double timeuse;
	printf("CUDA start\n");
	int cur = 0;
	gettimeofday(&tpstart, NULL);
	double all_sec = 0;

	for(int i=0; i<TESTROUND; i++){
		cudaMemcpyAsync(device_input[cur], host_input, SUMDATASIZE, cudaMemcpyHostToDevice, stream[cur]);
		checkCUDAError("memcpy from buf to device_input");
		cudaBindTexture(0,texreference_input, device_input[cur], SUMDATASIZE);

		cudaEvent_t start, stop;
		float elapsedTime = 0.0;

		cudaEventCreate(&start);
		cudaEventCreate(&stop);
		cudaEventRecord(start, 0);

		Keccak1600<<<BLOCKNUM, BLOCKX, 0, stream[cur]>>>(BLOCKSIZE/4, device_output[cur], HASH_SIZE);
		cudaDeviceSynchronize();

		cudaEventRecord(stop, 0);
		cudaEventSynchronize(stop);

		cudaEventElapsedTime(&elapsedTime, start, stop);

		cout << elapsedTime << endl;
		if(i != 0) // first time to call kernel will cost more second
			all_sec += elapsedTime;
		cudaEventDestroy(start);
		cudaEventDestroy(stop);	
		cudaMemcpyAsync(output, device_output[cur], HASH_SIZE*BLOCKNUM*BLOCKX, cudaMemcpyDeviceToHost, stream[cur]);
		cur = (cur + 1) % STREAMNUM;
		cudaUnbindTexture(&texreference_input);
	}
	cudaDeviceSynchronize();
	gettimeofday(&tpend, NULL);
	timeuse = all_sec*1000; //1000000*(tpend.tv_sec-tpstart.tv_sec) + tpend.tv_usec-tpstart.tv_usec;
	printf("used time: %f s\n", timeuse/1000000);
	printf("blockpersecond 2^%.5f\n", log2(BLOCKNUM*BLOCKX*(TESTROUND-1)/(timeuse/1000000)));
	printf("total block: %d\n", BLOCKNUM*BLOCKX*(TESTROUND-1));
	checkCUDAError("kernel invocation");

	FreeAll();
	printf("END\n");
	cout << sizeof(output) << endl;
	for(int d=0; d<1; d++){
		printf("block %d:\n", d);
		for(int j=0; j<HASH_SIZE; j++){
			printf(" %02X", output[d][j]);
		}
		printf("\n");
	}


	return 0;
}
