#!/bin/zsh
# Saca las capturas reales de la app (modo demo, ver HisenseRemote/HisenseRemote/Demo.swift)
# en el simulador. Por defecto el iPhone 16 Pro Max (1320×2868, pantalla de 6.9"), que es lo que
# usa tools/make-preview.swift. Con SIM se elige otro, p. ej. las capturas de 6.3" (1206×2622):
#
#   tools/capture-preview.sh [carpeta]      (por defecto appstore/preview/frames)
#   SIM="iPhone 16 Pro" tools/capture-preview.sh appstore/screenshots/6.3
set -euo pipefail

export DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer
ROOT=${0:A:h:h}
OUT=${1:-$ROOT/appstore/preview/frames}
SIM=${SIM:-"iPhone 16 Pro Max"}
BUNDLE=com.mariosaucedo.HisenseRemote
BUILD=$ROOT/.build/preview-sim

mkdir -p "$OUT"

echo "› Compilando para el simulador…"
xcodebuild -project "$ROOT/HisenseRemote/HisenseRemote.xcodeproj" -scheme HisenseRemote \
  -configuration Debug -destination "platform=iOS Simulator,name=$SIM" \
  -derivedDataPath "$BUILD" CODE_SIGNING_ALLOWED=NO build -quiet
APP=$BUILD/Build/Products/Debug-iphonesimulator/HisenseRemote.app

echo "› Arrancando $SIM…"
xcrun simctl boot "$SIM" 2>/dev/null || true
xcrun simctl bootstatus "$SIM" -b >/dev/null
xcrun simctl ui "$SIM" appearance dark
# Barra de estado "de catálogo": 9:41, señal y batería llenas.
xcrun simctl status_bar "$SIM" override --time 9:41 --dataNetwork wifi --wifiMode active --wifiBars 3 \
  --cellularMode active --cellularBars 4 --batteryState charged --batteryLevel 100
xcrun simctl install "$SIM" "$APP"

shot() {   # shot <archivo> <argumentos de demo…>
  local name=$1; shift
  xcrun simctl launch --terminate-running-process "$SIM" $BUNDLE "$@" >/dev/null
  sleep 2.5
  xcrun simctl io "$SIM" screenshot --type=png "$OUT/$name" >/dev/null 2>&1
  echo "  ✓ $name"
}

echo "› Capturando…"
shot 01-scan.png       -demoScreen scanning
shot 02-pin.png        -demoScreen pairing -demoPin 4821
shot 03-remote-v18.png -demoScreen remote -demoVolume 18 -demoFull YES
shot 04-remote-v19.png -demoScreen remote -demoVolume 19 -demoFull YES
shot 05-remote-v20.png -demoScreen remote -demoVolume 20 -demoFull YES

xcrun simctl terminate "$SIM" $BUNDLE 2>/dev/null || true
xcrun simctl status_bar "$SIM" clear
echo "Listo: $OUT"
