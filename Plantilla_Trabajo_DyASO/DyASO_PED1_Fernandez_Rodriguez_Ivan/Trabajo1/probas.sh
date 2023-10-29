#!/bin/bash

pServicio="procesos_servicio"
while IFS=' ' read -r pidServ comando_completo; do
	comando=$(echo "$comando_completo" | awk '{print $1}' | sed "s/'//") # Devuelve la palabra reservada del comando sin comillas
    pkill $comando
done < "$pServicio"

