#!/bin/bash
#este archivo es un scrip que:

#1 compila los fuentes padre.c e hijo.c con gcc

	# Compila padre.c y almacena ejecutable en /Trabajo2
	padre_fuente="Trabajo2/padre.c"
	nombre_ejecutable="Trabajo2/PADRE"
	gcc "$padre_fuente" -o "$nombre_ejecutable"

	# Compila hijo.c y almacena ejecutable en /Trabajo2
	hijo_fuente="Trabajo2/hijo.c"
	nombre_ejecutable="Trabajo2/HIJO"
	gcc "$hijo_fuente" -o "$nombre_ejecutable"

#2 crea el fichero fifo "resultado"

	fifo="Trabajo2/resultado"

	# Comprobamos si ya existe
	if [ ! -p "$fifo" ]; then
		# Si no existe, creamos el fichero
		mkfifo "$fifo"
		echo "Fichero '$fifo' creado correctamente."
	else
		echo "Fichero '$fifo' ya existe."
	fi

#lanza un cat en segundo plano para leer "resultado"

	cat < "$fifo" &

#lanza el proceso padre

	# nohup bash -c ./Trabajo2/PADRE > /dev/null 2>&1
	./Trabajo2/PADRE 10
	pid=$!
	echo "$pid -> pid a eliminar"

#al acabar limpia todos los ficheros que ha creado
	sleep 15
	kill $pid
	rm Trabajo2/HIJO
	rm Trabajo2/PADRE
	rm Trabajo2/resultado
	rm mensajes






