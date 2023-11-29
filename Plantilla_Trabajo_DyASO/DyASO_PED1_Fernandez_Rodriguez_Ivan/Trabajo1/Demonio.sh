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
	# Lanza de nuevo el comando como hijo de un proceso bash
	bash -c "$comando" &
	# Obtiene el pid del padre
	pid=$!
	# Guarda el nuevo proceso en la lista
	echo "$pid $comando" >> procesos_servicio
	time=$(date +%H:%M:%S)
    echo $time: "El proceso $1 resucita con pid $pid" >> Biblia.txt

}

# Comienza el proceso Demonio
while true; do
    sleep 1  # Espera 1 segundo

    # Comprobación del apocalipsis
    if [ -e Apocalipsis ]; then
        # Eliminación de todos los procesos de las listas
		time=$(date +%H:%M:%S)
        echo "$time: -------------Apocalipsis-------------" >> Biblia.txt

		# Procesos servicio
      	pServicio="procesos_servicio"
		while IFS=' ' read -r ppidServ comandoPS_completo; do
        	comandoPS=$(echo "$comandoPS_completo" | awk '{print $1}' | sed "s/'//") # Devuelve la palabra reservada del comando sin comillas
			pkill "$comandoPS"
			echo $time:" El proceso '$comandoPS' ha terminado" >> Biblia.txt
		done < "$pServicio"

		# Procesos normales
		procesos="procesos"
		while IFS=' ' read -r ppid comandoP_completo; do
			kill ppid
			echo $time:" El proceso '$comandoP' ha terminado" >> Biblia.txt
		done < "$procesos"

		# Procesos periodicos
		pPeriodicos="procesos_periodicos"
		while IFS=' ' read -r T_arranque T ppid comando; do
			kill ppid
			pkill Fausto.sh
			echo $time:" El proceso '$comando' ha terminado" >> Biblia.txt
		done < "$pPeriodicos"

		find -type f \( ! -name "*.sh" -a ! -name "Biblia.txt" -a ! -name "test*" \) -exec rm -f {} \;
		find -type d -exec rm -r -f;
		rm -r -f infierno
		pkill sleep
		kill $$ # Demonio.sh se elimina a si mismo
    fi

    # Comprobación procesos-servicio
    while IFS=' ' read -r pidServ comando; do
        if ! proceso_en_ejecucion "$pidServ"; then
            resucitar "$pidServ" "$comando"
			break
        fi
    done < "procesos_servicio"

	# Comprobacion procesos-periodicos
	while IFS=' ' read -r t_actual T ppid cmd; do
		# Comprueba si t_actual es multiplo de T
		modulo=$((t_actual % T))
		if [ "$modulo" -eq 0 ]; then
			eval "$cmd"
			sed -i "/\b$ppid\b/d" procesos_periodicos
			t_actual=$((t_actual + 1))
			echo "$t_actual $T $ppid $cmd" >> procesos_periodicos
		else
			# elimina el proceso de la lista y lo reintroduce con el tiempo actualizado
			sed -i "/\b$ppid\b/d" procesos_periodicos
			t_actual=$((t_actual + 1))
			echo "$t_actual $T $ppid $cmd" >> procesos_periodicos
		fi
	done < "procesos_periodicos"
done













