#!/usr/bin/env bash
# ==============================================================================
# ASUS ROG CONTROL CENTER - Instalador Universal para Linux
# Compatible con: Ubuntu, Debian, Fedora, Arch Linux, Manjaro, Pop!_OS, Mint
# ==============================================================================
set -e

if [ "$EUID" -ne 0 ]; then
    echo "Por favor, ejecuta el instalador con permisos de administrador:"
    echo "  sudo bash install.sh"
    exit 1
fi

REAL_USER="${SUDO_USER:-$USER}"
USER_HOME=$(getent passwd "$REAL_USER" | cut -d: -f6)
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "=========================================================="
echo " Instalando ASUS ROG Control Center en el sistema"
echo " Usuario: $REAL_USER ($USER_HOME)"
echo "=========================================================="

# 1. Copiar ejecutables a /usr/local/bin
echo "--> [1/5] Instalando binarios en /usr/local/bin..."
cp "$DIR/bin/asus-control-center" /usr/local/bin/asus-control-center
cp "$DIR/bin/asus-fan" /usr/local/bin/asus-fan
cp "$DIR/bin/asus-aura" /usr/local/bin/asus-aura
cp "$DIR/bin/asus_aura.py" /usr/local/bin/asus_aura.py
cp "$DIR/bin/auto-teclado-daemon" /usr/local/bin/auto-teclado-daemon
cp "$DIR/bin/toggle-teclado-laptop" /usr/local/bin/toggle-teclado-laptop
cp "$DIR/bin/cambiar-driver-550.sh" /usr/local/bin/cambiar-driver-550.sh
chmod 755 /usr/local/bin/asus-control-center /usr/local/bin/asus-fan /usr/local/bin/asus-aura /usr/local/bin/asus_aura.py /usr/local/bin/auto-teclado-daemon /usr/local/bin/toggle-teclado-laptop /usr/local/bin/cambiar-driver-550.sh

# 2. Configurar permisos sudoers sin contraseña para el control de perfiles e iluminación
echo "--> [2/5] Configurando permisos sudoers para cambios instantáneos de ventilación e iluminación..."
echo "$REAL_USER ALL=(ALL) NOPASSWD: /usr/local/bin/asus-fan, /usr/local/bin/asus-aura" > /etc/sudoers.d/asus-fan-control
chmod 440 /etc/sudoers.d/asus-fan-control

# 3. Instalar servicio de ventiladores del sistema
echo "--> [3/5] Instalando servicio de inicio asus-fan-fix.service..."
cp "$DIR/systemd/asus-fan-fix.service" /etc/systemd/system/asus-fan-fix.service
systemctl daemon-reload
systemctl enable asus-fan-fix.service
systemctl restart asus-fan-fix.service

# 4. Instalar servicio de usuario para detección automática de teclado
echo "--> [4/5] Instalando servicio de vigilancia inteligente de teclado..."
USER_SYSTEMD_DIR="$USER_HOME/.config/systemd/user"
mkdir -p "$USER_SYSTEMD_DIR"
cp "$DIR/systemd/auto-teclado.service" "$USER_SYSTEMD_DIR/auto-teclado.service"
chown -R "$REAL_USER:$REAL_USER" "$USER_HOME/.config/systemd"

USER_UID=$(id -u "$REAL_USER")
if [ -d "/run/user/$USER_UID" ]; then
    sudo -u "$REAL_USER" XDG_RUNTIME_DIR="/run/user/$USER_UID" systemctl --user daemon-reload 2>/dev/null || true
    sudo -u "$REAL_USER" XDG_RUNTIME_DIR="/run/user/$USER_UID" systemctl --user enable --now auto-teclado.service 2>/dev/null || true
fi

# 5. Instalar accesos directos
echo "--> [5/5] Instalando accesos directos en el menú y escritorio..."
cp "$DIR/desktop/asus-control-center.desktop" /usr/share/applications/asus-control-center.desktop
chmod 644 /usr/share/applications/asus-control-center.desktop

DESKTOP_DIR="$USER_HOME/Desktop"
[ ! -d "$DESKTOP_DIR" ] && DESKTOP_DIR="$USER_HOME/Escritorio"
if [ -d "$DESKTOP_DIR" ]; then
    cp "$DIR/desktop/asus-control-center.desktop" "$DESKTOP_DIR/ASUS-Control-Center.desktop"
    cp "$DIR/desktop/Alternar-Teclado.desktop" "$DESKTOP_DIR/Alternar-Teclado.desktop"
    chmod +x "$DESKTOP_DIR/ASUS-Control-Center.desktop" "$DESKTOP_DIR/Alternar-Teclado.desktop"
    chown "$REAL_USER:$REAL_USER" "$DESKTOP_DIR/ASUS-Control-Center.desktop" "$DESKTOP_DIR/Alternar-Teclado.desktop" 2>/dev/null || true
    if command -v gio >/dev/null 2>&1; then
        sudo -u "$REAL_USER" gio set "$DESKTOP_DIR/ASUS-Control-Center.desktop" metadata::trusted yes 2>/dev/null || true
        sudo -u "$REAL_USER" gio set "$DESKTOP_DIR/Alternar-Teclado.desktop" metadata::trusted yes 2>/dev/null || true
    fi
fi

echo ""
echo "=========================================================="

# 6. Configurar protección de pantalla contra falsos positivos de la tapa
echo "--> [6/6] Configurando protección de pantalla (ignorar sensor de tapa)..."
mkdir -p /etc/systemd/logind.conf.d
echo -e "[Login]\nHandleLidSwitch=ignore\nHandleLidSwitchExternalPower=ignore" > /etc/systemd/logind.conf.d/ignore-lid.conf
systemctl reload systemd-logind 2>/dev/null || true

echo " ✔ ¡Instalación completada con éxito!"
echo " Puedes abrir la aplicación desde:"
echo "   1. Tu Escritorio: 'ASUS ROG Control Center'"
echo "   2. El menú de aplicaciones del sistema"
echo "   3. La terminal escribiendo: asus-control-center"
echo "=========================================================="
