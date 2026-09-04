# 🎮 ASUS ROG Control Center (Linux)

[![Platform](https://img.shields.io/badge/Platform-Linux-orange.svg)](https://kernel.org)
[![Hardware](https://img.shields.io/badge/Hardware-ASUS%20ROG%20GL504GM-red.svg)](https://rog.asus.com)
[![License](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)
[![GUI](https://img.shields.io/badge/GUI-GTK%203%20(Dark%20Theme)-purple.svg)](https://www.gtk.org/)

**ASUS ROG Control Center** es una suite completa (GUI nativa GTK3, CLI y servicios Systemd) diseñada específicamente para solucionar los problemas térmicos, ventiladores acelerados al 100% y conflictos de teclado en portátiles gamer **ASUS ROG Strix** (especialmente **GL504GM / SCAR II / HERO II**, compatible con modelos que utilizan el controlador `asus-nb-wmi`).

---

## 📸 Características Principales

* ❄️ **Control Térmico y Silencioso de Ventiladores:** Alterna entre perfiles de enfriamiento (*Silent*, *Balanced*, *Overboost/Turbo*) y elimina el bloqueo de ventiladores a 5.000+ RPM.
* 🌈 **Control de Iluminación Aura RGB (Zonas y Pantalla Trasera):** Personaliza las 4 zonas del teclado de forma independiente, la barra de luz frontal y el logotipo ROG de la tapa de la pantalla (*Lid Logo*), además de regular el brillo o apagar todo al 100% (*Modo Stealth*).
* ⚡ **Control de Intel Turbo Boost:** Domador de picos térmicos para el procesador **Intel Core i7-8750H**. Permite fijar la frecuencia a 2.2 GHz para trabajar fresco a 45°C o liberar los 4.1 GHz para gaming.
* ⌨️ **Vigilante Inteligente de Teclado (Auto-Freeze):** Si el teclado integrado del portátil tiene teclas cruzadas por desgaste de matriz, el demonio silencia automáticamente el teclado interno al conectar un teclado externo (como el **ASUS ROG Falchion**) y lo reactiva al desconectarlo.
* 🎮 **Optimización de NVIDIA GTX 1060:** Configura el modo *On-Demand* correcto para evitar que el controlador desconecte los sensores térmicos de la placa base.
* 🖥️ **Interfaz Gráfica GTK3 (Dark Gamer Edition):** HUD en tiempo real con temperaturas, RPM de turbinas, selector de zonas Aura RGB, selector visual de perfiles e interruptores de arranque automático.
* ⚙️ **Suite de Gestión de Servicios:** Habilita, deshabilita o reinstala todas las configuraciones del sistema con un solo clic.

---

## 🔍 El Diagnóstico: ¿Por qué fallan los ventiladores en Linux?

En el **ASUS ROG Strix GL504GM** se presentan 3 factores combinados:

1. **Picos de Turbo Boost agresivos:** El procesador Intel Core i7-8750H salta instantáneamente de 800 MHz a 4.1 GHz consumiendo hasta 80W en tareas menores. Al tocar 95-100°C en milisegundos (*Thermal Throttling*), la BIOS de ASUS activa el modo de emergencia: turbinas a máxima potencia.
2. **Conflicto del controlador NVIDIA (`prime-select intel`):** Al apagar la tarjeta dedicada con `intel`, el driver oficial no se comunica con la GPU. La placa base pierde la lectura de temperatura de la gráfica y, por precaución de hardware, fuerza el ventilador secundario al 100% (`pwm2_enable: 0`).
3. **Disipador compartido:** Los tubos de calor de cobre (*heatpipes*) están unidos entre CPU y GPU; el calor de uno calienta al otro.

---

## 🚀 Instalación Rápida (1 Solo Paso)

Clona el repositorio y ejecuta el instalador con permisos de administrador:

```bash
git clone https://github.com/mayc1030/ASUS-ROG-CONTROL-Center.git
cd ASUS-ROG-CONTROL-Center
sudo bash install.sh
```

### ¿Qué hace el instalador automáticamente?
* Instala las herramientas CLI y GUI en `/usr/local/bin/`.
* Configura los permisos `sudoers` para permitir el cambio de perfiles sin pedir contraseña en la GUI.
* Habilita el servicio de inicio `asus-fan-fix.service` para arrancar siempre en modo silencioso.
* Habilita el servicio de usuario `auto-teclado.service` para vigilar la conexión de teclados externos.
* Crea accesos directos en el menú de aplicaciones y en el Escritorio.

---

## 🖥️ Uso de la Aplicación Gráfica

Abre la aplicación haciendo doble clic en el acceso directo de tu Escritorio **`ASUS ROG Control Center`** o ejecuta en la terminal:

```bash
asus-control-center
```

### Pestañas disponibles:
1. **❄️ Ventiladores y Rendimiento:** Telemetría HUD en vivo (Temperatura CPU, Temperatura GPU, RPM Ventilador 1, RPM Ventilador 2, Frecuencia en MHz), botones de perfiles (Silencioso, Equilibrado, Turbo) e interruptor de Turbo Boost.
2. **⌨️ Control de Teclado:** Estado visual del teclado del portátil (Congelado/Activo), botón de alternancia rápida y estado de detección del teclado externo.
3. **🌈 Iluminación Aura RGB:** Control independiente para las 4 zonas del teclado, sincronización del logotipo trasero de la pantalla (Lid Logo) y barra frontal, regulador de brillo maestro (0 a 3), interruptor de apagado total (Modo Stealth) y presets gamer de 1 solo clic.
4. **⚙️ Servicios e Inicio Automático:** Interruptores para activar/desactivar del arranque del sistema el modo silencioso o el vigilante de teclado, selector de perfil NVIDIA y botón maestro de reinstalación.
5. **📖 Guía para Otras Distros:** Manual técnico embebido con instrucciones para replicar la configuración en cualquier distribución Linux.

---

## 💻 Uso por Línea de Comandos (CLI)

### 1. Control de Ventiladores (`asus-fan`)
```bash
# Ver estado actual de temperaturas, RPMs y perfiles
asus-fan status

# Activar modo silencioso (curva suave y bajo ruido)
asus-fan silent

# Activar modo equilibrado estándar
asus-fan balanced

# Activar modo Overboost (máxima refrigeración)
asus-fan turbo

# Desactivar Turbo Boost (mantiene la CPU fresca a 2.2 GHz y 45°C)
asus-fan turbo-boost off

# Reactivar Turbo Boost (libera los 4.1 GHz para juegos)
asus-fan turbo-boost on
```

### 2. Control de Iluminación Aura RGB (`asus-aura`)
Control directo del hardware USB `0b05:1866` sin necesidad de `sudo` con arquitectura de **7 Zonas Independientes**:
- Zonas 1 a 4: Teclado RGB (WASD, Centro-Izq, Centro-Der, NumPad)
- Zonas 5 y 6: Barra Frontal Izquierda y Derecha
- Zona 7: Logotipo ROG en la tapa de la pantalla (Lid Logo)

```bash
# Ver estado de iluminación, brillo y las 7 zonas actuales
asus-aura status

# Color estático global en todo el equipo (teclado + barra + logo)
asus-aura static ff0000

# Control independiente del logotipo ROG trasero (pantalla)
asus-aura logo aa00ff

# Control independiente de la barra frontal (1 o 2 colores)
asus-aura lightbar 00ffff ff0055

# Control directo de cualquier zona específica (1 a 7)
asus-aura zone 1 ff0000          # Zona 1 (WASD) en rojo

# Color independiente para las zonas (4 a 7 zonas)
asus-aura multi ff0055 aa00ff 00d4ff 00ffaa ff0055 00d4ff aa00ff

# Modos dinámicos
asus-aura rainbow 2              # Modo Arcoíris dinámico (velocidad 1-3)
asus-aura cycle 2                # Ciclo de colores continuo
asus-aura breathing ff0000 0000ff 2  # Respiración entre 2 colores

# Presets rápidos de color
asus-aura red                    # Rojo ROG clásico
asus-aura blue                   # Azul glacial (Ice Blue)
asus-aura green                  # Verde Matrix
asus-aura white                  # Blanco puro
asus-aura cyberpunk              # Preset Cyberpunk completo (7 Zonas)

# Control de brillo maestro (0: apagado, 1: bajo, 2: medio, 3: máximo)
asus-aura brightness 2

# Apagado total instantáneo (Modo Stealth / Nocturno)
asus-aura off

# Restaurar perfil guardado y encender de nuevo
asus-aura on
```

Para alternar el teclado del portátil manualmente:
```bash
toggle-teclado-laptop
```

---

## 📖 Replicación Manual en Cualquier Distribución Linux

Si instalas **Arch Linux, Fedora, Debian, Manjaro, Pop!_OS o Linux Mint**, puedes aplicar estos ajustes manualmente:

### 1. Control del Ventilador (`asus-nb-wmi`)
```bash
# 0 = Normal/Equilibrado, 1 = Overboost/Turbo, 2 = Silencioso
echo 2 | sudo tee /sys/devices/platform/asus-nb-wmi/fan_boost_mode
```

### 2. Servicio de Inicio Systemd
Crear `/etc/systemd/system/asus-fan-fix.service`:
```ini
[Unit]
Description=Control Silencioso de Ventiladores ASUS ROG
After=multi-user.target

[Service]
Type=oneshot
ExecStart=/bin/sh -c 'echo 2 > /sys/devices/platform/asus-nb-wmi/fan_boost_mode'
RemainAfterExit=yes

[Install]
WantedBy=multi-user.target
```
Habilitar:
```bash
sudo systemctl daemon-reload
sudo systemctl enable --now asus-fan-fix.service
```

### 3. Control de Frecuencia del Procesador (Intel P-State)
```bash
# Mantener fresco a 2.2 GHz (Desactivar Turbo)
echo 1 | sudo tee /sys/devices/system/cpu/intel_pstate/no_turbo

# Reactivar 4.1 GHz (Activar Turbo)
echo 0 | sudo tee /sys/devices/system/cpu/intel_pstate/no_turbo
```

### 4. Tarjeta Gráfica NVIDIA
Usa siempre modo **On-Demand** (PRIME Render Offload):
```bash
sudo prime-select on-demand
sudo reboot
```

### 5. Desactivar Teclado Integrado Dañado
En portátiles ASUS ROG con luces Aura Sync, el teclado es un dispositivo USB interno (`ASUS N-KEY Device`, ID `0b05:1866`):
```bash
# Desactivar entradas internas
xinput list | grep "Asus Keyboard" | grep -o 'id=[0-9]*' | cut -d= -f2 | while read id; do xinput disable $id; done
xinput disable "AT Translated Set 2 keyboard" 2>/dev/null || true

# Reactivar
xinput list | grep "Asus Keyboard" | grep -o 'id=[0-9]*' | cut -d= -f2 | while read id; do xinput enable $id; done
xinput enable "AT Translated Set 2 keyboard" 2>/dev/null || true
```

---

## 🧰 Mantenimiento de Hardware Recomendado

* **Pasta Térmica:** Debido al contacto de silicio directo (*direct-die*), se recomienda usar pastas de alta densidad para evitar el efecto *pump-out*: **Honeywell PTM7950**, **Noctua NT-H2** o **Arctic MX-4**.
* **Batería de reemplazo:** Modelo **`C41N1727`** (15.4V / 66Wh). El portátil opera sin problemas conectado a la corriente si se retira la batería degradada.

---

## 🗑️ Desinstalación

Para desinstalar completamente el programa y sus servicios:
```bash
cd ASUS-ROG-CONTROL-Center
sudo bash uninstall.sh
```

---

## 📄 Licencia

Este proyecto está bajo la Licencia **MIT**. Consulta el archivo [LICENSE](LICENSE) para más detalles.
