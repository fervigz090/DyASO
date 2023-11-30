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
    echo $time: "El proceso $1 resucita con pid $pid" >> Biblia.txt

}

# Lanzamiento procesos periodicos
lanzamiento_periodico() {
    while read -r t_actual T ppid cmd; do
            modulo=$((t_actual % T))
            echo "$modulo" >> probas.txt
        if [ "$modulo" -eq 0 ]; then
            # Ejecutar el comando y mantener el proceso en lista si es necesario
            echo "$cmd dentro if!!!" >> probas.txt
            eval $cmd
            t_actual=$((t_actual + 1))
        else
            # Incrementar el tiempo y mantener el proceso en lista si es necesario
            t_actual=$((t_actual + 1))
        fi

        # Actualizar la entrada en el archivo procesos_periodicos
        sed -i "/\b$ppid\b/d" procesos_periodicos
        echo "$t_actual $T $ppid $cmd" >> procesos_periodicos
    done < "procesos_periodicos"
}

#Directorio donde se ubican los archivos compartidos
DIR_COMPARTIDO="$(dirname "$0")"  #Directorio del script Demonio.sh

#Bucle mientras que no llegue el apocalipsis
while true; do
    sleep 1  # Espera 1 segundo

# Comprobación del apocalipsis
    if [ -e "$DIR_COMPARTIDO/Apocalipsis" ]; then
		# Eliminación de todos los procesos de las listas
        time=$(date +%H:%M:%S)
        echo "$time: -------------Apocalipsis-------------" >> "$DIR_COMPARTIDO/Biblia.txt"

# Bloqueo para evitar acceso simultaneo a las listas
		flock -x 200

        # Eliminacion Procesos servicio
        pServicio="$DIR_COMPARTIDO/procesos_servicio"
        while IFS=' ' read -r ppidServ comandoPS_completo; do
			# Devuelve la palabra reservada del comando sin comillas
            comandoPS=$(echo "$comandoPS_completo" | awk '{print $1}' | sed "s/'//") 
            pkill "$comandoPS"
            echo "$time: El proceso '$comandoPS' ha terminado" >> "$DIR_COMPARTIDO/Biblia.txt"
        done < "$pServicio"

        # Eliminacion Procesos normales
        procesos="$DIR_COMPARTIDO/procesos"
        while IFS=' ' read -r ppid comandoP_completo; do
            kill ppid
            echo "$time: El proceso $comandoP_completo ha terminado" >> "$DIR_COMPARTIDO/Biblia.txt"
        done < "$procesos"

        # Eliminacion Procesos periodicos
        pPeriodicos="$DIR_COMPARTIDO/procesos_periodicos"
        while IFS=' ' read -r T_arranque T ppid comando; do
            kill ppid
            pkill Fausto.sh
            echo "$time: El proceso $comando ha terminado" >> "$DIR_COMPARTIDO/Biblia.txt"
        done < "$pPeriodicos"

		# Eliminacion de ficheros
        find "$DIR_COMPARTIDO" -type f \( ! -name "*.sh" -a ! -name "Biblia.txt" -a ! -name "test*" \) -exec rm -f {} \;
        find "$DIR_COMPARTIDO" -type d -exec rm -r -f {} \;
        rm -r -f "$DIR_COMPARTIDO/infierno"
        pkill sleep

# Liberacion del bloqueo
		flock -u 200

		# El proceso Demonio se elimina a si mismo
        kill $$
    fi

# Comprobación procesos-servicio con bloqueo
	flock -x 200

    while IFS=' ' read -r pidServ comando; do
        if ! proceso_en_ejecucion "$pidServ"; then
            resucitar "$pidServ" "$comando"
            break
        fi
    done < "$DIR_COMPARTIDO/procesos_servicio"

	flock -u 200

# Comprobación procesos-periodicos con bloqueo
	flock -x 200

    while read -r t_actual T ppid cmd; do
        modulo=$((t_actual % T))
        echo "$modulo" >> probas.txt
    if [ "$modulo" -eq 0 ]; then
        # Ejecutar el comando y mantener el proceso en lista si es necesario
        echo "$cmd" >> probas.txt
		cmd=$(echo "$cmd" | sed "s/'//")
		eval "$cmd"
        t_actual=$((t_actual + 1))
    else
        # Incrementar el tiempo y mantener el proceso en lista si es necesario
        t_actual=$((t_actual + 1))
    fi

        # Actualizar la entrada en el archivo procesos_periodicos
        sed -i "/\b$ppid\b/d" procesos_periodicos
        echo "$t_actual $T $ppid $cmd" >> procesos_periodicos
    done < "$DIR_COMPARTIDO/procesos_periodicos"

	flock -u 200

done


