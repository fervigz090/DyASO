#include <stdio.h>
#include <stdlib.h>
#include <sys/types.h>
#include <sys/ipc.h>
#include <sys/msg.h>
#include <sys/shm.h>
#include <sys/sem.h>
#include <sys/wait.h>
#include <unistd.h>

#define PERM 0666 // Permisos para la cola de mensajes

int main(int argc, char *argv[]) {
    int num_contendientes;
    key_t key;
    int msgid; // Cola de mensajes
    int shmid; // Memoria compartida
    int semid; // Semáforo
    struct sembuf p_op = {0, -1, 0}; // Operación P (espera)
    struct sembuf v_op = {0, 1, 0};  // Operación V (señal)
    int pid;
    int barrera[2]; // Tubería barrera
    FILE *resultado; // Archivo asociado a la tubería 'resultado'

    if (argc != 2) {
        printf("Uso: %s <num_contendientes>\n", argv[0]);
        return 1;
    }

    num_contendientes = atoi(argv[1]);

    // Abriendo tubería 'resultado'
    resultado = fopen("Trabajo2/resultado", "w");
    if (resultado == NULL) {
        perror("fopen resultado");
        exit(EXIT_FAILURE);
    }

    // Crear tubería barrera
    if (pipe(barrera) == -1) {
        perror("pipe barrera");
        exit(EXIT_FAILURE);
    }

    // Crear clave única
    if ((key = ftok(".", 'X')) == -1) {
        perror("ftok");
        exit(EXIT_FAILURE);
    }

    // Crear cola de mensajes
    if ((msgid = msgget(key, PERM | IPC_CREAT)) == -1) {
        perror("msgget");
        exit(EXIT_FAILURE);
    }

    // Crear semáforo
    semid = semget(key, 1, IPC_CREAT | 0666);
    if (semid == -1) {
        perror("semget");
        exit(EXIT_FAILURE);
    }
    if (semctl(semid, 0, SETVAL, 1) == -1) {
        perror("semctl");
        exit(EXIT_FAILURE);
    }

    // Crear región de memoria compartida
    shmid = shmget(key, sizeof(pid_t) * num_contendientes, IPC_CREAT | 0666);
    if (shmid == -1) {
        perror("shmget");
        exit(EXIT_FAILURE);
    }
    pid_t *lista = (pid_t *)shmat(shmid, NULL, 0);
    if (lista == (pid_t *)-1) {
        perror("shmat");
        exit(EXIT_FAILURE);
    }

    // Crear procesos hijo y almacenar PIDs en 'lista'
    for (int i = 0; i < num_contendientes; ++i) {
        pid = fork();

        if (pid < 0) {
            perror("fork");
            exit(EXIT_FAILURE);
        } else if (pid == 0) {
            // Código del proceso hijo
            char buffer;
            read(barrera[0], &buffer, 1); // Esperar señal del padre
            execl("./Trabajo2/HIJO", "Trabajo2/HIJO", (char *)NULL);
            perror("execl");
            exit(EXIT_FAILURE);
        } else {
            // Código del proceso padre
            fprintf(resultado, "Proceso hijo %d creado con PID %d\n", i + 1, pid);
            fflush(resultado);
            semop(semid, &p_op, 1);
            lista[i] = pid; // Almacenar PID del hijo
            semop(semid, &v_op, 1);
        }
    }

    fprintf(resultado, "Todos los procesos hijo han sido creados.\n");
    fflush(resultado);

    // Sincronización con hijos: enviar señal a través de la tubería
    for (int i = 0; i < num_contendientes; ++i) {
        write(barrera[1], "x", 1);
    }

    fprintf(resultado, "Señales enviadas a los procesos hijo.\n");
    fflush(resultado);

    // Esperar a que todos los hijos terminen
    for (int i = 0; i < num_contendientes; ++i) {
        wait(NULL);
    }

    fprintf(resultado, "Todos los procesos hijo han terminado.\n");
    fflush(resultado);

    // Limpieza
    fclose(resultado);
    close(barrera[0]);
    close(barrera[1]);
    shmdt(lista);
    shmctl(shmid, IPC_RMID, NULL);
    semctl(semid, 0, IPC_RMID);

    return 0;
}