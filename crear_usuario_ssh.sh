#!/bin/bash

function mostrar_ayuda {
    echo "Uso: $0 [opciones]"
    echo "Opciones:"
    echo "  -u, --user           Nombre de usuario"
    echo "  -p, --pass           Contraseña"
    echo "  -d, --dias           Días de validez"
    echo "  -c, --coneccion      Conexiones permitidas"
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
DIAS=""
CONECCIONES=1
ELIMINAR=0

# Procesar parámetros
while [[ "$1" != "" ]]; do
    case "$1" in
        -u|--user) shift; USUARIO="$1" ;;
        -p|--pass) shift; CONTRASENA="$1" ;;
        -d|--dias) shift; DIAS="$1" ;;
        -c|--coneccion) shift; CONECCIONES="$1" ;;
        --delete) ELIMINAR=1 ;;
        -h|--help) mostrar_ayuda ;;
        *) echo "Opción inválida: $1"; mostrar_ayuda ;;
    esac
    shift
done

DB_PATH="/root/usuarios.db"

if [ "$ELIMINAR" -eq 1 ]; then
    if [ -z "$USUARIO" ]; then
        echo "Debes especificar el usuario a eliminar con -u"
        exit 1
    fi
    userdel -f "$USUARIO" && sed -i "/^$USUARIO /d" "$DB_PATH"
    echo "Usuario '$USUARIO' eliminado correctamente."
    exit 0
fi

if [ -z "$USUARIO" ] || [ -z "$CONTRASENA" ] || [ -z "$DIAS" ]; then
    echo "Faltan parámetros obligatorios."
    mostrar_ayuda
fi

# Crear usuario
useradd -M -s /bin/false -e $(date -d "$DIAS days" +%Y-%m-%d) "$USUARIO"
echo "$USUARIO:$CONTRASENA" | chpasswd

# Guardar datos
echo "$USUARIO $DIAS $CONECCIONES" >> "$DB_PATH"

# Mostrar resultado
FECHA_EXPIRA=$(chage -l "$USUARIO" | grep "Account expires" | cut -d: -f2 | xargs)
echo ""
echo "Usuario creado:"
echo "------------------------"
echo "Usuario     : $USUARIO"
echo "Contraseña  : $CONTRASENA"
echo "Días        : $DIAS"
echo "Conexiones  : $CONECCIONES"
echo "Expira el   : $FECHA_EXPIRA"
echo "------------------------"