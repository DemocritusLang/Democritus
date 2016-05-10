#include <pthread.h>
#include <string.h>
#include <sys/socket.h>
#include <arpa/inet.h>
#include <stdio.h>
#include <errno.h>
#include <netdb.h>
#include <stdlib.h>
#define BUFSIZE 4096

static void die(const char *msg)
{
    perror(msg);
    exit(1);
}

void *request_from_server(void *link, void *filename)
{
    char *serverName;
    char *serverIP;
    char *serverPort = "80";
    char *filePath;
    char *fname;
    serverName = (char *) link;
    filePath = (char *) filename;
    fname = (char *) filename + 1; 
    int sock;
    struct sockaddr_in serverAddr;
    struct hostent *he;
    char request[BUFSIZE], response[100 *BUFSIZE], recvbuf[BUFSIZE];

    serverName = (char *) link;
    if ((he = gethostbyname(serverName)) == NULL)
	die("gethostbyname failed");

    sock = socket(AF_INET, SOCK_STREAM, 0);
    if (sock < 0)
    {
	die("socket failed");
    }
    serverIP = inet_ntoa(*(struct in_addr *)he->h_addr);
    memset(&serverAddr, 0, sizeof(serverAddr));
    serverAddr.sin_addr.s_addr = inet_addr(serverIP);
    serverAddr.sin_family = AF_INET;
    serverAddr.sin_port = htons(80);

    int connected = connect(sock, (struct sockaddr *)&serverAddr, sizeof(serverAddr));
    if(connected == -1)
    {
	die("connect() failed");
    }

    // send HTTP request
    snprintf(recvbuf, sizeof(recvbuf), 
	    // note that C language concatenates adjacent string literals
	    "GET %s HTTP/1.0\r\n"
	    "Host: %s:%s\r\n"
	    "\r\n",
	    filePath, serverName, serverPort);
    if (send(sock, recvbuf, strlen(recvbuf), 0) != strlen(recvbuf)) {
        die("send failed");
    }

    // wrap the socket with a FILE* so that we can read the socket using fgets()
    FILE *fd;
    if ((fd = fdopen(sock, "r")) == NULL) {
	die("fdopen failed");
    }

    // read the 1st line
    if (fgets(recvbuf, sizeof(recvbuf), fd) == NULL) {
	if (ferror(fd))
	    die("IO error");
	else {
	    fprintf(stderr, "server terminated connection without response");
	    exit(1);
	}
    } 
    if (strncmp("HTTP/1.0 ", recvbuf, 9) != 0 && strncmp("HTTP/1.1 ", recvbuf, 9) != 0) {
	fprintf(stderr, "unknown protocol response: %s\n", recvbuf);
	exit(1);
    }
    if (strncmp("200", recvbuf + 9, 3) != 0) {
	fprintf(stderr, "%s\n", recvbuf);
	exit(1);
    }

    // If we're still here, it means we have a successful HTTP
    // response (i.e., response code 200).

    // Now, skip the header lines.
    for (;;) {
	if (fgets(recvbuf, sizeof(recvbuf), fd) == NULL) {
	    if (ferror(fd))
		die("IO error");
	    else {
		fprintf(stderr, "server terminated connection without sending file");
		exit(1);
	    }
	}
	if (strcmp("\n", recvbuf) == 0) {
	    // this marks the end of header lines
	    // get out of the for loop.
	    break;
	}
    }

    // Now it's time to read the file.
    // We switch to fread()/fwrite() so that we can download a binary
    // file as well as an HTML file.
    // (Handling binary file is not required for the assignment.)

    FILE *outputFile = fopen(fname, "wb");
    if (outputFile == NULL){
	die("can't open output file\n");
    }

    size_t n;
    while ((n = fread(recvbuf, 1, sizeof(recvbuf), fd)) > 0) {
	if (fwrite(recvbuf, 1, n, outputFile) != n) {
	    die("fwrite failed");
	}
    }
    // fread() returns 0 on EOF or on error
    // so we need to check if there was an error.
    if (ferror(fd)) {
	die("fread failed");
    }

    // All done.  Clean up.
    
    fclose(outputFile);

    // closing fd closes the underlying socket as well.
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
