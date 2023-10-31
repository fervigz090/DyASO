#!/bin/bash


# FUNCIONES

# Creacion de archivos al inicio
inicializar (){
	touch procesos
	touch procesos_servicio
	touch Biblia.txt
	touch SanPedro
	mkdir infierno
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

# Invocacion del demonio
verificar_y_lanzar_demonio() {
    if pgrep -x "Demonio.sh" >/dev/null; then
        echo "El proceso Demonio.sh ya está en ejecución."
    else
        echo "El proceso Demonio.sh no está en ejecución. Iniciando..."
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
	local lista_procesos="$2"
	pid_exec=$(ps -l | awk '{print $4}' | grep -v PID)
	ppid_exec=$(ps -l | awk '{print $5}' | grep -v PPID)
	check=0
	for proceso in $pid_exec; do    # comprueba si esta en ejecucion
   	    if [ "$proceso" == "$pid" ]; then
		    check=1
            break   # sale del bucle si encuentra el pid
		fi
	done

	if [ "$check" -eq 0 ]; then
		echo "Error! el proceso con PID: $pid no esta en ejecucion"
	
		# El proceso esta en ejecucion, asi que buscamos su PPID en las listas
	fi

}

# Ejecucion del comando



#Recibe órdenes creando los procesos y listas adecuadas

if [ $# -eq 0 ]; then	#Si no hay argumentos se verifica la existencia del demonio
	verificar_y_lanzar_demonio;
else
	time=$(date +%H:%M:%S)
	comando="$2"
	case "$1" in
		"run")	#ejecuta un comando una sola vez
			bash -c "$2" &	#instancia de bash en segundo plano
			pid=$!	#obtenemos el pid del proceso bash
			echo "$pid '$2'" >> procesos
			echo "$time: El proceso $pid '$2' ha nacido" >> Biblia.txt
			;;
		"run-service")
			bash -c "$2" &
			pid=$!
			echo "$pid '$2'" >> procesos_servicio
			echo "$time: El proceso $pid '$2' ha nacido" >> Biblia.txt
			;;
		"run-periodic")
			echo "run-periodic ok"
			;;
		"list")
			echo "***** Procesos normales *****"
			procesos="procesos"
            while IFS=' ' read -r ppid comandoP_completo; do
                comandoP=$(echo "comandoP_completo" | awk '{print $1}' | sed "s/'//")
              
            done < "$procesos"
			echo "***** Procesos servicio *****"

			echo "***** Procesos periodicos *****"
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
			verificar_pid_en_lista "$2" "procesos";
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

