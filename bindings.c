#include <pthread.h>

void *default_start_routine(void *arg)
{
	return arg;
}

void init_thread(void *(*start_routine) (void *), int arg, int nthreads)
{
    pthread_t thread[nthreads];
    int i;
    for (i = 0; i < nthreads; i ++) {
	pthread_create(&thread[i], NULL, start_routine, NULL);
    }

    for (i = 0; i < nthreads; i++) {
	pthread_join(thread[i], NULL);
    }
}
