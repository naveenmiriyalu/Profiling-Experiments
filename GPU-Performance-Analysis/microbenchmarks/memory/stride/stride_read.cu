#include <cuda_runtime.h>

#include <cstdio>
#include <cstdlib>

#define CUDA_CHECK(call)                                                   \
do {                                                                       \
    cudaError_t err = (call);                                              \
    if (err != cudaSuccess) {                                              \
        fprintf(stderr, "CUDA error at %s:%d: %s\n",                      \
                __FILE__, __LINE__, cudaGetErrorString(err));              \
        std::exit(EXIT_FAILURE);                                           \
    }                                                                      \
} while (0)

__global__ void stride_read(
    const float* __restrict__ in,
    float* __restrict__ out,
    size_t n,
    int stride)
{
    size_t i =
        static_cast<size_t>(blockIdx.x) * blockDim.x
        + threadIdx.x;

    if (i < n) {
        out[i] = in[i * stride];
    }
}

int main()
{
    const size_t N = 100'000'000;
    const int stride = 1;

    const size_t input_elements = N * stride;
    const size_t input_bytes = input_elements * sizeof(float);
    const size_t output_bytes = N * sizeof(float);

    printf("N               : %zu\n", N);
    printf("stride          : %d\n", stride);
    printf("input size      : %.2f MB\n", input_bytes / 1.0e6);
    printf("output size     : %.2f MB\n", output_bytes / 1.0e6);

    float* d_in = nullptr;
    float* d_out = nullptr;

    CUDA_CHECK(cudaMalloc(&d_in, input_bytes));
    CUDA_CHECK(cudaMalloc(&d_out, output_bytes));
    CUDA_CHECK(cudaMemset(d_in, 0, input_bytes));
    CUDA_CHECK(cudaMemset(d_out, 0, output_bytes));

    const int threads_per_block = 256;
    const size_t blocks =
        (N + threads_per_block - 1) / threads_per_block;

    printf("threads/block   : %d\n", threads_per_block);
    printf("blocks          : %zu\n", blocks);

    stride_read<<<blocks, threads_per_block>>>(d_in, d_out, N, stride);
    CUDA_CHECK(cudaGetLastError());
    CUDA_CHECK(cudaDeviceSynchronize());

    cudaEvent_t start;
    cudaEvent_t stop;
    CUDA_CHECK(cudaEventCreate(&start));
    CUDA_CHECK(cudaEventCreate(&stop));

    CUDA_CHECK(cudaEventRecord(start));
    stride_read<<<blocks, threads_per_block>>>(d_in, d_out, N, stride);
    CUDA_CHECK(cudaGetLastError());
    CUDA_CHECK(cudaEventRecord(stop));
    CUDA_CHECK(cudaEventSynchronize(stop));

    float elapsed_ms = 0.0f;
    CUDA_CHECK(cudaEventElapsedTime(&elapsed_ms, start, stop));

    // Application-level useful traffic: one 4-B read + one 4-B write.
    // This is not necessarily equal to L1/L2/HBM traffic.
    const double useful_bytes =
        static_cast<double>(N) * 2.0 * sizeof(float);
    const double elapsed_seconds = elapsed_ms / 1000.0;
    const double useful_GBs =
        useful_bytes / elapsed_seconds / 1.0e9;

    printf("\n");
    printf("Kernel time     : %.3f ms\n", elapsed_ms);
    printf("Useful traffic  : %.3f GB\n", useful_bytes / 1.0e9);
    printf("Useful bandwidth: %.2f GB/s\n", useful_GBs);

    CUDA_CHECK(cudaEventDestroy(start));
    CUDA_CHECK(cudaEventDestroy(stop));
    CUDA_CHECK(cudaFree(d_in));
    CUDA_CHECK(cudaFree(d_out));

    return 0;
}
