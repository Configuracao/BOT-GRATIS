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

# Verificar si ya existe
if id "$USUARIO" &>/dev/null; then
    echo "El usuario '$USUARIO' ya existe."
    exit 1
fi

# Crear el usuario con expiración
useradd -M -s /bin/false -e $(date -d "$DIAS days" +%Y-%m-%d) "$USUARIO"
echo "$USUARIO:$CONTRASENA" | chpasswd

# Registrar en la base de datos SSHPLUS
DB_PATH="/etc/SSHPlus/usuarios.db"
FECHA_EXPIRA=$(date -d "$DIAS days" +"%d-%m-%Y")

if [ -d "/etc/SSHPlus" ]; then
    echo "$USUARIO|$CONTRASENA|$FECHA_EXPIRA|$CONECCIONES" >> "$DB_PATH"
fi

# Limitar conexiones por usuario
LIMITS_FILE="/etc/security/limits.conf"
echo "$USUARIO hard maxlogins $CONECCIONES" >> "$LIMITS_FILE"

# Mostrar resumen
echo ""
echo "Usuario creado:"
echo "------------------------"
echo "Usuario     : $USUARIO"
echo "Contraseña  : $CONTRASENA"
echo "Expira el   : $FECHA_EXPIRA"
echo "Tipo        : $TIPO"
echo "Límite SSH  : $CONECCIONES conexiones"
echo "------------------------"