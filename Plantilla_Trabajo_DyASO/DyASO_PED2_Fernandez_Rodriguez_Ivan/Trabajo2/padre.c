//este archivo es el fichero fuente que al compilarse produce el ejecutable PADRE
#include <stdio.h>
#include <stdlib.h>
#include <sys/types.h>
#include <sys/ipc.h>
#include <sys/msg.h>
#include <sys/shm.h>
#include <sys/sem.h>
#include <unistd.h>

#define PERM 0666 //Permisos para la cola de mensajes

int main(int argc, char *argv[]){
	int num_contendientes;
	key_t key;
	int msgid; // Cola de mensajes
	int shmid; // Memoria compartida

	if (argc != 2) {
        printf("Uso: %s <num_contendientes>\n", argv[0]);
        return 1;
    }

    num_contendientes = atoi(argv[1]); // Convertir el argumento a entero

    printf("El número de contendientes es: %d\n", num_contendientes);

// CREAR COLA DE MENSAJES

	// Generar una clave unica
	if ((key = ftok(".", 'X')) == -1) {
		perror("Error al generar la clave");
		exit(1);
	}

	// Crear o acceder a la cola de mensajes
	if ((msgid = msgget(key, PERM | IPC_CREAT)) == -1) {
		perror("Error al crear/acceder a la cola de mensajes");
		exit(1);
	}

	// Redirigir la salida estandar hacia el archivo mensajes
	if (freopen("mensajes", "w", stdout) == NULL) {
		perror("Error al redirigir la salida estandar");
		exit(1);
	}

	// Mostrar el identificador de la cola de mensajes en el archivo
	printf("Cola de mensajes creada con identificador: %d\n", msgid);

// CREAR REGION DE MEMORIA COMPARTIDA

	// Crear la región de memoria compartida
    shmid = shmget(key, sizeof(pid_t) * num_contendientes, IPC_CREAT | 0666);
    if (shmid == -1) {
        perror("shmget");
        exit(EXIT_FAILURE);
    }

    // Adjuntar la region de memoria compartida al espacio de direcciones del proceso
    pid_t *pids = (pid_t *)shmat(shmid, NULL, 0);
    if (pids == (pid_t *)(-1)) {
        perror("shmat");
        exit(EXIT_FAILURE);
    }

    // Uso de la memoria compartida

    // Desasociar la region de memoria compartida del espacio de direcciones del proceso
    if (shmdt(pids) == -1) {
        perror("shmdt");
        exit(EXIT_FAILURE);
    }

    // Marcar la region de memoria compartida para su eliminacion
    shmctl(shmid, IPC_RMID, NULL);




	return 0;
}
