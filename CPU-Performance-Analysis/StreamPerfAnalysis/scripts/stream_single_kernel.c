// STREAM-like single-kernel benchmark for correlating useful bandwidth with PCM.
// Build: gcc -O3 -march=native -fopenmp stream_single_kernel.c -o stream_single_kernel
// Run:   ./stream_single_kernel copy|scale|add|triad [iterations] [array_elements]

#define _POSIX_C_SOURCE 200112L
#include <errno.h>
#include <omp.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

static void usage(const char *program)
{
    fprintf(stderr,
            "Usage: %s copy|scale|add|triad [iterations] [array_elements]\n",
            program);
}

int main(int argc, char **argv)
{
    if (argc < 2 || argc > 4) {
        usage(argv[0]);
        return EXIT_FAILURE;
    }

    const char *kernel = argv[1];
    const int iterations = argc >= 3 ? atoi(argv[2]) : 200;
    const size_t elements =
        argc >= 4 ? (size_t)strtoull(argv[3], NULL, 10) : 100000000ULL;
    const double scalar = 3.0;

    if (iterations <= 0 || elements == 0) {
        fprintf(stderr, "Iterations and array elements must be positive.\n");
        return EXIT_FAILURE;
    }

    const int is_copy = strcmp(kernel, "copy") == 0;
    const int is_scale = strcmp(kernel, "scale") == 0;
    const int is_add = strcmp(kernel, "add") == 0;
    const int is_triad = strcmp(kernel, "triad") == 0;

    if (!is_copy && !is_scale && !is_add && !is_triad) {
        usage(argv[0]);
        return EXIT_FAILURE;
    }

    const size_t bytes = elements * sizeof(double);
    double *a = NULL;
    double *b = NULL;
    double *c = NULL;

    if (posix_memalign((void **)&a, 64, bytes) != 0 ||
        posix_memalign((void **)&b, 64, bytes) != 0 ||
        posix_memalign((void **)&c, 64, bytes) != 0) {
        fprintf(stderr, "Allocation failed for three arrays of %.2f GiB each.\n",
                (double)bytes / (1024.0 * 1024.0 * 1024.0));
        free(a);
        free(b);
        free(c);
        return EXIT_FAILURE;
    }

#pragma omp parallel for schedule(static)
    for (size_t i = 0; i < elements; ++i) {
        a[i] = 1.0;
        b[i] = 2.0;
        c[i] = 0.0;
    }

    // Keep initialization outside the timed region.
    const double start = omp_get_wtime();

    for (int iteration = 0; iteration < iterations; ++iteration) {
        if (is_copy) {
#pragma omp parallel for schedule(static)
            for (size_t i = 0; i < elements; ++i)
                c[i] = a[i];
        } else if (is_scale) {
#pragma omp parallel for schedule(static)
            for (size_t i = 0; i < elements; ++i)
                b[i] = scalar * c[i];
        } else if (is_add) {
#pragma omp parallel for schedule(static)
            for (size_t i = 0; i < elements; ++i)
                c[i] = a[i] + b[i];
        } else {
#pragma omp parallel for schedule(static)
            for (size_t i = 0; i < elements; ++i)
                a[i] = b[i] + scalar * c[i];
        }
    }

    const double seconds = omp_get_wtime() - start;
    const double useful_bytes_per_element =
        (is_copy || is_scale) ? 16.0 : 24.0;
    const double useful_gb =
        useful_bytes_per_element * (double)elements * (double)iterations / 1.0e9;

    // Consume output so the compiler must preserve the stores.
    volatile double checksum =
        is_scale ? b[elements / 2] :
        (is_copy || is_add) ? c[elements / 2] : a[elements / 2];

    printf("Kernel             : %s\n", kernel);
    printf("Threads            : %d\n", omp_get_max_threads());
    printf("Iterations         : %d\n", iterations);
    printf("Elements per array : %zu\n", elements);
    printf("Array size         : %.3f GiB\n",
           (double)bytes / (1024.0 * 1024.0 * 1024.0));
    printf("Elapsed time       : %.6f s\n", seconds);
    printf("Useful bandwidth   : %.3f GB/s\n", useful_gb / seconds);
    printf("Checksum           : %.6f\n", checksum);

    free(a);
    free(b);
    free(c);
    return EXIT_SUCCESS;
}
