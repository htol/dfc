# Voice capture chain (AKG P220 -> ZOOM UAC-2)

## Required packages (Arch)

    sudo pacman -S easyeffects lsp-plugins-lv2
    yay -S deepfilternet-plus-bin

- `lsp-plugins-lv2` is an *optional* EasyEffects dependency; without it the
  Filter / Equalizer / Gate / Compressor plugins are missing.
- `deepfilternet-plus-bin` (AUR) provides the LADSPA library for the Deep
  Noise Remover stage. Without it EasyEffects shows "effect unavailable"
  and audio passes through that stage unprocessed.

## Files

- `input/clean mic.json` — input preset:
  high-pass 80 Hz x4 -> DeepFilterNet -> EQ -> gate -> compressor.
- `autoload/input/alsa_input.usb-ZOOM_Corporation_UAC-2_*.json` — loads the
  preset automatically when the UAC-2 input appears.
- `~/.config/wireplumber/wireplumber.conf.d/51-uac2-mic-priority.conf` —
  keeps the UAC-2 as the fallback default source (priority 3000) when
  EasyEffects is not running; the Bluetooth headset mic never wins.

## Verify after restore

1. `easyeffects` is running (service mode is enough).
2. `pactl info | grep 'Default Source'` shows `easyeffects_source`
   (or the UAC-2 when EasyEffects is stopped).
3. In the EasyEffects GUI no plugin on the Input page reports
   "unavailable".
