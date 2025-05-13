#!/bin/bash

function mostrar_ayuda {
    echo "Uso: $0 [opciones]"
    echo "Opciones:"
    echo "  -u, --user           Nombre de usuario"
    echo "  -p, --pass           Contraseña"
    echo "  -d, --dias           Días de validez"
    echo "  --delete             Eliminar usuario"
    echo "  -h, --help           Mostrar esta ayuda"
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
ELIMINAR=0
CONECCIONES=1  # Se establece por defecto a 1

while [[ "$1" != "" ]]; do
    case $1 in
        -h|--help) mostrar_ayuda ;;
        -u|--user) shift; USUARIO="$1" ;;
        -p|--pass) shift; CONTRASENA="$1" ;;
        -d|--dias) shift; DIAS="$1" ;;
        --delete) ELIMINAR=1 ;;
        *) echo "Opción inválida: $1"; mostrar_ayuda ;;
    esac
    shift
done

if [ -z "$USUARIO" ]; then
    echo "Debes especificar un nombre de usuario con -u"
    mostrar_ayuda
fi

DB_PATH="/root/usuarios.db"

if [ "$ELIMINAR" -eq 1 ]; then
    # Eliminar usuario
    userdel -f "$USUARIO"
    sed -i "/^$USUARIO /d" "$DB_PATH"
    echo "Usuario '$USUARIO' eliminado correctamente."
    exit 0
fi

if [ -z "$CONTRASENA" ]; then
    echo "Debes especificar una contraseña con -p"
    mostrar_ayuda
fi

# Crear el usuario
useradd -M -s /bin/false -e $(date -d "$DIAS days" +%Y-%m-%d) "$USUARIO"
echo "$USUARIO:$CONTRASENA" | chpasswd

# Registrar en base de datos
echo "$USUARIO $DIAS $CONECCIONES" >> "$DB_PATH"

# Mostrar información
FECHA_EXPIRA=$(chage -l "$USUARIO" | grep "Account expires" | cut -d: -f2)
echo ""
echo "Usuario creado:"
echo "------------------------"
echo "Usuario     : $USUARIO"
echo "Contraseña  : $CONTRASENA"
echo "Expira el   : $FECHA_EXPIRA"
echo "Conexiones  : $CONECCIONES"
echo "------------------------"