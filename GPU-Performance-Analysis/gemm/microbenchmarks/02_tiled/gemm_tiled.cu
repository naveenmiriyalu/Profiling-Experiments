#include <cuda_runtime.h>
#include <cstdio>
#include <cstdlib>
#include <cmath>
#define CK(x) do{cudaError_t e=(x);if(e!=cudaSuccess){fprintf(stderr,"%s\n",cudaGetErrorString(e));exit(1);}}while(0)
constexpr int TILE=16;
__global__ void gemm_tiled(const float* __restrict__ A,const float* __restrict__ B,float* __restrict__ C,int M,int N,int K){
 __shared__ float As[TILE][TILE],Bs[TILE][TILE];int tx=threadIdx.x,ty=threadIdx.y,col=blockIdx.x*TILE+tx,row=blockIdx.y*TILE+ty;float sum=0;
 for(int t=0;t<(K+TILE-1)/TILE;t++){int ak=t*TILE+tx,bk=t*TILE+ty;As[ty][tx]=(row<M&&ak<K)?A[(size_t)row*K+ak]:0;Bs[ty][tx]=(bk<K&&col<N)?B[(size_t)bk*N+col]:0;__syncthreads();
 #pragma unroll
 for(int k=0;k<TILE;k++)sum=fmaf(As[ty][k],Bs[k][tx],sum);__syncthreads();}
 if(row<M&&col<N)C[(size_t)row*N+col]=sum;
}
int main(int argc,char**argv){int M=argc>1?atoi(argv[1]):4096,N=argc>2?atoi(argv[2]):4096,K=argc>3?atoi(argv[3]):4096;size_t ab=(size_t)M*K*4,bb=(size_t)K*N*4,cb=(size_t)M*N*4;float *A,*B,*C;CK(cudaMalloc(&A,ab));CK(cudaMalloc(&B,bb));CK(cudaMalloc(&C,cb));CK(cudaMemset(A,0,ab));CK(cudaMemset(B,0,bb));dim3 block(TILE,TILE),grid((N+TILE-1)/TILE,(M+TILE-1)/TILE);gemm_tiled<<<grid,block>>>(A,B,C,M,N,K);CK(cudaDeviceSynchronize());cudaEvent_t s,e;CK(cudaEventCreate(&s));CK(cudaEventCreate(&e));CK(cudaEventRecord(s));gemm_tiled<<<grid,block>>>(A,B,C,M,N,K);CK(cudaEventRecord(e));CK(cudaEventSynchronize(e));float ms;CK(cudaEventElapsedTime(&ms,s,e));double flops=2.0*M*N*K;printf("GEMM tiled M=%d N=%d K=%d TILE=%d\nKernel time: %.3f ms\nPerformance: %.2f GFLOP/s\n",M,N,K,TILE,ms,flops/(ms/1000.0)/1e9);cudaFree(A);cudaFree(B);cudaFree(C);}
