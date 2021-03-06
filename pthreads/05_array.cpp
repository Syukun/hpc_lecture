#include <pthread.h>
#include <stdio.h>

const size_t size=1000000;
static size_t sum=0;

void* print(void* arg) {
  static int t=0;
  static pthread_mutex_t mutex=PTHREAD_MUTEX_INITIALIZER;
  pthread_mutex_lock(&mutex);
  t++;
  pthread_mutex_unlock(&mutex);
  size_t ibegin = (t-1)*size/10;
  size_t iend = t*size/10;
  printf("thread %d, range %ld - %ld\n", t-1, ibegin, iend-1);
  size_t *a = (size_t*)arg;
  pthread_mutex_lock(&mutex);
  for (int i=ibegin; i<iend; i++) sum+=a[i];
  pthread_mutex_unlock(&mutex);
}

int main() {
  size_t *a = new size_t [size];
  for (size_t i=0; i<size; i++) a[i] = 1;
  pthread_t thread[10];
  for(int i=0; i<10; i++) {
    pthread_create(&thread[i], NULL, print, (void*)a);
  }
  printf("sum = %ld\n", sum);
  for(int i=0; i<10; i++) {
    pthread_join(thread[i], NULL);
  }
  printf("sum = %ld\n", sum);
  delete[] a;
  pthread_exit(NULL);
}
