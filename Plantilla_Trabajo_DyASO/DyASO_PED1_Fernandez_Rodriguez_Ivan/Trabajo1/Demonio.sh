#!/bin/bash

#Demonio Dummie, tenéis que completarlo para que haga algo

#Bucle mientras que no llegue el apocalipsis
#   -Espera un segundo
#   -Lee las listas y revive los procesos cuando sea necaario dejando entradas en la biblia
#   -Puede usar todos los ficheros temporales que quiera pero luego en el Apocalipsis hay que borrarlos
#   -Hay que usar un lock para no acceder a las listas a la vez que Fausto
#   -Ojo al cerrar los proceos, hay que terminar el arbol completo no sólo uno de ellos
#Fin bucle

#Apocalipsis: termino todos los procesos y limpio todo dejando sólo Fausto, el Demonio y la Biblia

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
    local comando="$2"
    eval "$comando" &
    echo "El demonio ha resucitado al proceso con PID $pid" >> Biblia.txt
}

while true; do
    sleep 1  # Espera 1 segundo

    # Comprobación del apocalipsis
    if [ -e Apocalipsis ]; then
        # Eliminación de todos los procesos excepto Fausto, el Demonio y la Biblia
        for procesos in "procesos"; do
			pid=$(echo "$proceso" | awk '{print $1}')
			kill "$pid" 2>/dev/null
		done

		for procesos in "procesos_servicio"; do
			pid=$(echo "$proceso" | awk '{print $1}')
			kill "$pid" 2>/dev/null
		done

        rm -f Apocalipsis
		pidDemonio=$(pgrep -f -o "Demonio.sh")
		kill &pidDemonio
    fi

    # Comprobación procesos-servicio
    pServicio="procesos_servicio"
    while IFS=' ' read -r pidServ comando; do
        if proceso_en_ejecucion "$pidServ"; then
            echo "El proceso con PID $pidServ está en ejecución"
        else
            resucitar "$pidServ" "$comando"
        fi
    done < "$pServicio"
done
