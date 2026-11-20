
#include <stdio.h>
#include <stdlib.h>
#include <chrono>
#include <cuda_runtime.h>

#define N 10000000

#define CHECK(call) do { \
    cudaError_t err = (call); \
    if (err != cudaSuccess) { \
        printf("CUDA Error: %s\n", cudaGetErrorString(err)); \
        exit(1); \
    } \
} while (0)

__global__ void vectorAdd(float *a, float *b, float *c, int n) {
    int i = blockIdx.x * blockDim.x + threadIdx.x;
    if (i < n)
        c[i] = a[i] + b[i];
}

int main() {
    size_t size = N * sizeof(float);

    float *a = (float *)malloc(size);
    float *b = (float *)malloc(size);
    float *cpu = (float *)malloc(size);
    float *gpu = (float *)malloc(size);

    if (!a || !b || !cpu || !gpu) {
        printf("Host memory allocation failed\n");
        return 1;
    }

    for (int i = 0; i < N; i++) {
        a[i] = i % 100;
        b[i] = i % 50;
    }

    auto cpuStart = std::chrono::steady_clock::now();

    for (int i = 0; i < N; i++)
        cpu[i] = a[i] + b[i];

    auto cpuEnd = std::chrono::steady_clock::now();

    float *d_a, *d_b, *d_c;

    CHECK(cudaMalloc((void **)&d_a, size));
    CHECK(cudaMalloc((void **)&d_b, size));
    CHECK(cudaMalloc((void **)&d_c, size));

    cudaEvent_t start, stop;
    CHECK(cudaEventCreate(&start));
    CHECK(cudaEventCreate(&stop));

    auto gpuStart = std::chrono::steady_clock::now();

    CHECK(cudaMemcpy(d_a, a, size, cudaMemcpyHostToDevice));
    CHECK(cudaMemcpy(d_b, b, size, cudaMemcpyHostToDevice));

    int threads = 256;
    int blocks = (N + threads - 1) / threads;

    CHECK(cudaEventRecord(start));
    vectorAdd<<<blocks, threads>>>(d_a, d_b, d_c, N);
    CHECK(cudaGetLastError());
    CHECK(cudaEventRecord(stop));
    CHECK(cudaEventSynchronize(stop));

    float kernelMs = 0;
    CHECK(cudaEventElapsedTime(&kernelMs, start, stop));

    CHECK(cudaMemcpy(gpu, d_c, size, cudaMemcpyDeviceToHost));

    auto gpuEnd = std::chrono::steady_clock::now();

    int correct = 1;
    for (int i = 0; i < N; i++) {
        if (cpu[i] != gpu[i]) {
            correct = 0;
            break;
        }
    }

    double cpuMs =
        std::chrono::duration<double, std::milli>(
            cpuEnd - cpuStart).count();

    double gpuMs =
        std::chrono::duration<double, std::milli>(
            gpuEnd - gpuStart).count();

    printf("\n===== CUDA BENCHMARK =====\n");
    printf("Elements: %d\n", N);
    printf("CPU time: %.3f ms\n", cpuMs);
    printf("GPU kernel time: %.3f ms\n", kernelMs);
    printf("GPU total time: %.3f ms\n", gpuMs);
    printf("CPU/GPU total time ratio: %.2fx\n", cpuMs / gpuMs);
    printf("Verification: %s\n", correct ? "PASSED" : "FAILED");

    CHECK(cudaEventDestroy(start));
    CHECK(cudaEventDestroy(stop));

    CHECK(cudaFree(d_a));
    CHECK(cudaFree(d_b));
    CHECK(cudaFree(d_c));

    free(a);
    free(b);
    free(cpu);
    free(gpu);

    return correct ? 0 : 1;
}

