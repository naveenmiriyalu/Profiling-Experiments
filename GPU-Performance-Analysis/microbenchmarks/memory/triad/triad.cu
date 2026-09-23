#include <cuda_runtime.h>
#include <cstdio>
#include <cstdlib>
#define CUDA_CHECK(call) do { cudaError_t err=(call); if(err!=cudaSuccess){ fprintf(stderr,"CUDA error at %s:%d: %s\n",__FILE__,__LINE__,cudaGetErrorString(err)); std::exit(EXIT_FAILURE);} } while(0)

__global__ void triad(float* __restrict__ a,const float* __restrict__ b,const float* __restrict__ c,size_t n,float scalar) {
    size_t i=static_cast<size_t>(blockIdx.x)*blockDim.x+threadIdx.x;
    if(i<n) a[i]=b[i]+scalar*c[i];
}

int main() {
    const size_t N=100'000'000;
    const float scalar=3.0f;
    const size_t bytes=N*sizeof(float);
    printf("N               : %zu\n",N);
    printf("array size      : %.2f MB each\n",bytes/1.0e6);
    printf("scalar          : %.2f\n",scalar);
    float *d_a=nullptr,*d_b=nullptr,*d_c=nullptr;
    CUDA_CHECK(cudaMalloc(&d_a,bytes)); CUDA_CHECK(cudaMalloc(&d_b,bytes)); CUDA_CHECK(cudaMalloc(&d_c,bytes));
    CUDA_CHECK(cudaMemset(d_a,0,bytes)); CUDA_CHECK(cudaMemset(d_b,0,bytes)); CUDA_CHECK(cudaMemset(d_c,0,bytes));
    const int threads_per_block=256;
    const size_t blocks=(N+threads_per_block-1)/threads_per_block;
    printf("threads/block   : %d\n",threads_per_block);
    printf("blocks          : %zu\n",blocks);
    triad<<<blocks,threads_per_block>>>(d_a,d_b,d_c,N,scalar);
    CUDA_CHECK(cudaGetLastError()); CUDA_CHECK(cudaDeviceSynchronize());
    cudaEvent_t start,stop;
    CUDA_CHECK(cudaEventCreate(&start)); CUDA_CHECK(cudaEventCreate(&stop));
    CUDA_CHECK(cudaEventRecord(start));
    triad<<<blocks,threads_per_block>>>(d_a,d_b,d_c,N,scalar);
    CUDA_CHECK(cudaGetLastError());
    CUDA_CHECK(cudaEventRecord(stop)); CUDA_CHECK(cudaEventSynchronize(stop));
    float elapsed_ms=0.0f;
    CUDA_CHECK(cudaEventElapsedTime(&elapsed_ms,start,stop));
    const double useful_bytes=static_cast<double>(N)*3.0*sizeof(float);
    const double useful_GBs=useful_bytes/(elapsed_ms/1000.0)/1.0e9;
    printf("\nKernel time     : %.3f ms\n",elapsed_ms);
    printf("Useful traffic  : %.3f GB\n",useful_bytes/1.0e9);
    printf("Useful bandwidth: %.2f GB/s\n",useful_GBs);
    CUDA_CHECK(cudaEventDestroy(start)); CUDA_CHECK(cudaEventDestroy(stop));
    CUDA_CHECK(cudaFree(d_a)); CUDA_CHECK(cudaFree(d_b)); CUDA_CHECK(cudaFree(d_c));
    return 0;
}
