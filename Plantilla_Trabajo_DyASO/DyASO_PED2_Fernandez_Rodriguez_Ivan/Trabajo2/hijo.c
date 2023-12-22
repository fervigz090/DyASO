
#include <stdio.h>
#include <stdio.h>
#include <stdlib.h>
#include <sys/types.h>
#include <sys/ipc.h>
#include <sys/msg.h>
#include <sys/shm.h>
#include <sys/sem.h>
#include <unistd.h>


int main(int argc, char *argv[]){

	int num_contendientes;

	num_contendientes = atoi(argv[1]); // Convertir el argumento a entero

	// Re-establecer mecanismos IPC (key='X')
	key_t key;

	if ((key = ftok(".", 'X')) == -1) {
    	perror("ftok");
    	exit(EXIT_FAILURE);
	}

	// Conectarse a la cola de mensajes
	int msgid;
	msgid = msgget(key, 0666); // No es necesario el flag IPC_CREAT
	if (msgid == -1) {
    	perror("msgget");
    	exit(EXIT_FAILURE);
	}

	// Conectarse a la memoria compartida
	int shmid;
	pid_t *shared_memory;

	shmid = shmget(key, sizeof(pid_t) * num_contendientes, 0666);
	if (shmid == -1) {
   		perror("shmget");
  		exit(EXIT_FAILURE);
	}

	shared_memory = (pid_t *) shmat(shmid, NULL, 0);
	if (shared_memory == (void *) -1) {
    	perror("shmat");
    	exit(EXIT_FAILURE);
	}

	// Conectarse al semaforo
	int semid;
	semid = semget(key, 1, 0666); // Asume que solo hay un semáforo
	if (semid == -1) {
	    perror("semget");
	    exit(EXIT_FAILURE);
	}



	
}
