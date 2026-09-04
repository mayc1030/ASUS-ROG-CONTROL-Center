#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
ASUS ROG Aura RGB Lighting Controller
Controlador de iluminación para portátiles ASUS ROG (GL504GM / N-KEY Device 0b05:1866).
Permite controlar de forma independiente las 4 zonas del teclado, modo global,
logotipo trasero de la pantalla (Lid Logo), barra de luz frontal y brillo.
"""

import sys
import os
import glob
import fcntl
import json
import time

# Constantes del protocolo USB HID de ASUS Aura
AURA_VENDOR_ID = "00000B05"
AURA_PRODUCT_ID = "00001866"
REPORT_ID_COLOR = 0x5D
REPORT_ID_BRIGHTNESS = 0x5A

CMD_UPDATE = 0xB3
CMD_APPLY = 0xB4
CMD_SET = 0xB5
CMD_BRIGHTNESS = 0xBA

# ioctl: _IOC(_IOC_WRITE|_IOC_READ, 'H', 0x06, 17) -> HIDIOCSFEATURE(17)
HIDIOCSFEATURE_17 = 0xC0114806

CONFIG_DIR = os.path.expanduser("~/.config/asus-rog-center")
STATE_FILE = os.path.join(CONFIG_DIR, "aura_state.json")

# 7 Zonas en hardware ASUS ROG Strix GL504GM:
# 1: Teclado WASD (Izquierda)
# 2: Teclado Centro-Izquierda
# 3: Teclado Centro-Derecha
# 4: Teclado NumPad (Derecha)
# 5: Barra Frontal Izquierda
# 6: Barra Frontal Derecha
# 7: Logotipo ROG de la Tapa Trasera (Pantalla)
DEFAULT_STATE = {
    "mode": "static",
    "sync": True,
    "brightness": 3,
    "global_color": "#ff0000",
    "zones": [
        "#ff0000",  # 1: Teclado WASD / Izquierda
        "#ff0000",  # 2: Teclado Centro-Izquierda
        "#ff0000",  # 3: Teclado Centro-Derecha
        "#ff0000",  # 4: Teclado NumPad / Derecha
        "#ff0000",  # 5: Barra Frontal (Izquierda)
        "#ff0000",  # 6: Barra Frontal (Derecha)
        "#ff0000",  # 7: Logotipo ROG Trasero (Tapa Pantalla)
    ],
    "speed": "normal",
    "is_off": False
}


def hex_to_rgb(hex_str):
    """Convierte un color hexadecimal '#RRGGBB' o 'RRGGBB' a tupla (R, G, B)."""
    hex_str = hex_str.lstrip('#')
    if len(hex_str) == 3:
        hex_str = ''.join([c * 2 for c in hex_str])
    try:
        r = int(hex_str[0:2], 16)
        g = int(hex_str[2:4], 16)
        b = int(hex_str[4:6], 16)
        return r, g, b
    except ValueError:
        return 255, 0, 0


def rgb_to_hex(r, g, b):
    """Convierte componentes R, G, B a string hexadecimal '#RRGGBB'."""
    return f"#{r:02x}{g:02x}{b:02x}"


def find_aura_hidraw():
    """
    Localiza dinámicamente el nodo /dev/hidraw correspondiente al controlador
    ASUS Aura N-KEY Device (0b05:1866) con soporte para el Report ID 0x5D.
    """
    for hidraw in sorted(glob.glob('/sys/class/hidraw/hidraw*')):
        dev_path = os.path.realpath(os.path.join(hidraw, 'device'))
        uevent_file = os.path.join(dev_path, 'uevent')
        if os.path.exists(uevent_file):
            try:
                with open(uevent_file, 'r') as f:
                    content = f.read()
                if f"{AURA_VENDOR_ID}:{AURA_PRODUCT_ID}" in content:
                    desc_file = os.path.join(dev_path, 'report_descriptor')
                    if os.path.exists(desc_file):
                        with open(desc_file, 'rb') as df:
                            if b'\x85\x5d' in df.read():
                                dev_node = f"/dev/{os.path.basename(hidraw)}"
                                if os.path.exists(dev_node):
                                    return dev_node
            except Exception:
                continue
    return None


class AuraController:
    def __init__(self, device_path=None):
        self.dev_path = device_path or find_aura_hidraw()
        self.state = self.load_state()

    def load_state(self):
        """Carga el estado guardado o retorna la configuración por defecto."""
        if os.path.exists(STATE_FILE):
            try:
                with open(STATE_FILE, 'r') as f:
                    data = json.load(f)
                loaded = {**DEFAULT_STATE, **data}
                # Asegurar que existan las 7 zonas en el estado cargado
                if "zones" in loaded:
                    while len(loaded["zones"]) < 7:
                        loaded["zones"].append(loaded["zones"][-1] if loaded["zones"] else "#ff0000")
                return loaded
            except Exception:
                pass
        return dict(DEFAULT_STATE)

    def save_state(self):
        """Guarda el estado actual para persistencia."""
        try:
            os.makedirs(CONFIG_DIR, exist_ok=True)
            with open(STATE_FILE, 'w') as f:
                json.dump(self.state, f, indent=2)
        except Exception:
            pass

    def _send_feature_report_fd(self, fd, data):
        """Envía un Feature Report de 17 bytes usando un descriptor de archivo abierto."""
        buf = bytearray(17)
        for i in range(min(len(data), 17)):
            buf[i] = data[i]
        fcntl.ioctl(fd, HIDIOCSFEATURE_17, buf)

    def _apply_and_set_fd(self, fd):
        """Envía las órdenes de SET (0xB5) y APPLY (0xB4) sobre el descriptor abierto."""
        buf_set = bytearray(17)
        buf_set[0] = REPORT_ID_COLOR
        buf_set[1] = CMD_SET
        self._send_feature_report_fd(fd, buf_set)

        buf_apply = bytearray(17)
        buf_apply[0] = REPORT_ID_COLOR
        buf_apply[1] = CMD_APPLY
        self._send_feature_report_fd(fd, buf_apply)

    def _send_feature_report(self, data):
        """Envía un Feature Report abriendo y cerrando el dispositivo."""
        if not self.dev_path:
            raise RuntimeError("No se encontró el dispositivo ASUS Aura N-KEY Device (0b05:1866).")
        fd = os.open(self.dev_path, os.O_RDWR)
        try:
            self._send_feature_report_fd(fd, data)
        finally:
            os.close(fd)

    def _apply_and_set(self):
        """Envía SET y APPLY abriendo y cerrando el dispositivo."""
        if not self.dev_path:
            raise RuntimeError("No se encontró el dispositivo ASUS Aura N-KEY Device (0b05:1866).")
        fd = os.open(self.dev_path, os.O_RDWR)
        try:
            self._apply_and_set_fd(fd)
        finally:
            os.close(fd)

    def _send_zone_packet(self, fd, zone, r, g, b, mode=0, speed=0xFF, direction=0):
        """
        Envía un comando de actualización de zona (0xB3) seguido inmediatamente
        de SET (0xB5) y APPLY (0xB4) con un retardo de 20ms.
        Esto garantiza que el microcontrolador de la placa confirme la zona
        sin sobreescribir la memoria de otras zonas.
        """
        buf = bytearray(17)
        buf[0] = REPORT_ID_COLOR
        buf[1] = CMD_UPDATE
        buf[2] = zone
        buf[3] = mode
        buf[4] = r
        buf[5] = g
        buf[6] = b
        buf[7] = speed
        buf[8] = direction
        self._send_feature_report_fd(fd, buf)
        self._apply_and_set_fd(fd)
        time.sleep(0.02)

    def set_brightness(self, level):
        """
        Ajusta el brillo global (0 a 3).
        0 = Apagado, 1 = Bajo, 2 = Medio, 3 = Alto.
        """
        level = max(0, min(3, int(level)))
        buf = bytearray(17)
        buf[0] = REPORT_ID_BRIGHTNESS
        buf[1] = CMD_BRIGHTNESS
        buf[2] = 0xC5
        buf[3] = 0xC4
        buf[4] = level
        self._send_feature_report(buf)
        self.state["brightness"] = level
        self.state["is_off"] = (level == 0)
        self.save_state()

    def set_single_static(self, hex_color):
        """
        Aplica un color estático global a todas las zonas, barra de luz frontal
        y logotipo trasero de la pantalla (Lid Logo).
        """
        r, g, b = hex_to_rgb(hex_color)
        clean_hex = rgb_to_hex(r, g, b)

        fd = os.open(self.dev_path, os.O_RDWR)
        try:
            # Zona 0 = Global / Broadcast a todas las zonas
            self._send_zone_packet(fd, 0, r, g, b)
        finally:
            os.close(fd)

        self.state["mode"] = "static"
        self.state["sync"] = True
        self.state["global_color"] = clean_hex
        self.state["zones"] = [clean_hex] * 7
        self.state["is_off"] = (r == 0 and g == 0 and b == 0)
        self.save_state()

    def set_zone_color(self, zone_id, hex_color):
        """
        Configura el color estático de una zona específica (1 a 7).
        Zonas soportadas:
          1: Teclado WASD / Izquierda
          2: Teclado Centro-Izquierda
          3: Teclado Centro-Derecha
          4: Teclado NumPad / Derecha
          5: Barra Frontal (Izquierda)
          6: Barra Frontal (Derecha)
          7: Logotipo ROG Trasero (Tapa Pantalla)
        """
        if zone_id < 1 or zone_id > 7:
            raise ValueError(f"Zona inválida: {zone_id}. Debe estar entre 1 y 7.")

        r, g, b = hex_to_rgb(hex_color)
        clean_hex = rgb_to_hex(r, g, b)

        fd = os.open(self.dev_path, os.O_RDWR)
        try:
            self._send_zone_packet(fd, zone_id, r, g, b)
        finally:
            os.close(fd)

        if "zones" not in self.state or len(self.state["zones"]) < 7:
            self.state["zones"] = (self.state.get("zones", []) + ["#ff0000"] * 7)[:7]
        self.state["zones"][zone_id - 1] = clean_hex
        self.state["sync"] = False
        self.state["mode"] = "static"
        self.state["is_off"] = all(c == "#000000" for c in self.state["zones"])
        self.save_state()

    def set_logo_color(self, hex_color):
        """Configura el color del logotipo ROG trasero en la tapa de la pantalla (Zona 7)."""
        return self.set_zone_color(7, hex_color)

    def set_lightbar_color(self, color_left, color_right=None):
        """Configura el color de la barra frontal (Zonas 5 y 6)."""
        if color_right is None:
            color_right = color_left
        self.set_zone_color(5, color_left)
        self.set_zone_color(6, color_right)

    def set_multi_static(self, colors):
        """
        Configura independientemente las zonas de iluminación (4 a 7 zonas).
        colors: Lista de colores hexadecimales.
        """
        if len(colors) < 4:
            colors = list(colors) + [colors[-1]] * (4 - len(colors))

        if "zones" not in self.state or len(self.state["zones"]) < 7:
            self.state["zones"] = ["#ff0000"] * 7

        current_zones = list(self.state["zones"])

        fd = os.open(self.dev_path, os.O_RDWR)
        try:
            for i in range(len(colors)):
                zone = i + 1
                if zone > 7:
                    break
                r, g, b = hex_to_rgb(colors[i])
                clean_hex = rgb_to_hex(r, g, b)
                current_zones[i] = clean_hex
                self._send_zone_packet(fd, zone, r, g, b)
        finally:
            os.close(fd)

        self.state["mode"] = "static"
        self.state["sync"] = False
        self.state["zones"] = current_zones
        self.state["is_off"] = all(c == "#000000" for c in current_zones)
        self.save_state()

    def set_mode(self, mode_name, speed=2, color1="#ff0000", color2="#0000ff"):
        """
        Aplica un modo dinámico de iluminación:
        mode_name: 'breathing', 'colorcycle', 'rainbow'
        speed: 1 (Lento), 2 (Normal), 3 (Rápido)
        """
        speeds = {1: 0xE1, 2: 0xEB, 3: 0xF5}
        speed_byte = speeds.get(speed, 0xEB)

        mode_name = mode_name.lower()
        if mode_name == "breathing":
            r1, g1, b1 = hex_to_rgb(color1)
            r2, g2, b2 = hex_to_rgb(color2)
            buf = bytearray(17)
            buf[0] = REPORT_ID_COLOR
            buf[1] = CMD_UPDATE
            buf[2] = 0
            buf[3] = 1  # Breathing
            buf[4] = r1
            buf[5] = g1
            buf[6] = b1
            buf[7] = speed_byte
            buf[9] = 1
            buf[10] = r2
            buf[11] = g2
            buf[12] = b2
            self._send_feature_report(buf)
            self._apply_and_set()

        elif mode_name in ("colorcycle", "cycle"):
            buf = bytearray(17)
            buf[0] = REPORT_ID_COLOR
            buf[1] = CMD_UPDATE
            buf[2] = 0
            buf[3] = 2  # Color Cycle
            buf[4] = 0xFF
            buf[7] = speed_byte
            self._send_feature_report(buf)
            self._apply_and_set()

        elif mode_name == "rainbow":
            buf = bytearray(17)
            buf[0] = REPORT_ID_COLOR
            buf[1] = CMD_UPDATE
            buf[2] = 0
            buf[3] = 3  # Rainbow
            buf[4] = 0xFF
            buf[7] = speed_byte
            self._send_feature_report(buf)
            self._apply_and_set()
        else:
            raise ValueError(f"Modo no reconocido: {mode_name}")

        self.state["mode"] = mode_name
        self.state["speed"] = "fast" if speed == 3 else ("slow" if speed == 1 else "normal")
        self.state["is_off"] = False
        self.save_state()

    def turn_off(self):
        """Apagado total de luces (Modo Stealth / Oscuro)."""
        self.set_single_static("#000000")
        self.set_brightness(0)
        self.state["is_off"] = True
        self.save_state()

    def restore_state(self):
        """Restaura la iluminación guardada en el archivo de estado."""
        state = self.load_state()
        if state.get("is_off", False):
            self.turn_off()
            return

        # Restaurar brillo
        b = state.get("brightness", 3)
        self.set_brightness(b)

        mode = state.get("mode", "static")
        if mode == "static":
            if state.get("sync", True):
                self.set_single_static(state.get("global_color", "#ff0000"))
            else:
                self.set_multi_static(state.get("zones", ["#ff0000"] * 7))
        elif mode in ("rainbow", "colorcycle", "breathing"):
            sp = 3 if state.get("speed") == "fast" else (1 if state.get("speed") == "slow" else 2)
            self.set_mode(mode, speed=sp)


ZONE_LABELS = [
    "Zona 1 (Teclado WASD / Izq)",
    "Zona 2 (Teclado Centro-Izq)",
    "Zona 3 (Teclado Centro-Der)",
    "Zona 4 (Teclado NumPad / Der)",
    "Zona 5 (Barra Frontal Izq)",
    "Zona 6 (Barra Frontal Der)",
    "Zona 7 (Logo Trasero Pantalla)"
]


def print_status(ctrl):
    print("\n\033[1m\033[36m=== ESTADO DE ILUMINACIÓN ASUS AURA RGB (7 ZONAS) ===\033[0m\n")
    if ctrl.dev_path:
        print(f"  \033[1mDispositivo HID:\033[0m       \033[32m{ctrl.dev_path}\033[0m (ASUS N-KEY 0b05:1866)")
    else:
        print("  \033[1mDispositivo HID:\033[0m       \033[31mNo detectado\033[0m")

    state = ctrl.state
    off_str = "\033[31mAPAGADO (Stealth)\033[0m" if state.get("is_off") else "\033[32mENCENDIDO\033[0m"
    print(f"  \033[1mEstado General:\033[0m        {off_str}")
    print(f"  \033[1mBrillo Actual:\033[0m         Nivel {state.get('brightness', 3)} / 3")
    print(f"  \033[1mModo de Luz:\033[0m           {state.get('mode', 'static').upper()}")
    print(f"  \033[1mSincronización:\033[0m        {'Global (Todas las zonas)' if state.get('sync') else 'Zonas Independientes'}")
    
    if state.get("sync"):
        print(f"  \033[1mColor Global:\033[0m          {state.get('global_color', '#ff0000')}")
    else:
        zones = state.get("zones", ["#ff0000"] * 7)
        for i, zc in enumerate(zones):
            label = ZONE_LABELS[i] if i < len(ZONE_LABELS) else f"Zona {i+1}"
            print(f"    - {label}: {zc}")
    print()


def show_help():
    print("""\033[1mHerramienta de Control ASUS Aura RGB (GL504GM - 7 Zonas)\033[0m
Uso: \033[36masus-aura\033[0m [comando] [argumentos]

Comandos principales:
  \033[1mstatus\033[0m                               Muestra el estado actual y las 7 zonas de luz
  \033[1mstatic <hex>\033[0m                         Color estático global en todo el equipo
  \033[1mmulti <c1> <c2> <c3> <c4> [c5 c6 c7]\033[0m  Color independiente para cada zona (4 a 7 zonas)
  \033[1mzone <1-7> <hex>\033[0m                     Cambia el color de una zona específica
  \033[1mlogo <hex>\033[0m                           Control exclusivo del logotipo ROG trasero (pantalla)
  \033[1mlightbar <hex1> [hex2]\033[0m               Control de la barra frontal (1 o 2 colores)
  \033[1mbrightness <0-3>\033[0m                     Ajusta el brillo maestro (0 = apagado, 3 = máximo)
  \033[1moff\033[0m                                  Apaga todas las luces (Modo Stealth)
  \033[1mon / restore\033[0m                         Restaura el perfil guardado y enciende luces
  \033[1mrainbow [1-3]\033[0m                        Activa modo arcoíris en movimiento
  \033[1mcycle [1-3]\033[0m                          Ciclo de colores continuo
  \033[1mbreathing <hex1> [hex2] [1-3]\033[0m        Efecto respiración entre 1 o 2 colores

Zonas Disponibles (1 a 7):
  1: Teclado WASD (Izquierda)           5: Barra Frontal (Izquierda)
  2: Teclado Centro-Izquierda           6: Barra Frontal (Derecha)
  3: Teclado Centro-Derecha             7: Logotipo ROG Trasero (Tapa Pantalla)
  4: Teclado NumPad (Derecha)

Preajustes directos:
  \033[1mred, blue, green, white, yellow, cyan, magenta, cyberpunk\033[0m
""")


def main():
    ctrl = AuraController()
    args = sys.argv[1:]

    if not args or args[0] in ("status", "--status", "-s"):
        print_status(ctrl)
        return

    cmd = args[0].lower()

    try:
        if cmd in ("help", "--help", "-h"):
            show_help()
        elif cmd in ("off", "apagado", "apagar", "stealth"):
            ctrl.turn_off()
            print("\033[32m✔ Iluminación Aura apagada por completo (Modo Stealth).\033[0m")
        elif cmd in ("on", "restore", "restaurar"):
            ctrl.restore_state()
            print("\033[32m✔ Iluminación Aura restaurada y encendida.\033[0m")
        elif cmd in ("brightness", "brillo"):
            val = int(args[1]) if len(args) > 1 else 3
            ctrl.set_brightness(val)
            print(f"\033[32m✔ Brillo Aura ajustado a nivel {val}/3.\033[0m")
        elif cmd in ("static", "color", "set"):
            hex_c = args[1] if len(args) > 1 else "ff0000"
            ctrl.set_single_static(hex_c)
            print(f"\033[32m✔ Color estático global aplicado: {hex_c}\033[0m")
        elif cmd in ("zone", "zona"):
            if len(args) < 3:
                print("\033[31mUso: asus-aura zone <1-7> <hex_color>\033[0m")
                sys.exit(1)
            zid = int(args[1])
            hcolor = args[2]
            ctrl.set_zone_color(zid, hcolor)
            label = ZONE_LABELS[zid-1] if 1 <= zid <= len(ZONE_LABELS) else f"Zona {zid}"
            print(f"\033[32m✔ {label} configurada en color {hcolor}.\033[0m")
        elif cmd in ("logo", "tapa", "lid"):
            if len(args) < 2:
                print("\033[31mUso: asus-aura logo <hex_color>\033[0m")
                sys.exit(1)
            hcolor = args[1]
            ctrl.set_logo_color(hcolor)
            print(f"\033[32m✔ Logotipo ROG de la tapa trasera (pantalla) configurado en: {hcolor}.\033[0m")
        elif cmd in ("lightbar", "barra"):
            if len(args) < 2:
                print("\033[31mUso: asus-aura lightbar <hex1> [hex2]\033[0m")
                sys.exit(1)
            c1 = args[1]
            c2 = args[2] if len(args) > 2 else c1
            ctrl.set_lightbar_color(c1, c2)
            print(f"\033[32m✔ Barra frontal configurada: Izq ({c1}) / Der ({c2}).\033[0m")
        elif cmd in ("multi", "zonas", "zones"):
            if len(args) < 5:
                print("\033[31mError: multi requiere al menos 4 colores hexadecimales.\033[0m")
                print("Ejemplo 4 zonas: asus-aura multi ff0000 00ff00 0000ff ffff00")
                print("Ejemplo 7 zonas: asus-aura multi ff0000 00ff00 0000ff ffff00 ff00ff 00ffff ffffff")
                sys.exit(1)
            ctrl.set_multi_static(args[1:])
            print("\033[32m✔ Colores independientes aplicados correctamente a las zonas:\033[0m", args[1:])
        elif cmd == "rainbow":
            speed = int(args[1]) if len(args) > 1 else 2
            ctrl.set_mode("rainbow", speed=speed)
            print(f"\033[32m✔ Modo Arcoíris activado (Velocidad: {speed}).\033[0m")
        elif cmd in ("cycle", "colorcycle"):
            speed = int(args[1]) if len(args) > 1 else 2
            ctrl.set_mode("colorcycle", speed=speed)
            print(f"\033[32m✔ Modo Ciclo de Colores activado (Velocidad: {speed}).\033[0m")
        elif cmd == "breathing":
            c1 = args[1] if len(args) > 1 else "#ff0000"
            c2 = args[2] if len(args) > 2 and not args[2].isdigit() else "#000000"
            speed = int(args[-1]) if len(args) > 2 and args[-1].isdigit() else 2
            ctrl.set_mode("breathing", speed=speed, color1=c1, color2=c2)
            print(f"\033[32m✔ Modo Respiración activado ({c1} -> {c2}).\033[0m")
        # Presets rápidos
        elif cmd in ("red", "rojo"):
            ctrl.set_single_static("#ff0000")
            print("\033[32m✔ Preset ROG Red (#ff0000) aplicado a todo el equipo.\033[0m")
        elif cmd in ("blue", "azul"):
            ctrl.set_single_static("#0066ff")
            print("\033[32m✔ Preset Ice Blue (#0066ff) aplicado a todo el equipo.\033[0m")
        elif cmd in ("green", "verde"):
            ctrl.set_single_static("#00ff00")
            print("\033[32m✔ Preset Matrix Green (#00ff00) aplicado a todo el equipo.\033[0m")
        elif cmd in ("white", "blanco"):
            ctrl.set_single_static("#ffffff")
            print("\033[32m✔ Preset Blanco Puro (#ffffff) aplicado a todo el equipo.\033[0m")
        elif cmd in ("yellow", "amarillo"):
            ctrl.set_single_static("#ffff00")
            print("\033[32m✔ Preset Amarillo (#ffff00) aplicado a todo el equipo.\033[0m")
        elif cmd in ("cyan", "celeste"):
            ctrl.set_single_static("#00ffff")
            print("\033[32m✔ Preset Cian (#00ffff) aplicado a todo el equipo.\033[0m")
        elif cmd in ("magenta", "morado", "purple"):
            ctrl.set_single_static("#ff00ff")
            print("\033[32m✔ Preset Magenta (#ff00ff) aplicado a todo el equipo.\033[0m")
        elif cmd == "cyberpunk":
            cyberpunk_colors = [
                "#ff0055",  # 1: WASD / Neon Pink
                "#aa00ff",  # 2: Centro-Izq / Electric Purple
                "#00d4ff",  # 3: Centro-Der / Cyan Blue
                "#00ffaa",  # 4: NumPad / Neon Mint
                "#ff0055",  # 5: Barra Frontal Izq
                "#00d4ff",  # 6: Barra Frontal Der
                "#aa00ff"   # 7: Logo Trasero Pantalla
            ]
            ctrl.set_multi_static(cyberpunk_colors)
            print("\033[32m✔ Preset Cyberpunk Completo (7 Zonas: Teclado, Barra Frontal y Logo Trasero) aplicado con éxito.\033[0m")
        else:
            print(f"\033[31mComando no reconocido: {cmd}\033[0m")
            show_help()
            sys.exit(1)
    except Exception as e:
        print(f"\033[31mError al controlar hardware Aura: {e}\033[0m")
        sys.exit(1)


if __name__ == "__main__":
    main()

