
#include <stdio.h>
#include <stdio.h>
#include <stdlib.h>
#include <sys/types.h>
#include <sys/ipc.h>
#include <sys/msg.h>
#include <sys/shm.h>
#include <sys/sem.h>
#include <unistd.h>
#include <time.h>
#include <string.h>
#include <signal.h>

// Variables globales
FILE *resultado = NULL;
pid_t *shared_memory = NULL;
int semid;

char estado[3] = "OK"; // Estado inicial

volatile sig_atomic_t enEstadoIndefenso = 0; // Indica si el hijo está indefenso

// Estructura para los mensajes
typedef struct {
    long mtype;  // Tipo de mensaje
    pid_t pid;   // PID del proceso hijo
    char estado[3]; // Estado del proceso hijo ('OK' o 'KO')
} mensaje;

void defensa(int signum) {
    printf("El hijo %d ha repelido un ataque\n", getpid());
    
}

void indefenso(int signum) {
    //if (enEstadoIndefenso) {
        strcpy(estado, "KO");
    //}

    printf("El hijo %d ha sido emboscado mientras realizaba un ataque\n", getpid());
}

void term_handler(int sig) {

    // Desconectar la memoria compartida
    if (shared_memory != NULL) {
        shmdt(shared_memory);
        shared_memory = NULL;
    }

    // Liberar el semáforo
    if (semid >= 0) {
        semctl(semid, IPC_RMID, 0);
    }

    // Cerrar el archivo resultado si está abierto
    if (resultado != NULL) {
        fclose(resultado);
        resultado = NULL;
    }

    // Terminar el proceso hijo
    exit(0);
}


int main(int argc, char *argv[]){

	int num_contendientes = atoi(argv[1]); // Convertir el argumento a entero
	int readEnd = atoi(argv[2]);
    signal(SIGTERM, term_handler); // Manejador SIGTERM

	// Abrir tuberia 'resultado' en modo agregar
	FILE *resultado = fopen("Trabajo2/resultado", "a");
    if (resultado == NULL) {
        perror("Error al abrir la tubería resultado");
        exit(EXIT_FAILURE);
    }

	// Re-establecer mecanismos IPC (key='X')
	key_t key;

	if ((key = ftok(".", 'X')) == -1) {
    	perror("ftok");
    	exit(EXIT_FAILURE);
	}

	// Conectarse a la cola de mensajes
	int msgid;
	msgid = msgget(key, 0666);
	if (msgid == -1) {
    	perror("msgget");
    	exit(EXIT_FAILURE);
	}

	// Conectarse a la memoria compartida
	int shmid;

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
	semid = semget(key, 1, 0666);
	if (semid == -1) {
	    perror("semget");
	    exit(EXIT_FAILURE);
	}

    struct sembuf p_op = {0, -1, 0}; // Operación P (espera)
    struct sembuf v_op = {0,  1, 0}; // Operación V (señal)


	// Fase de preparacion

	srand(time(NULL) ^ (getpid() << 16));

	while(1) {

        // Comprobar si el proceso padre sigue vivo
        if (getppid() == 1) {
            // El proceso padre ha terminado
            exit(0);
        }

		int decision = rand();

		// readEnd para leer de la tuberia
		char buffer;
		read(readEnd, &buffer, 1);

		if (decision % 2 == 0) {
		    // DEFENSOR
		    signal(SIGUSR1, defensa); 
		    usleep(200000); // Espera 0.2 segundos
		    strcpy(estado, "OK");
            enEstadoIndefenso = 0;
		    fprintf(resultado, "Proceso %2d defensor\n", getpid());
		    fflush(resultado);
		} else {
		    // ATACANTE
		    signal(SIGUSR1, indefenso);
		    usleep(100000); // Espera 0.1 segundos antes de atacar
            enEstadoIndefenso = 1; // El proceso ahora está indefenso
		    fprintf(resultado, "Proceso %2d atacante\n", getpid());
		    fflush(resultado);

			// Atacar. Elige un PID aleatorio, excepto el suyo.
			int target;

            semop(semid, &p_op, 1); // Bloquear el semáforo antes de acceder
			
			do {

                // Comprobar si el proceso padre sigue vivo
                if (getppid() == 1) {
                    // El proceso padre ha terminado
                    exit(0);
                }

                target = rand() % num_contendientes;

			} while (shared_memory[target] == getpid() || shared_memory[target] == 0);

            if (shared_memory[target] != 0) {
    			printf("%d Atacando al proceso %d\n", getpid(), shared_memory[target]);

    			kill(shared_memory[target], SIGUSR1);
            }

            semop(semid, &v_op, 1); // Liberar el semáforo después de acceder

			usleep(100000); // Espera 0.1 segundos adicionales

        }

		// Envia mensaje con informacion del resultado
		mensaje msg;
		msg.mtype = 1;
		msg.pid = getpid(); // PID del proceso hijo
        strcpy(msg.estado, estado);

		int msgid = msgget(key, 0666); // Obtener el identificador de la cola de mensajes

		if (msgsnd(msgid, &msg, sizeof(mensaje) - sizeof(long), 0) == -1) {
		    perror("msgsnd");
		    exit(EXIT_FAILURE);

		}

	}

	fclose(resultado);

}



