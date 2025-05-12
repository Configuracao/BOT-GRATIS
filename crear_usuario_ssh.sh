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

# Verificar que se ejecuta como root
if [ "$(id -u)" -ne 0 ]; then
    echo "Este script debe ejecutarse como root"
    exit 1
fi

# Valores por defecto
USUARIO=""
CONTRASENA=""
DIAS=30
CONECCIONES=1
DB_PATH="/etc/SSHPlus/usuarios.db"

# Procesar argumentos
while [[ "$1" != "" ]]; do
    case $1 in
        -h | --help) mostrar_ayuda ;;
        -u | --user) shift; USUARIO=$1 ;;
        -p | --pass) shift; CONTRASENA=$1 ;;
        -d | --dias) shift; DIAS=$1 ;;
        -c | --coneccion) shift; CONECCIONES=$1 ;;
        *) echo "Opción no válida: $1"; mostrar_ayuda ;;
    esac
    shift
done

# Verificar campos obligatorios
if [ -z "$USUARIO" ] || [ -z "$CONTRASENA" ]; then
    echo "Se debe especificar un nombre de usuario y una contraseña."
    mostrar_ayuda
fi

# Crear usuario
EXPIRA=$(date -d "$DIAS days" +%Y-%m-%d)
useradd -M -s /bin/false -e "$EXPIRA" "$USUARIO"
echo "$USUARIO:$CONTRASENA" | chpasswd

# Limitar conexiones individuales
sed -i "/^$USUARIO .* maxlogins/d" /etc/security/limits.conf
echo "$USUARIO hard maxlogins $CONECCIONES" >> /etc/security/limits.conf

# Asegurar que pam_limits esté activo
grep -q "pam_limits.so" /etc/pam.d/sshd || echo "session required pam_limits.so" >> /etc/pam.d/sshd
systemctl restart sshd

# Guardar en usuarios.db
mkdir -p "$(dirname "$DB_PATH")"
EXPIRA_HUMANA=$(date -d "$DIAS days" +"%d-%m-%Y")
echo "$USUARIO|$CONTRASENA|$EXPIRA_HUMANA|$CONECCIONES" >> "$DB_PATH"

# Mostrar info
echo ""
echo "Usuario creado exitosamente:"
echo "-----------------------------"
echo "Usuario     : $USUARIO"
echo "Contraseña  : $CONTRASENA"
echo "Expira el   : $EXPIRA_HUMANA"
echo "Conexiones  : $CONECCIONES"
echo "Guardado en : $DB_PATH"
echo "-----------------------------"