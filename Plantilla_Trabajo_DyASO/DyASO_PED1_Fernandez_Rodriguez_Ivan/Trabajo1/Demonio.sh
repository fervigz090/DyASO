#!/bin/bash

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

        # Eliminacion Procesos servicio
        pServicio="$DIR_COMPARTIDO/procesos_servicio"
        while IFS=' ' read -r ppidServ comandoPS_completo; do
            comandoPS=$(echo "$comandoPS_completo" | awk '{print $1}' | sed "s/'//") # Devuelve la palabra reservada del comando sin comillas
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

		# El proceso Demonio se elimina a si mismo
        kill $$
    fi

    # Comprobación procesos-servicio
    while IFS=' ' read -r pidServ comando; do
        if ! proceso_en_ejecucion "$pidServ"; then
            resucitar "$pidServ" "$comando"
            break
        fi
    done < "$DIR_COMPARTIDO/procesos_servicio"

    # Comprobación procesos-periodicos
    lanzamiento_periodico &
done

