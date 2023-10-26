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
# Resurreccion de proceso
resucitar() {
	local proceso="$1"
	echo "El demonio ha resucitado a '$1'" >> Biblia.txt
	./"$proceso".sh &
}

time=$(date +%H:%M:%S)
while true; do
	sleep 1 #espera 1 segundo
	# comprobacion apocalipsis
	if [ -e Apocalipsis ]; then
		# eliminacion del proceso demonio
		pid_demonio=$(ps -C 'Demonio.sh' -o pid,cmd | grep -v 'color' | awk '{print $1}' | sed '/^PID$/d')
		for pid in $pid_demonio; do
			kill -9 "$pid"
		done
	fi

	# comprobacion procesos-servicio
	for proceso in "$procesos_servicio"; do
		#Comprueba que el proceso esta en ejecucion
		
	done
done






