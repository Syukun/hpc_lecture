#include <pthread.h>
#include <stdio.h>

void* print(void*) {
  static int t=0;
  static pthread_mutex_t mutex=PTHREAD_MUTEX_INITIALIZER;
  pthread_mutex_lock(&mutex);
  t++;
  pthread_mutex_unlock(&mutex);
  printf("%d\n", t-1);
}

int main() {
  for(int i=0; i<10; i++) {
    pthread_t thread;
    pthread_create(&thread, NULL, print, NULL);
  }
  pthread_exit(NULL);
}
