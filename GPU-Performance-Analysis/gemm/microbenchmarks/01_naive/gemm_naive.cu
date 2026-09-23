#include <cuda_runtime.h>
#include <cstdio>
#include <cstdlib>
#include <cmath>
#define CK(x) do{cudaError_t e=(x);if(e!=cudaSuccess){fprintf(stderr,"%s\n",cudaGetErrorString(e));exit(1);}}while(0)
__global__ void gemm_naive(const float* __restrict__ A,const float* __restrict__ B,float* __restrict__ C,int M,int N,int K){
 int col=blockIdx.x*blockDim.x+threadIdx.x,row=blockIdx.y*blockDim.y+threadIdx.y;
 if(row<M&&col<N){float sum=0;for(int k=0;k<K;k++)sum=fmaf(A[(size_t)row*K+k],B[(size_t)k*N+col],sum);C[(size_t)row*N+col]=sum;}
}
int main(int argc,char**argv){int M=argc>1?atoi(argv[1]):4096,N=argc>2?atoi(argv[2]):4096,K=argc>3?atoi(argv[3]):4096;
 size_t ab=(size_t)M*K*4,bb=(size_t)K*N*4,cb=(size_t)M*N*4;float *A,*B,*C;CK(cudaMalloc(&A,ab));CK(cudaMalloc(&B,bb));CK(cudaMalloc(&C,cb));CK(cudaMemset(A,0,ab));CK(cudaMemset(B,0,bb));
 dim3 block(16,16),grid((N+15)/16,(M+15)/16);gemm_naive<<<grid,block>>>(A,B,C,M,N,K);CK(cudaDeviceSynchronize());
 cudaEvent_t s,e;CK(cudaEventCreate(&s));CK(cudaEventCreate(&e));CK(cudaEventRecord(s));gemm_naive<<<grid,block>>>(A,B,C,M,N,K);CK(cudaEventRecord(e));CK(cudaEventSynchronize(e));float ms;CK(cudaEventElapsedTime(&ms,s,e));
 double flops=2.0*M*N*K;printf("GEMM naive M=%d N=%d K=%d block=16x16\nKernel time: %.3f ms\nPerformance: %.2f GFLOP/s\n",M,N,K,ms,flops/(ms/1000.0)/1e9);cudaFree(A);cudaFree(B);cudaFree(C);}
