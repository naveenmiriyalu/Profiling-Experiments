#include <cuda_runtime.h>
#include <cstdio>
#include <cstdlib>

#define CUDA_CHECK(call) do {                                              \
    cudaError_t err = (call);                                              \
    if (err != cudaSuccess) {                                              \
        fprintf(stderr, "CUDA error at %s:%d: %s\n",                       \
                __FILE__, __LINE__, cudaGetErrorString(err));              \
        std::exit(EXIT_FAILURE);                                           \
    }                                                                      \
} while (0)

template<int LOADS>
__global__ void mlp_copy(
    const float* __restrict__ in,
    float* __restrict__ out,
    size_t elements_per_stream)
{
    size_t i = static_cast<size_t>(blockIdx.x) * blockDim.x + threadIdx.x;
    if (i >= elements_per_stream) return;

    // Each stream is contiguous across lanes, but streams are disjoint.
    // LOADS therefore controls the number of independent global loads
    // available to a thread/warp before their values are consumed.
    float x[LOADS];

    #pragma unroll
    for (int k = 0; k < LOADS; ++k) {
        x[k] = in[static_cast<size_t>(k) * elements_per_stream + i];
    }

    #pragma unroll
    for (int k = 0; k < LOADS; ++k) {
        out[static_cast<size_t>(k) * elements_per_stream + i] = x[k];
    }
}

template<int LOADS>
static void run_case(size_t total_elements)
{
    // Keep total useful bytes approximately constant across LOADS=1/2/4/8.
    const size_t elements_per_stream = total_elements / LOADS;
    const size_t active_elements = elements_per_stream * LOADS;
    const size_t bytes = active_elements * sizeof(float);

    float *d_in = nullptr, *d_out = nullptr;
    CUDA_CHECK(cudaMalloc(&d_in, bytes));
    CUDA_CHECK(cudaMalloc(&d_out, bytes));
    CUDA_CHECK(cudaMemset(d_in, 0, bytes));
    CUDA_CHECK(cudaMemset(d_out, 0, bytes));

    const int threads_per_block = 256;
    const size_t blocks =
        (elements_per_stream + threads_per_block - 1) / threads_per_block;

    printf("MLP loads/thread : %d\n", LOADS);
    printf("active elements  : %zu\n", active_elements);
    printf("elements/stream  : %zu\n", elements_per_stream);
    printf("array size       : %.2f MB each\n", bytes / 1.0e6);
    printf("threads/block    : %d\n", threads_per_block);
    printf("blocks           : %zu\n", blocks);

    // Warm-up.
    mlp_copy<LOADS><<<blocks, threads_per_block>>>(
        d_in, d_out, elements_per_stream);
    CUDA_CHECK(cudaGetLastError());
    CUDA_CHECK(cudaDeviceSynchronize());

    cudaEvent_t start, stop;
    CUDA_CHECK(cudaEventCreate(&start));
    CUDA_CHECK(cudaEventCreate(&stop));

    CUDA_CHECK(cudaEventRecord(start));
    mlp_copy<LOADS><<<blocks, threads_per_block>>>(
        d_in, d_out, elements_per_stream);
    CUDA_CHECK(cudaGetLastError());
    CUDA_CHECK(cudaEventRecord(stop));
    CUDA_CHECK(cudaEventSynchronize(stop));

    float elapsed_ms = 0.0f;
    CUDA_CHECK(cudaEventElapsedTime(&elapsed_ms, start, stop));

    // One 4-B read + one 4-B write for every active element.
    const double useful_bytes =
        static_cast<double>(active_elements) * 2.0 * sizeof(float);
    const double useful_GBs =
        useful_bytes / (elapsed_ms / 1000.0) / 1.0e9;

    printf("Kernel time      : %.3f ms\n", elapsed_ms);
    printf("Useful traffic   : %.3f GB\n", useful_bytes / 1.0e9);
    printf("Useful bandwidth : %.2f GB/s\n", useful_GBs);

    CUDA_CHECK(cudaEventDestroy(start));
    CUDA_CHECK(cudaEventDestroy(stop));
    CUDA_CHECK(cudaFree(d_in));
    CUDA_CHECK(cudaFree(d_out));
}

int main(int argc, char** argv)
{
    int loads = (argc > 1) ? std::atoi(argv[1]) : 1;
    const size_t TOTAL_ELEMENTS = 100'000'000;

    switch (loads) {
        case 1: run_case<1>(TOTAL_ELEMENTS); break;
        case 2: run_case<2>(TOTAL_ELEMENTS); break;
        case 4: run_case<4>(TOTAL_ELEMENTS); break;
        case 8: run_case<8>(TOTAL_ELEMENTS); break;
        default:
            fprintf(stderr, "Usage: %s {1|2|4|8}\n", argv[0]);
            return EXIT_FAILURE;
    }
    return 0;
}
