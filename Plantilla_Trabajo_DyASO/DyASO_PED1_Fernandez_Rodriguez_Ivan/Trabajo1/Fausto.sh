#!/bin/bash


# FUNCIONES

# Creacion de archivos al inicio
inicializar (){
	touch procesos
	touch procesos_servicio
	touch procesos_periodicos
	touch Biblia.txt
	touch SanPedro
	mkdir -m 777 infierno
}

# Borrado inicial
borrado (){

	rm -f procesos
	rm -f procesos_servicio
	rm -f procesos_periodicos
	rm -f Biblia.txt
	rm -f Apocalipsis
	rm -f SanPedro
	rm -f -R infierno
}

# Invocacion del demonio. Si ya esta en ejecucion no hace nada.
verificar_y_lanzar_demonio() {
    if ! pgrep -x "Demonio.sh" >/dev/null; then
        # El proceso Demonio.sh no está en ejecución. Iniciando..
		borrado
		inicializar
        nohup ./Demonio.sh > /dev/null 2>&1 &
		time=$(date +%H:%M:%S)
		echo $time:" -------------Genesis-------------" >> Biblia.txt
		echo $time:" El demonio ha sido creado." >> Biblia.txt
    fi
}

# Recorrido lista para verificar PID (funcion STOP)
verificar_eliminar_proceso() {
	local pid="$1"
	# Elimina el proceso de la lista para que no lo resucite el Demonio
	sed -i "/$pid/d" "$2"
	# Eliminamos el proceso hijo (proceso que se desea eliminar)
	pgrep -P "$pid" | xargs kill -9
	# Eliminamos el proceso padre enviando la senal SIGKILL
	kill -9 "$pid"
}

# Funcion lanzamiento de procesos periodicos
lanzamiento_periodico() {
	local periodo_T="$1"
	local comando="$2"
	arranque=$(date +%s) # momento en el que se lanza el proceso la primera vez
	# Lanzamiento periodico del proceso
	while true; do
        # Hora de inicio del proceso actual
        t_inicio=$(date +%s)

        # Ejecutar el comando
        eval "$comando" > /dev/null 2>&1 &
		pid=$!

        # Hora de finalización del proceso actual
        t_fin=$(date +%s)

        # Calcular el tiempo transcurrido en segundos
        t_transcurrido=$((t_fin - t_inicio))

        # Calcular el tiempo restante hasta el próximo período
        t_restante=$((periodo_T - (t_transcurrido % periodo_T)))

		# Guardar el proceso en la lista y una entrada en Biblia.txt
		echo "$t_transcurrido $periodo_T $pid '$comando'" >> procesos_periodicos
		echo "$time: El proceso $pid '$comando' ha nacido" >> Biblia.txt

        # Esperar hasta el siguiente período
        sleep "$t_restante"
    done
}


#Recibe órdenes creando los procesos y listas adecuadas

if [ $# -eq 0 ]; then	#Si no hay argumentos se verifica la existencia del demonio
	verificar_y_lanzar_demonio;
else
	verificar_y_lanzar_demonio;
	time=$(date +%H:%M:%S)
	comando="$2"
	case "$1" in
		"run")	#ejecuta un comando una sola vez
			bash -c "$comando" &	#instancia de bash en segundo plano
			pid=$!	#obtenemos el pid del padre
			echo "$pid '$2'" >> procesos
			echo "$time: El proceso $pid '$2' ha nacido" >> Biblia.txt
			;;
		"run-service")
			bash -c "$comando" &
			pid=$!
			echo "$pid '$2'" >> procesos_servicio
			echo "$time: El proceso $pid '$2' ha nacido" >> Biblia.txt
			;;
		"run-periodic")
			comando="$3"
			periodo_T="$2"
			lanzamiento_periodico "$periodo_T" "$comando" &
			;;
		"list")
			echo "***** Procesos normales *****"
			# Comprobamos que existe el fichero y que no esta vacio
			if [ -e procesos ] && [ -s procesos ]; then
				procesos="procesos"
				# Recorremos cada linea devolviendola
            	while IFS=' ' read -r ppid comando; do
                	echo "$ppid $comando"
            	done < "$procesos"
			fi

			echo "***** Procesos servicio *****"
			# Comprobamos que existe el fichero y que no esta vacio
			if [ -e procesos_servicio ] && [ -s procesos_servicio ]; then
				procesos_servicio="procesos_servicio"
				# Recorremos cada linea del fichero devolviendola.
				while IFS=' ' read -r ppid comando; do
					echo "$ppid $comando"
				done < "$procesos_servicio"
			fi

			echo "***** Procesos periodicos *****"
			# Comprobamos que existe el fichero y que no esta vacio
			if [ -e procesos_periodicos ] && [ -s procesos_periodicos ]; then
				procesos_periodicos="procesos_periodicos"
				# Recorremos cada linea del fichero devolviendola
				while IFS=' ' read -r t_arranque T ppid comando; do
					echo "$t_arranque $T $ppid $comando"
				done < "$procesos_periodicos"
			fi
			;;
		"help")
			echo "Sintaxis:"
			echo " ./Fausto.sh run comando"
			echo " ./Fausto.sh run-service comando"
			echo " ./Fausto.sh run-periodic T comando"
			echo " ./Fausto.sh list"
			echo " ./Fausto.sh help"
			echo " ./Fausto.sh stop PID"
			echo " ./Fausto.sh end"
			;;
		"stop")
			verificar_eliminar_proceso "$2" "procesos_servicio";
			;;
		"end")
			touch Apocalipsis
			;;
		*)
			echo "Error, orden '$1' no reconocido, consulte las ordenes disponibles con ./Fausto.sh help"
			;;
	esac
fi

#Si el Demonio no está vivo lo crea

#Al leer/escribir en las listas hay que usar bloqueo para no coincidir con el Demonio

