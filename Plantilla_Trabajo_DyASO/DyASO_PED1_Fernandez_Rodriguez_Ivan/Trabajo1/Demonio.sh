#!/bin/bash

time=''

# FUNCIONES

# Comprobación de existencia de un proceso por PID
proceso_en_ejecucion() {
    local pid="$1"
    if ps -p "$pid" > /dev/null; then
        return 0  # El proceso está en ejecución
    else
        return 1  # El proceso no está en ejecución
    fi
}

# Resurrección de proceso
resucitar() {
    local pid="$1"
    local comando=$(echo "$2" | sed "s/'//g")
    # Elimina el proceso hijo
    pgrep -P "$pid" | xargs kill -9
    # Elimina el proceso padre con senal KILL
    kill -9 "$pid"
    # Elimina el proceso de la lista, ya que el nuevo no tiene el mismo pid ni ppid
    sed -i "/$pid/d" procesos_servicio
    # Lanza de nuevo el comando
    bash -c "$comando" &
    # Obtiene el pid del padre
    pid=$!
    # Guarda el nuevo proceso en la lista
    echo "$pid $comando" >> procesos_servicio
    time=$(date +%H:%M:%S)
    echo "$time: El proceso $1 resucita con pid $pid" >> Biblia.txt

}

#Bucle mientras que no llegue el apocalipsis
while true; do
    sleep 1  # Espera 1 segundo

# Comprobación del apocalipsis
    if [ -e Apocalipsis ]; then

		# Eliminación de todos los procesos de las listas
        time=$(date +%H:%M:%S)
        echo "$time: -------------Apocalipsis-------------" >> Biblia.txt

        # Eliminacion Procesos servicio
        pServicio="procesos_servicio"
        while IFS=' ' read -r ppidServ comandoPS_completo; do
			# Devuelve la palabra reservada del comando sin comillas
            comandoPS=$(echo "$comandoPS_completo" | awk '{print $1}' | sed "s/'//")
            pkill "$comandoPS"
            echo "$time: El proceso '$comandoPS' ha terminado" >> Biblia.txt
        done < "$pServicio"

        # Eliminacion Procesos normales
        procesos="procesos"
        while IFS=' ' read -r ppid comandoP_completo; do
            kill ppid
            echo "$time: El proceso $comandoP_completo ha terminado" >> Biblia.txt
        done < "$procesos"

        # Eliminacion Procesos periodicos
        pPeriodicos="procesos_periodicos"
        while IFS=' ' read -r T_arranque T ppid comando; do
            kill ppid
            pkill Fausto.sh
            echo "$time: El proceso $comando ha terminado" >> Biblia.txt
        done < "$pPeriodicos"

		# Eliminacion de ficheros
        find -type f \( ! -name "*.sh" -a ! -name "Biblia.txt" -a ! -name "test*" \) -exec rm -f {} \;
        find -type d -exec rm -r -f {} \;
        rm -r -f infierno
        pkill sleep

		# El proceso Demonio se elimina a si mismo
        kill $$
    fi

# Comprobación procesos-servicio

    while IFS=' ' read -r pidServ comando; do
        if ! proceso_en_ejecucion "$pidServ"; then
            resucitar "$pidServ" "$comando"
            break
        fi
    done < "procesos_servicio"

# Comprobación procesos-periodicos

    while read -r t_actual T ppid cmd; do
		time=$(date +%H:%M:%S)
		#Extraemos el tiempo de espera adicional
		espera=$(echo "$cmd" | awk -F ';' '{print $2}')
		nppid=$ppid
		if [ "$espera" -gt 0 ]; then
			T=$(T + espera)
		fi
    	modulo=$((t_actual % T))
    	if [ "$modulo" -eq 0 ]; then
			cmd=$(echo "$cmd" | sed "s/'//")
			eval "$cmd" &
			nppid=$!
			echo "$time: El proceso $ppid se reencarna con pid $nppid" >> Biblia.txt
      		t_actual=$((t_actual + 1))
    	else
        	# Incrementar el tiempo y mantener el proceso en lista si es necesario
        	t_actual=$((t_actual + 1))
    	fi

        # Actualizar la entrada en el archivo procesos_periodicos
        sed -i "/\b$ppid\b/d" procesos_periodicos
		ppid=$nppid
        echo "$t_actual $T $ppid $cmd" >> procesos_periodicos
    done < "procesos_periodicos"
done


