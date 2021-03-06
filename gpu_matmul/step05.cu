#include <cmath>
#include <cstdlib>
#include <cstdio>
#include <sys/time.h>

#define M 1024

double get_time() {
  struct timeval tv;
  gettimeofday(&tv, NULL);
  return double(tv.tv_sec)+double(tv.tv_usec)*1e-6;
}

__global__ void matmul(float *A, float *B, float *C, int N) {
  int i = blockIdx.y;
  int j = threadIdx.x + blockDim.x * blockIdx.x;
  float sum = 0.0f;
  __shared__ float s_A[M];
  for (int ks=0; ks<N; ks+=M) {
    __syncthreads();
    s_A[threadIdx.x] = A[N*i+ks+threadIdx.x];
    __syncthreads();
    for (int k=ks; k<ks+M; k++) {
      sum += s_A[k-ks] * B[N*k+j];
    }
  }
  C[N*i+j] = sum;
}

int main(int argc, char **argv) {
  int N = atoi(argv[1]);
  float * h_A = new float [N*N];
  float * h_B = new float [N*N];
  float * h_C = new float [N*N];
  float *d_A, *d_B, *d_C;
  int size = N * N * sizeof(float);
  cudaMalloc((void **) &d_A, size);
  cudaMalloc((void **) &d_B, size);
  cudaMalloc((void **) &d_C, size);

  for (int i=0; i<N; i++) {
    for (int j=0; j<N; j++) {
      h_A[N*i+j] = drand48();
      h_B[N*i+j] = drand48();
      h_C[N*i+j] = 0;
    }
  }
  double tic = get_time();
  cudaMemcpy(d_A, h_A, size, cudaMemcpyHostToDevice);
  cudaMemcpy(d_B, h_B, size, cudaMemcpyHostToDevice);
  cudaMemcpy(d_C, h_C, size, cudaMemcpyHostToDevice);
  dim3 grid(N/M, N);
  matmul<<<grid,M>>>(d_A, d_B, d_C, N);
  cudaMemcpy(h_A, d_A, size, cudaMemcpyDeviceToHost);
  cudaMemcpy(h_B, d_B, size, cudaMemcpyDeviceToHost);
  cudaMemcpy(h_C, d_C, size, cudaMemcpyDeviceToHost);

  double toc = get_time();
  printf("N=%d: %lf s (%lf GFlops)\n",N,toc-tic,2.*N*N*N/(toc-tic)/1e9);
  tic = get_time();
#pragma omp parallel for
  for (int i=0; i<N; i++) {
    for (int k=0; k<N; k++) {
      for (int j=0; j<N; j++) {
        h_C[N*i+j] -= h_A[N*i+k] * h_B[N*k+j];
      }
    }
  }
  toc = get_time();
  printf("N=%d: %lf s (%lf GFlops)\n",N,toc-tic,2.*N*N*N/(toc-tic)/1e9);
  float err = 0;
  for (int i=0; i<N; i++) {
    for (int j=0; j<N; j++) {
      err += fabs(h_C[N*i+j]);
    }
  }
  printf("error: %f\n",err/N/N);
  delete[] h_A;
  delete[] h_B;
  delete[] h_C;
}
