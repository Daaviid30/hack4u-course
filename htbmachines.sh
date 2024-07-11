#!/bin/bash

#Colours
greenColour="\e[0;32m\033[1m"
endColour="\033[0m\e[0m"
redColour="\e[0;31m\033[1m"
blueColour="\e[0;34m\033[1m"
yellowColour="\e[0;33m\033[1m"
purpleColour="\e[0;35m\033[1m"
turquoiseColour="\e[0;36m\033[1m"
grayColour="\e[0;37m\033[1m"

# Función que se ejecuta tras pulsar Ctrl+C
function ctrl_c(){
    echo -e "\n\n${redColour}[!]${endColour}${yellowColour} Saliendo de la ejecución del script htbmachines...${endColour}\n"
    exit 1
}

# Capturamos la señal de ctrl+C
trap ctrl_c INT

# Variables globales
main_url="https://htbmachines.github.io/bundle.js"

# Funcion para mostrar el panel de ayuda
function helpPanel(){
    echo -e "\n${redColour}[+]${endColour}${yellowColour} Panel de ayuda${endColour}\n"
    echo -e "\tEjecución del script:${greenColour}./htbmachines {parametros}${endColour}\n"
    echo -e "\t${turquoiseColour}Parametros:${endColour}\n"
    echo -e "\t${turquoiseColour}-m (nombre maquina):${endColour} Busca por el nombre de una maquina en concreto\n"
    echo -e "\t${turquoiseColour}-h:${endColour} Muestra el panel de ayuda del script\n"
    echo -e "\t${turquoiseColour}-u:${endColour} Actualiza o descarga el archivo bundle.js y añade nuevas maquinas\n"
    echo -e "\t${turquoiseColour}-i (IP maquina):${endColour} Buscar nombre de una maquina con una dirección IP específica\n"
    echo -e "\t${turquoiseColour}-y (nombre maquina):${endColour} Buscar el link a la resolucion de una maquina determinada en youtube por su nombre\n"
    echo -e "\t${turquoiseColour}-d (dificultad):${endColour} Buscar maquinas filtrando por un nivel de dificultad determinado\n"
    echo -e "\t${turquoiseColour}-o (sistema operativo):${endColour} Buscar maquinas filtrando por un sistema operativo determinado\n"
    echo -e "\t${turquoiseColour}-s (skill):${endColour} Buscar maquinas filtrando por una skill determinada\n"
}

# Función que actualiza el los archivos necesarios para el script
function updateBundle(){
    # Si no existe el fichero bundle.js, lo descargamos
    if [ ! -f bundle.js ]; then
        echo -e "\n${purpleColour}[+] Descargando archivos necesarios...${endColour}\n"
        curl -s -X GET $main_url > bundle.js
        js-beautify bundle.js | sponge bundle.js
        echo -e "\n${greenColour}[+] Archivos descargados exitoxamente${endColour}\n"
    else
        curl -s -X GET $main_url > bundle_temp.js
        js-beautify bundle_temp.js | sponge bundle_temp.js
        # Comprobamos el hash del fichero que tenemos y del que nos descargamos para ver si son iguales, si no lo son
        # cambiamos el antiguo fichero por el nuevo
        if [ $(md5sum bundle_temp.js | awk '{print $1}') == $(md5sum bundle.js | awk '{print $1}') ]; then
            echo -e "\n${greenColour}[+] Los archivos ya estan actualizados${endColour}\n"
            rm bundle_temp.js
        else
            echo -e "\n${purpleColour}[+] Descargando nueva version disponible...${endColour}\n"
            sleep 1
            rm bundle.js && mv bundle_temp.js bundle.js
            echo -e "\n${greenColour}[+] Archivos descargados exitoxamente${endColour}\n"
        fi  
    fi
}

# Funcion cuando se pasa el argumento -m
function searchMachine(){
    machineName="$1"
    existeMaquina="$(cat bundle.js | grep "name: \"$machineName\"")"
    if [ -n "$existeMaquina" ]; then
        echo -e "\n${purpleColour}[+] Listando las propiedades de la maquina:${endColour}${turquoiseColour} $machineName ${endColour}\n"
        cat bundle.js | awk "/name: \"$machineName\"/,/resuelta:/" | grep -vE "id:|sku:|resuelta" | tr -d '"' | tr -d ','
        echo -e "\n"
    else
        echo -e "\n${redColour}[!] El nombre $machineName no coincide con ninguna maquina${endColour}\n"
        exit 1
    fi
}

# Funcion cuando se pasa el argumento -i
function searchIP(){
    machineIP="$1"
    machineName="$(cat bundle.js | grep "ip: \"$machineIP\"" -B 4 | grep "name" | awk 'NF{print $NF}' | tr -d '"' | tr -d ',')"
    if [ -n "$machineName" ]; then
        echo -e "\n${purpleColour}[+] La maquina correspondiente a la IP $machineIP es:${endColour}${turquoiseColour} $machineName ${endColour}\n"
    else
        echo -e "\n${redColour}[!] La IP $machineIP no coincide con ninguna maquina${endColour}\n"
        exit 1
    fi
}

# Funcion cuando se pasa el argumento -y
function searchLink(){
    machineName="$1"
    youtubeLink="$(cat bundle.js | awk "/name: \"$machineName\"/, /youtube:/" | tail -n 1 | awk 'NF{print $NF}' | tr -d '"' | tr -d ',')"
    if [ -n "$youtubeLink" ]; then
        echo -e "\n${greenColour}[+] El enlace a la resolucion de la maquina $machineName en Youtube es: ${endColour}${purpleColour}$youtubeLink${endColour}\n"
    else
        echo -e "\n${redColour}[!] El nombre $machineName no coincide con ninguna maquina o dicha maquina no tiene resolucion en Youtube${endColour}\n"
        exit 1
    fi
}

# Funcion cuando se pasa el argumento -d
function searchDifficulty(){
    machineDifficulty="$1"
    if [ "$machineDifficulty" == "Fácil" ];then
        difficultyColour=${greenColour}
    elif [ "$machineDifficulty" == "Media" ]; then
        difficultyColour=${yellowColour}
    elif [ "$machineDifficulty" == "Difícil" ]; then
        difficultyColour=${redColour}
    else
        difficultyColour=${purpleColour}
    fi
    machines="$(cat bundle.js | grep "dificultad: \"$machineDifficulty\"" -B 5 | grep "name:" | awk 'NF{print $NF}' | tr -d '"' | tr -d ',' | column)"
    if [ -n "$machines" ]; then
        echo -e "\n${yellowColour}[+] Las maquinas con dificultad${endColour}${difficultyColour} $machineDifficulty${endColour}${yellowColour} son:${endColour}\n"
        cat bundle.js | grep "dificultad: \"$machineDifficulty\"" -B 5 | grep "name:" | awk 'NF{print $NF}' | tr -d '"' | tr -d ',' | column
    else
        echo -e "\n${redColour}[!] El nivel de dificultad introducido no existe.\n\nDificultades disponibles: Fácil, Media, Difícil, Insane.${endColour}\n"
        exit 1
    fi

}

# Funcion para cuando se pasa el argumento -o
function searchSystem(){
    machineSystem=$1
    machines="$(cat bundle.js | grep "so: \"$machineSystem\"" -B 5 | grep "name:" | awk 'NF{print $NF}' | tr -d '"' | tr -d ',' | column)"

    if [ -n "$machines" ]; then
        echo -e "\n${purpleColour}[+] Las maquinas con el sistema operativo${endColour}${redColour} $machineSystem${endColour}${purpleColour} son:${endColour}\n"
        cat bundle.js | grep "so: \"$machineSystem\"" -B 5 | grep "name:" | awk 'NF{print $NF}' | tr -d '"' | tr -d ',' | column
    else
        echo -e "\n${redColour}[!] No se encuentra ninguna maquina con el sistema operativo introducido\n\nSistemas operativos disponibles: Windows, Linux${endColour}\n"
        exit 1
    fi
}

# Funcion para cunado se pasan los argumetos -d y -o
function searchSystemDifficulty(){
    machineSystem=$1
    machiineDifficulty=$2
    machines="$(cat bundle.js | grep "so: \"$machineSystem\"" -B 5 -A 1 | grep "dificultad: \"$machineDifficulty\"" -B 6 | grep "name:" | awk 'NF{print $NF}' | tr -d ',' | tr -d '"' | column)"
    if [ "$machineDifficulty" == "Fácil" ];then
        difficultyColour=${greenColour}
    elif [ "$machineDifficulty" == "Media" ]; then
        difficultyColour=${yellowColour}
    elif [ "$machineDifficulty" == "Difícil" ]; then
        difficultyColour=${redColour}
    else
        difficultyColour=${purpleColour}
    fi

    if [ -n "$machines" ]; then
        echo -e "\n${turquoiseColour}[+] Las maquinas con el SO ${endColour}${redColour}$machineSystem${endColour}${turquoiseColour} y con la dificultad ${endColour}${difficultyColour}$machineDifficulty${endColour}${turquoiseColour} son:${endColour}\n"
        cat bundle.js | grep "so: \"$machineSystem\"" -B 5 -A 1 | grep "dificultad: \"$machineDifficulty\"" -B 6 | grep "name:" | awk 'NF{print $NF}' | tr -d ',' | tr -d '"' | column
    else
        echo -e "\n${redColour}[!] No se han encontrado maquinas con el SO y nivel de dificultad pasados como argumentos${endColour}\n"
        exit 1
    fi

}

# Funcion para cuando se pasa el argumento -s
function searchSkill(){
    skill=$1
    machines="$(cat bundle.js | grep "skills:" -B 6 | grep -i "$skill" -B 6 | grep "name:" | awk 'NF{print $NF}' | tr -d ',' | tr -d '"' | column)"
    
    if [ -n "$machines" ]; then
        echo -e "\n${purpleColour}[+] Las maquinas con la skill${endColour}${redColour} $skill${endColour}${purpleColour} son:${endColour}\n"
        cat bundle.js | grep "skills:" -B 6 | grep -i "$skill" -B 6 | grep "name:" | awk 'NF{print $NF}' | tr -d ',' | tr -d '"' | column
    else
        echo -e "\n${redColour}[!] No se han encontrado maquinas con la skill introducida${endColour}\n"
        exit 1
    fi
}
# Creamos el bucle que nos permitira leer los argumentos que se le pasen al script
# -m -> Para indicar el nombre de la maquina que se quiere buscar
# -h -> Para mostrar panel de ayuda

# Creamos una variable para según que argumentos se reciban, se determine un flujo de salida para el bucle
declare -i parameter_counter=0
declare -i arg_difficulty=0
declare -i arg_system=0

while getopts "m:ui:y:d:o:s:h" arg; do
    case $arg in
        m) machineName=$OPTARG; let parameter_counter+=1;;
        u) let parameter_counter+=2;;
        i) machineIP=$OPTARG; let parameter_counter+=3;;
        y) machineName=$OPTARG; let parameter_counter+=4;;
        d) machineDifficulty=$OPTARG; arg_difficulty=1; let parameter_counter+=5;;
        o) machineSystem=$OPTARG; arg_system=1; let parameter_counter+=6;;
        s) skill="$OPTARG"; let parameter_counter+=7;;
        h) ;;
    esac    
done

if [ $parameter_counter -eq 1 ]; then
    searchMachine $machineName
elif [ $parameter_counter -eq 2 ]; then
    updateBundle
elif [ $parameter_counter -eq 3 ]; then
    searchIP $machineIP
elif [ $parameter_counter -eq 4 ]; then
    searchLink $machineName
elif [ $parameter_counter -eq 5 ]; then
    searchDifficulty $machineDifficulty
elif [ $parameter_counter -eq 6 ]; then
    searchSystem $machineSystem
elif [ $parameter_counter -eq 7 ]; then
    searchSkill "$skill"
# Consideramos otro caso en el cual se combinen los argumentos -o y -d
elif [ $arg_difficulty -eq 1 ] && [ $arg_system -eq 1 ]; then
    searchSystemDifficulty $machineSystem $machineDifficulty
else
    helpPanel
fi