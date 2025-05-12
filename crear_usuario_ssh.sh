#!/bin/bash

# Función para mostrar la ayuda
function mostrar_ayuda {
    echo "Uso: $0 [-u usuario] [-p contraseña] [-d dias] [-c conexiones]"
    echo "Opciones:"
    echo "  -h, --help           Mostrar esta ayuda"
    echo "  -u, --user           Especificar un nombre de usuario"
    echo "  -p, --pass           Especificar una contraseña"
    echo "  -d, --dias           Cantidad de días de validez"
    echo "  -c, --coneccion      Número de conexiones simultáneas permitidas"
    exit 1
}

# Comprobar si el script se ejecuta como root
if [ "$(id -u)" -ne 0 ]; then
    echo "Este script debe ejecutarse como root"
    exit 1
fi

# Valores por defecto
USUARIO=""
CONTRASENA=""
DIAS=30
CONECCIONES=10

# Procesar las opciones de la línea de comandos
while [[ "$1" != "" ]]; do
    case $1 in
        -h | --help)
            mostrar_ayuda
            ;;
        -u | --user)
            shift
            USUARIO=$1
            ;;
        -p | --pass)
            shift
            CONTRASENA=$1
            ;;
        -d | --dias)
            shift
            DIAS=$1
            ;;
        -c | --coneccion)
            shift
            CONECCIONES=$1
            ;;
        *)
            echo "Opción no válida: $1"
            mostrar_ayuda
            ;;
    esac
    shift
done

# Verificar que se han proporcionado el nombre de usuario y la contraseña
if [ -z "$USUARIO" ] || [ -z "$CONTRASENA" ]; then
    echo "Se debe especificar un nombre de usuario y una contraseña."
    mostrar_ayuda
fi

# Crear el usuario con la expiración y sin acceso shell
useradd -M -s /bin/false -e $(date -d "$DIAS days" +%Y-%m-%d) "$USUARIO"

# Establecer la contraseña
echo "$USUARIO:$CONTRASENA" | chpasswd

# Mostrar información del usuario
FECHA_EXPIRA=$(chage -l "$USUARIO" | grep "Account expires" | cut -d: -f2)
echo ""
echo "Usuario creado exitosamente:"
echo "-----------------------------"
echo "Usuario     : $USUARIO"
echo "Contraseña  : $CONTRASENA"
echo "Expira el   : $FECHA_EXPIRA"
echo "-----------------------------"

# Limitar las conexiones simultáneas
if [ "$CONECCIONES" -gt 0 ]; then
    echo "MaxSessions $CONECCIONES" >> /etc/ssh/sshd_config
    echo "MaxStartups 1:$CONECCIONES:$CONECCIONES" >> /etc/ssh/sshd_config
    systemctl restart sshd
    echo "Conexiones SSH limitadas a $CONECCIONES por usuario."
fi