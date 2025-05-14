#!/bin/bash

function mostrar_ayuda {
    echo "Uso: $0 -u usuario -d dias -c conexiones"
    echo "  -u, --user        Nombre de usuario"
    echo "  -d, --dias        Días de validez"
    echo "  -c, --coneccion   Conexiones permitidas"
    echo "  --delete          Eliminar usuario"
    echo "  -h, --help        Mostrar esta ayuda"
    exit 1
}

if [ "$(id -u)" -ne 0 ]; then
    echo "Este script debe ejecutarse como root"
    exit 1
fi

# Variables
USUARIO=""
DIAS=31
CONECCIONES=1
ELIMINAR=0
DB_PATH="/etc/SSHPlus/usuarios.db"
TOKEN_PATH="/etc/SSHPlus/Token.txt"

while [[ "$1" != "" ]]; do
    case $1 in
        -h|--help) mostrar_ayuda ;;
        -u|--user) shift; USUARIO="$1" ;;
        -d|--dias) shift; DIAS="$1" ;;
        -c|--coneccion) shift; CONECCIONES="$1" ;;
        --delete) ELIMINAR=1 ;;
        *) echo "Opción inválida: $1"; mostrar_ayuda ;;
    esac
    shift
done

if [ -z "$USUARIO" ]; then
    echo "Debes especificar un nombre de usuario con -u"
    mostrar_ayuda
fi

if [ "$ELIMINAR" -eq 1 ]; then
    userdel -f "$USUARIO"
    sed -i "/^$USUARIO|/d" "$DB_PATH"
    rm -f "/etc/SSHPlus/senha/$USUARIO"
    echo "Usuario '$USUARIO' eliminado correctamente."
    exit 0
fi

if [ ! -f "$TOKEN_PATH" ]; then
    echo "Archivo de contraseña $TOKEN_PATH no encontrado."
    exit 1
fi

# Leer contraseña desde el archivo
CONTRASENA=$(cat "$TOKEN_PATH")

# Calcular fecha de expiración
EXPIRA=$(date -d "+$DIAS days" +%Y-%m-%d)
FECHA_FORMATO=$(date -d "$EXPIRA" +%d-%m-%Y)

# Crear usuario
useradd -M -s /bin/false -e "$EXPIRA" "$USUARIO"
echo "$USUARIO:$CONTRASENA" | chpasswd

# Guardar en la base de datos
mkdir -p /etc/SSHPlus/senha
echo "$CONTRASENA" > "/etc/SSHPlus/senha/$USUARIO"
echo "$USUARIO|$CONTRASENA|$FECHA_FORMATO|$CONECCIONES" >> "$DB_PATH"

# Mostrar resumen
echo ""
echo "Usuario tipo TOKEN creado:"
echo "------------------------"
echo "Usuario     : $USUARIO"
echo "Contraseña  : $CONTRASENA"
echo "Expira el   : $FECHA_FORMATO"
echo "Conexiones  : $CONECCIONES"
echo "------------------------"