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
verificar_pid_en_lista() {
	local pid="$1"
	local lista_procesos=$(awk '{print $1}' "$2") #nos quedamos con el ppid solo
	pid_exec=$(ps -l | awk '{print $4}' | grep -v PID)
	check=0
	ppid=''
	for proceso in $pid_exec; do    # comprueba si esta en ejecucion
   	    if [ "$proceso" == "$pid" ]; then
		    check=1
			ppid=$(ps -o ppid= -p "$proceso")
            ppid=${ppid#"${ppid%%[![:space:]]*}"}   # sustitucion de patrones para eliminar espacios en blanco.
            echo "$ppid"
            break   # sale del bucle si encuentra el pid
		fi
	done

	if [ "$check" -eq 0 ]; then
		echo "Error! el proceso con PID: $pid no esta en ejecucion"
	else	# El proceso esta en ejecucion, asi que buscamos su PPID en las listas
		for proceso in $lista_procesos; do	# comprueba si el proceso esta en la lista
			if [ "$proceso" == "$ppid" ]; then
				cd infierno
				touch "$pid"
				chmod 666 "$pid"	#Asignamos permisos infernales
                break   # sale del bucle si el ppid esta en la lista
			else
				echo "Error! el proceso '$pid' no se encuentra en las listas."
				echo "Comprobar con el comando './Fausto.sh list'"
                echo "Su PPID es '$ppid'"
			fi
		done
	fi

}

# Ejecucion del comando



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
			pid=$!	#obtenemos el pid del hijo mas reciente
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
			t_arranque=0
			bash -c "$comando" &
			pid=$!
			echo "$t_arranque $periodo_T $pid $comando" >> procesos_periodicos
			echo "$time: El proceso $pid '$comando' ha nacido" >> Biblia.txt
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
			verificar_pid_en_lista "$2" "procesos_servicio";
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

