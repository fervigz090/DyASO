#include <stdio.h>
#include <stdlib.h>
#include <sys/types.h>
#include <sys/ipc.h>
#include <sys/msg.h>
#include <sys/shm.h>
#include <sys/sem.h>
#include <sys/wait.h>
#include <unistd.h>

#define PERM 0666 //Permisos para la cola de mensajes

int main(int argc, char *argv[]){
	int num_contendientes;
	key_t key;
	int msgid; // Cola de mensajes
	int shmid; // Memoria compartida
	int semid; // Semaforo
	struct sembuf p_op = {0, -1, 0}; // Operación P (espera)
	struct sembuf v_op = {0,  1, 0}; // Operación V (señal)
	int pid;

	if (argc != 2) {
        printf("Uso: %s <num_contendientes>\n", argv[0]);
        return 1;
    }

    num_contendientes = atoi(argv[1]); // Convertir el argumento a entero


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

// CREAR SEMAFORO

	// Crear y comprobar
	semid = semget(key, 1, IPC_CREAT | 0666);
	if (semid == -1) {
		perror("semget");
		exit(EXIT_FAILURE);
	}

	// Inicializar (Necesario antes de su uso)
	if(semctl(semid, 0, SETVAL, 1) == -1) {
		perror("semctl");
		exit(EXIT_FAILURE);
	}

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



// CREAR N HIJOS Y ALMACENAR PIDs EN "lista"

    pid_t *lista; // Declaración del puntero al array en la memoria compartida

	// Adjuntar la memoria compartida
	lista = (pid_t *)shmat(shmid, NULL, 0);
	if (lista == (pid_t *)-1) {
	    perror("Error en shmat");
	    exit(EXIT_FAILURE);
	}


	for (int i = 0; i < num_contendientes; ++i) {
        pid = fork();

        if (pid < 0) {
            // Error al crear el proceso hijo
            perror("Error en fork");
            exit(EXIT_FAILURE);
        } else if (pid == 0) {
            // Código ejecutado por el proceso hijo
            execl("./Trabajo2/HIJO", "Trabajo2/HIJO", (char *)NULL); 

            // Si execl() retorna, hubo un error
            perror("Error en execl");
            exit(EXIT_FAILURE);
        }  else {
	        // Código del proceso padre

	        // Operación P (esperar) en el semáforo antes de escribir en la memoria compartida
			semop(semid, &p_op, 1);

	        lista[i] = pid; // Almacena el PID del hijo en la memoria compartida

	        // Operación V (señal) en el semáforo después de escribir en la memoria compartida
			semop(semid, &v_op, 1);
		}
	}

    // El proceso padre puede esperar a que los hijos terminen
    while (wait(NULL) > 0);

// ABRIR TUBERIA FIFO "resultado"
	FILE *fifo;
	fifo = fopen("Trabajo2/resultado", "w"); // Abrir para escritura
	if (fifo == NULL) {
	    perror("Error al abrir el FIFO");
	    exit(EXIT_FAILURE);
	}

	// Usar fprintf o fputs para escribir en el FIFO
	fprintf(fifo, "Mensaje del proceso padre\n");

	// TEST lista
	// Suponiendo que lista es un array de pid_t y almacena los PIDs de los procesos hijos
	for (int i = 0; i < num_contendientes; ++i) {
	    fprintf(fifo, "Proceso hijo %d tiene PID: %d\n", i+1, lista[i]);
	}

	// Cerrar el FIFO al final
	fclose(fifo);







    // Desasociar la region de memoria compartida del espacio de direcciones del proceso
    if (shmdt(pids) == -1) {
        perror("shmdt");
        exit(EXIT_FAILURE);
    }

    // Marcar la region de memoria compartida para su eliminacion
    shmctl(shmid, IPC_RMID, NULL);




	return 0;
}
