
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

void defensa(int signum) {
    printf("El hijo %d ha repelido un ataque\n", getpid());
    
}

void indefenso(int signum) {
    printf("El hijo %d ha sido emboscado mientras realizaba un ataque\n", getpid());
    
}

int main(int argc, char *argv[]){

	int num_contendientes;

	num_contendientes = atoi(argv[1]); // Convertir el argumento a entero

	// Abrir tuberia 'resultado' en modo agregar
	FILE *resultado = fopen("Trabajo2/resultado", "a");
    if (resultado == NULL) {
        perror("Error al abrir la tubería resultado");
        exit(EXIT_FAILURE);
    }

    fprintf(resultado, "holahola");
	    fflush(resultado);

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


	// Fase de preparacion

	srand(time(NULL) ^ (getpid() << 16)); // Inicializar la semilla aleatoria
	int decision = rand();

	char estado[3] = "OK"; // Estado inicial

	if (decision % 2 == 0) {
	    // Defensor
	    signal(SIGUSR1, defensa);  // Configura la señal SIGUSR1 para la función defensa
	    usleep(200000); // Espera 0.2 segundos
	    strcpy(estado, "OK");
	    fprintf(resultado, "Proceso %2d defensor", getpid());
	    fflush(resultado);
	} else {
	    // Atacante
	    signal(SIGUSR1, indefenso); // Configura la señal SIGUSR1 para la función indefenso
	    usleep(100000); // Espera 0.1 segundos antes de atacar
	    fprintf(resultado, "Proceso %2d atacante", getpid());
	    fflush(resultado);
	    // Elegir un PID aleatorio y atacar
	    // ...
	}

	// Atacar. Elige un PID aleatorio, excepto el suyo.
	int target;
	do {
	    target = rand() % num_contendientes;
	} while (shared_memory[target] == getpid() || shared_memory[target] == 0);

	printf("Atacando al proceso %d\n", shared_memory[target]);
	kill(shared_memory[target], SIGUSR1);
	usleep(100000); // Espera 0.1 segundos adicionales


	fclose(resultado);

}



