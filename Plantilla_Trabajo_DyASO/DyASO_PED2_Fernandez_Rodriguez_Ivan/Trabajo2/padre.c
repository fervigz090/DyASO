//este archivo es el fichero fuente que al compilarse produce el ejecutable PADRE
#include <stdio.h>
#include <stdlib.h>
#include <sys/types.h>
#include <sys/ipc.h>
#include <sys/msg.h>

#define PERM 0666 //Permisos para la cola de mensajes

int main(int argc, char *argv[]){
	int num_contendientes;
	key_t key;
	int msgid;

	if (argc != 2) {
        printf("Uso: %s <num_contendientes>\n", argv[0]);
        return 1;
    }

    num_contendientes = atoi(argv[1]); // Convertir el argumento a entero

    printf("El número de contendientes es: %d\n", num_contendientes);

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





	return 0;
}
