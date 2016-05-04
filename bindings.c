#include<pthread.h> 

void init_thread(void *(start_routine) (void *), int nthreads)
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
