#!/bin/bash

#!/bin/bash

pServicio="procesos_servicio"
while IFS=' ' read -r pidServ comando; do
    echo "pid: $pidServ comando: $comando"
done < "$pServicio"

