#include <stdio.h>
#include <stdlib.h>
#include <sys/types.h>
#include <sys/ipc.h>
#include <sys/msg.h>
#include <sys/shm.h>
#include <sys/sem.h>
#include <sys/wait.h>
#include <unistd.h>
#include <sys/stat.h>
#include <string.h>
#include <stdbool.h>
#include <errno.h>

#define PERM 0666 // Permisos

// Estructura para los mensajes
typedef struct {
    long mtype;  // Tipo de mensaje (por ejemplo, 1)
    pid_t pid;   // PID del proceso hijo
    char estado[3]; // Estado del proceso hijo ('OK' o 'KO')
} mensaje;


int main(int argc, char *argv[]) {
    int num_contendientes;
    key_t key;
    int msgid; // Cola de mensajes
    int shmid; // Memoria compartida
    int semid; // Semáforo
    struct sembuf p_op = {0, -1, 0}; // Operación P (espera)
    struct sembuf v_op = {0, 1, 0};  // Operación V (señal)
    int pid;
    char (*estados)[3];
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
        perror("Error fopen 'resultado'");
        exit(EXIT_FAILURE);
    }

    // Cambiar permisos de la tubería FIFO
    if (chmod("Trabajo2/resultado", 0666) == -1) { 
        perror("Error chmod 'resultado'");
        return 1;
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
    semid = semget(key, 1, IPC_CREAT | 0777);
    if (semid == -1) {
        perror("fallo en semget");
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

    // Pasamos num_contendientes a string
    char num_contendientes_str[20];
    sprintf(num_contendientes_str, "%d", num_contendientes);

    // Pasamos descriptor de lectura a string
    char readEndStr[num_contendientes];
    sprintf(readEndStr, "%d", barrera[0]);   

    // Crear procesos hijo y almacenar PIDs en 'lista'
    for (int i = 0; i < num_contendientes; ++i) {
        pid = fork();

        if (pid < 0) {
            perror("fork");
            exit(EXIT_FAILURE);
        } else if (pid == 0) {
            // Código del proceso hijo
            execl("Trabajo2/HIJO", "HIJO", num_contendientes_str, readEndStr,(char *)NULL);
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

    sleep(1);

    int contador = 1;
    int rondasActivas = 1;
    int num_contendientes_activos = num_contendientes;

    // Bucle while para cada ronda
    while (num_contendientes_activos > 1) {

        fprintf(resultado, "\n\nInicio RONDA %d\n\n", contador);
        fflush(resultado);

        // Reiniciar num_contendientes para esta ronda
        num_contendientes_activos = 0;

        // Leer mensajes de cola de mensajes
        mensaje msg;
        int res;

        while (true) {

            res = msgrcv(msgid, &msg, sizeof(mensaje) - sizeof(long), 1, IPC_NOWAIT);

            if (res == -1) {
                if (errno == ENOMSG) {
                    // No hay más mensajes en la cola
                    // Enviar señal de inicio de ronda
                    num_contendientes_activos = 0;
                    semop(semid, &p_op, 1); // Espera antes de acceder a 'barrera'
                    for (int i = 0; i < num_contendientes; ++i) {
                        if (lista[i] != 0) { // 0 significa 'no activo'
                            write(barrera[1], "x", 1);
                            num_contendientes_activos++; // Contar contendientes activos
                        }
                    }
                    semop(semid, &v_op, 1); // Señal después de la sección crítica

                    if (num_contendientes_activos < 2) {
                        break;
                    }

                    fprintf(resultado, "Señales enviadas a %d procesos hijo vivos.\n", num_contendientes_activos);

                    // Esperar un segundo para que la ronda se complete
                    sleep(1);

                    num_contendientes = num_contendientes_activos;
                    break; // Sale del bucle
                } else {
                    // Ocurrió un error distinto de "no hay mensajes"
                    perror("msgrcv");
                    exit(EXIT_FAILURE);
                }
            } else {
                // Mensaje recibido exitosamencdcesarlo
                if (strcmp(msg.estado, "KO") == 0) {
                    semop(semid, &p_op, 1); // Espera antes de acceder a 'lista'
                    
                    for (int i = 0; i < num_contendientes; ++i) {
                        if (lista[i] == msg.pid) {
                            // Terminar el proceso hijo con estado KO
                            if (kill(lista[i], SIGTERM) == -1) {
                                perror("kill");
                                exit(EXIT_FAILURE);
                            }

                            // Esperar al proceso hijo para recoger su estado y evitar procesos zombi
                            waitpid(lista[i], NULL, 0);
                            // Proceso hijo con estado KO, marcar como no activo
                            lista[i] = 0;
                            break;
                        }
                    }
                    
                    semop(semid, &v_op, 1); // Señal después de la sección crítica
                }
            }
        }

        // Comprobar el estado de los procesos hijo para la siguiente ronda
        rondasActivas = num_contendientes_activos > 1;

        sleep(1);

        fprintf(resultado, "Fin RONDA %d\n\n", contador);
        fflush(resultado);
        contador++;
    }
    
    // Elimina los hijos restantes despues de la batalla
    if (num_contendientes > 0) {
        for (int i = 0; i < num_contendientes; ++i) {
            if (lista[i] != 0) {
                // Enviar señal de terminación al proceso hijo
                kill(lista[i], SIGTERM);

                fprintf(resultado, "***** El hijo %d ha ganado! *****\n\n", lista[i]);
                fflush(resultado);

                // Esperar al proceso hijo para recoger su estado
                waitpid(lista[i], NULL, 0);
            }
        }
    } else {
        fprintf(resultado, "Empate!\n");
        fflush(resultado);
    }


    // Esperar a que todos los hijos terminen
    for (int i = 0; i < num_contendientes; ++i) {
        if (lista[i] != 0) {
            waitpid(lista[i], NULL, 0);
        }
    }

    // Limpieza
    fclose(resultado);
    close(barrera[0]);
    close(barrera[1]);
    shmdt(lista);
    shmctl(shmid, IPC_RMID, NULL);

    // Liberar el conjunto de semáforos
    if (semctl(semid, IPC_RMID, 0) == -1) {
        perror("semctl IPC_RMID");
    }

    // Liberar la cola de mensajes
    if (msgctl(msgid, IPC_RMID, NULL) == -1) {
        perror("msgctl IPC_RMID");
    }

    return 0;
}