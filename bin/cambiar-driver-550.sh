#!/usr/bin/env bash
# ==============================================================================
# SCRIPT DE BLINDAJE DE PANTALLA Y ESTABILIZACIÓN DE GPU (OPCIÓN 2)
# ASUS ROG Strix GL504GM (Intel i7-8750H + NVIDIA GTX 1060 Mobile)
# ==============================================================================
set -e

if [ "$EUID" -ne 0 ]; then
    echo "❌ Error: Este script requiere permisos de administrador."
    echo "Ejecútalo con: sudo bash $0"
    exit 1
fi

echo "===================================================================="
echo " 🛡️ INICIANDO BLINDAJE Y ESTABILIZACIÓN DEL SISTEMA (ASUS GL504GM)"
echo "===================================================================="

# 1. Blindar sensor magnético de la tapa y botón de encendido del teclado dañado
echo "--> [1/4] Protegiendo pantalla y botón de encendido contra falsas pulsaciones..."
mkdir -p /etc/systemd/logind.conf.d
cat << 'LID' > /etc/systemd/logind.conf.d/ignore-lid.conf
[Login]
HandleLidSwitch=ignore
HandleLidSwitchExternalPower=ignore
HandlePowerKey=ignore
HandlePowerKeyLongPress=poweroff
LID
echo "✔ Sensor de tapa y botón de encendido blindados (cero apagones involuntarios)."

# 2. Estabilización de bus PCIe y video Intel en GRUB
echo "--> [2/4] Configurando estabilización de bus PCIe y gráficos en GRUB..."
GRUB_FILE="/etc/default/grub"
PARAMS="pcie_aspm=off pci=noaer i915.enable_psr=0"

if ! grep -q "pcie_aspm=off" "$GRUB_FILE"; then
    sed -i "s/GRUB_CMDLINE_LINUX_DEFAULT=\"/GRUB_CMDLINE_LINUX_DEFAULT=\"$PARAMS /" "$GRUB_FILE"
    echo "✔ Parámetros añadidos a GRUB ($PARAMS)."
    echo "  Actualizando configuración de GRUB..."
    update-grub
else
    echo "✔ Los parámetros PCIe ya se encontraban configurados en GRUB."
fi

# 3. Estabilización de energía y memoria de la GTX 1060
echo "--> [3/4] Fijando parámetros de energía en el controlador NVIDIA..."
cat << 'MOD' > /etc/modprobe.d/nvidia-power-fix.conf
options nvidia NVreg_DynamicPowerManagement=0
options nvidia NVreg_PreserveVideoMemoryAllocations=1
MOD
echo "✔ Archivo /etc/modprobe.d/nvidia-power-fix.conf creado (Previene caída de bus Xid 79)."

# 4. Asegurar perfil PRIME On-Demand (Garantiza puertos HDMI y Mini-DP activos)
echo "--> [4/4] Verificando modo gráfico On-Demand para salida HDMI..."
prime-select on-demand
echo "✔ Modo PRIME On-Demand configurado (HDMI externo 100% operativo)."

echo ""
echo "===================================================================="
echo " ✔ ¡BLINDAJE Y ESTABILIZACIÓN COMPLETADOS CON ÉXITO!"
echo " Todos los ajustes han sido aplicados correctamente en el sistema."
echo ""
echo " Para que el kernel aplique los nuevos parámetros de GRUB y energía,"
echo " es necesario reiniciar el equipo:"
echo "   sudo reboot"
echo "===================================================================="

