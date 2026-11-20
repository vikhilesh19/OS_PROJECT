#include <stdio.h>
#include <stdlib.h>
#include <cuda_runtime.h>

void check(cudaError_t error) {
    if (error != cudaSuccess) {
        printf("CUDA Error: %s\n", cudaGetErrorString(error));
        exit(1);
    }
}

__global__ void add(int *a, int *b, int *c) {
    int i = threadIdx.x;
    if (i < 10)
        c[i] = a[i] + b[i];
}

int main() {
    int a[10], b[10], c[10];
    int *d_a, *d_b, *d_c;
    int count;

    check(cudaGetDeviceCount(&count));
    if (count == 0) {
        printf("No CUDA GPU found\n");
        return 1;
    }

    for (int i = 0; i < 10; i++) {
        a[i] = i;
        b[i] = i * 10;
    }

    check(cudaMalloc((void **)&d_a, sizeof(a)));
    check(cudaMalloc((void **)&d_b, sizeof(b)));
    check(cudaMalloc((void **)&d_c, sizeof(c)));

    check(cudaMemcpy(d_a, a, sizeof(a), cudaMemcpyHostToDevice));
    check(cudaMemcpy(d_b, b, sizeof(b), cudaMemcpyHostToDevice));

    add<<<1, 32>>>(d_a, d_b, d_c);

    check(cudaGetLastError());
    check(cudaDeviceSynchronize());

    check(cudaMemcpy(c, d_c, sizeof(c), cudaMemcpyDeviceToHost));

    printf("GPU Vector Addition Results:\n");

    for (int i = 0; i < 10; i++) {
        printf("%d + %d = %d\n", a[i], b[i], c[i]);
        if (c[i] != a[i] + b[i])
            return 1;
    }

    check(cudaFree(d_a));
    check(cudaFree(d_b));
    check(cudaFree(d_c));

    printf("CUDA GPU TEST PASSED!\n");
    return 0;
}
