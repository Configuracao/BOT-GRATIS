#!/bin/bash

function mostrar_ayuda {
    echo "Uso: $0 [-u usuario] [-p contraseña] [-d dias] [-c conexiones] [-t tipo]"
    echo "Opciones:"
    echo "  -h, --help           Mostrar esta ayuda"
    echo "  -u, --user           Nombre de usuario"
    echo "  -p, --pass           Contraseña"
    echo "  -d, --dias           Días de validez"
    echo "  -c, --coneccion      Conexiones permitidas"
    echo "  -t, --tipouser       Tipo de usuario (opcional)"
    exit 1
}

if [ "$(id -u)" -ne 0 ]; then
    echo "Este script debe ejecutarse como root"
    exit 1
fi

# Valores por defecto
USUARIO=""
CONTRASENA=""
DIAS=30
CONECCIONES=1
TIPO="normal"

while [[ "$1" != "" ]]; do
    case $1 in
        -h|--help) mostrar_ayuda ;;
        -u|--user) shift; USUARIO="$1" ;;
        -p|--pass) shift; CONTRASENA="$1" ;;
        -d|--dias) shift; DIAS="$1" ;;
        -c|--coneccion) shift; CONECCIONES="$1" ;;
        -t|--tipouser) shift; TIPO="$1" ;;
        *) echo "Opción inválida: $1"; mostrar_ayuda ;;
    esac
    shift
done

if [ -z "$USUARIO" ] || [ -z "$CONTRASENA" ]; then
    echo "Usuario y contraseña son obligatorios."
    mostrar_ayuda
fi

# Crear el usuario
useradd -M -s /bin/false -e $(date -d "$DIAS days" +%Y-%m-%d) "$USUARIO"
echo "$USUARIO:$CONTRASENA" | chpasswd

# Registrar en base de datos usada por SSHPLUS
DB_PATH="/root/usuarios.db"
echo "$USUARIO $DIAS $CONECCIONES $TIPO" >> "$DB_PATH"

# Mostrar información
FECHA_EXPIRA=$(chage -l "$USUARIO" | grep "Account expires" | cut -d: -f2)
echo ""
echo "Usuario creado:"
echo "------------------------"
echo "Usuario     : $USUARIO"
echo "Contraseña  : $CONTRASENA"
echo "Expira el   : $FECHA_EXPIRA"
echo "Conexiones  : $CONECCIONES"
echo "Tipo        : $TIPO"
echo "------------------------"

# IMPORTANTE: El control de conexiones simultáneas por usuario DEBE hacerse con scripts que monitorean conexiones activas (como hace SSHPLUS).