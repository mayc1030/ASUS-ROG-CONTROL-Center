#!/usr/bin/env bash
# ==============================================================================
# ASUS ROG CONTROL CENTER - Desinstalador
# ==============================================================================
set -e

if [ "$EUID" -ne 0 ]; then
    echo "Por favor, ejecuta el desinstalador con permisos de administrador:"
    echo "  sudo bash uninstall.sh"
    exit 1
fi

REAL_USER="${SUDO_USER:-$USER}"
USER_HOME=$(getent passwd "$REAL_USER" | cut -d: -f6)

echo "Desinstalando ASUS ROG Control Center..."

# Detener y deshabilitar servicios
systemctl disable --now asus-fan-fix.service 2>/dev/null || true
rm -f /etc/systemd/system/asus-fan-fix.service
systemctl daemon-reload

USER_UID=$(id -u "$REAL_USER")
if [ -d "/run/user/$USER_UID" ]; then
    sudo -u "$REAL_USER" XDG_RUNTIME_DIR="/run/user/$USER_UID" systemctl --user disable --now auto-teclado.service 2>/dev/null || true
fi
rm -f "$USER_HOME/.config/systemd/user/auto-teclado.service"

# Eliminar binarios
rm -f /usr/local/bin/asus-control-center
rm -f /usr/local/bin/asus-fan
rm -f /usr/local/bin/auto-teclado-daemon
rm -f /usr/local/bin/toggle-teclado-laptop

# Eliminar sudoers y accesos directos
rm -f /etc/sudoers.d/asus-fan-control
rm -f /usr/share/applications/asus-control-center.desktop
rm -f "$USER_HOME/Desktop/ASUS-Control-Center.desktop" "$USER_HOME/Desktop/Alternar-Teclado.desktop" 2>/dev/null || true
rm -f "$USER_HOME/Escritorio/ASUS-Control-Center.desktop" "$USER_HOME/Escritorio/Alternar-Teclado.desktop" 2>/dev/null || true

echo "✔ Desinstalación completada."
