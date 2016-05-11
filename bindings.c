#include <pthread.h>
#include <string.h>
#include <sys/socket.h>
#include <arpa/inet.h>
#include <stdio.h>
#include <errno.h>
#include <netdb.h>
#include <stdlib.h>
#include <unistd.h>
#define BUFSIZE 4096

void append_strings(void *str1, void *str2)
{
    strcat((char *)str1, (char *)str2);
}

void int_to_string(int n, void *buf)
{
    sprintf(buf, "%d", n);
}

int exec_prog(void *str1, void *str2, void *str3)
{

    execl((char *)str1, (char *)str2, (char *)str3, NULL);
    return 0;
}

/*
 * Given a URL, send a GET request.
 */
//void *get_request(void *url, void *filePath)
void *request_from_server(void *urlVoid)
{
    // www.xkcd.com/index.html
    char *urlStr = (char *) urlVoid;
    int idxslash = strrchr(urlStr, '/') - urlStr;
    char *url = malloc(idxslash + 1);
    char *filePath = malloc(strlen(urlStr) - (idxslash) + 1);
    memset(url, 0, idxslash - 1);
    memset(filePath, 0, strlen(urlStr) - (idxslash));

    strncat(url, urlStr, idxslash);
    strncat(filePath, urlStr + idxslash, strlen(urlStr) - (idxslash));
    char *fileName = strrchr(urlStr, '/') + 1;

    char *serverIP;
    int sock;   // socket we connect to remote on
    struct sockaddr_in serverAddr;
    struct hostent *he;
    char recvbuf[BUFSIZE];

    if ((he = gethostbyname((char *) url)) == NULL) {
	fprintf(stderr, "gethostbyname() failed.");
        exit(1);
    }

    sock = socket(AF_INET, SOCK_STREAM, 0);
    if (sock < 0) {
        fprintf(stderr, "socket() failed.");
        exit(1);
    }
    serverIP = inet_ntoa(*(struct in_addr *)he->h_addr);
    memset(&serverAddr, 0, sizeof(serverAddr));
    serverAddr.sin_addr.s_addr = inet_addr(serverIP);
    serverAddr.sin_family = AF_INET;
    serverAddr.sin_port = htons(80);

    int connected = connect(sock, (struct sockaddr *)&serverAddr, sizeof(serverAddr));
    if(connected < 0) {
	fprintf(stderr, "connect() failed.");
        exit(1);
    }

    // send HTTP request
    if (((char *) url)[strlen((char *) url) - 1] == '/') {
        strcat(url, "index.html");
    }

    snprintf(recvbuf, sizeof(recvbuf), 
            "GET %s HTTP/1.0\r\n"
            "Host: %s:%s\r\n"
            "\r\n",
            filePath, url, "80");
    if (send(sock, recvbuf, strlen(recvbuf), 0) != strlen(recvbuf)) {
        fprintf(stderr, "send() failed.");
        exit(1);
    }

    // wrap the socket with a FILE* so that we can read the socket using fgets()
    FILE *fd;
    if ((fd = fdopen(sock, "r")) == NULL) {
	fprintf(stderr, "fdopen() failed.");
        exit(1);
    }

    /* check header for valid protocol and status code */
    if (fgets(recvbuf, sizeof(recvbuf), fd) == NULL) {
        fprintf(stderr, "server terminated connection without response.");
        exit(1);
    } 
    if (strncmp("HTTP/1.0 ", recvbuf, 9) != 0 && strncmp("HTTP/1.1 ", recvbuf, 9) != 0) {
	fprintf(stderr, "unknown protocol response: %s.", recvbuf);
	exit(1);
    }
    if (strncmp("200", recvbuf + 9, 3) != 0) {
	fprintf(stderr, "request failed with status code %s.", recvbuf);
	exit(1);
    }

    /* ignore remaining header lines */
    do {
	if (fgets(recvbuf, sizeof(recvbuf), fd) == NULL) {
            fprintf(stderr, "server terminated connection without sending file.");
            exit(1);
	}
    } while (strcmp("\n", recvbuf) != 0);

    char *filePathName = malloc(100);
    memset(filePathName, 0, 100);
    strcat(filePathName, "tests/");
    strcat(filePathName, fileName);
    

    /* open and read into file */
    FILE *outputFile = fopen(filePathName, "w");
    if (outputFile == NULL) {
	fprintf(stderr, "fopen() failed.");
        exit(1);
    }

    size_t n;
    int total = 0;
    while ((n = fread(recvbuf, 1, sizeof(recvbuf), fd)) > 0) {
	if (fwrite(recvbuf, 1, n, outputFile) != n) {
	    fprintf(stderr, "fwrite() failed.");
            exit(1);
	}
	total += n;
    }
    fprintf(stderr, "total bytes written: %d\n", total);
    
    if (ferror(fd)) {
	fprintf(stderr, "fread() failed.");
        exit(1);
    }

    fclose(outputFile);
    fclose(fd);
 
    return NULL;
}

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
