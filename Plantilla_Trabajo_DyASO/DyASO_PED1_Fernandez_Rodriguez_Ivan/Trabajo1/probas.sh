
linea_demonio=$(ps l | grep [D]emonio)
echo "$linea_demonio"
pid_demonio=$(echo $linea_demonio | cut -d " " -f3)
echo "$pid_demonio"
pstree -s $pid_demonio
