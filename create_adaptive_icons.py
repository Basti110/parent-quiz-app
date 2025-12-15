#!/usr/bin/env python3
from PIL import Image
import os

# Größen für adaptive icons (108dp in verschiedenen Dichten)
sizes = {
    'mdpi': 162,
    'hdpi': 216, 
    'xhdpi': 324,
    'xxhdpi': 432,
    'xxxhdpi': 648
}

# Lade das Original-Icon
source = Image.open('assets/app_symbol.png')

for density, size in sizes.items():
    # Erstelle ein transparentes Bild in der Zielgröße
    output = Image.new('RGBA', (size, size), (0, 0, 0, 0))
    
    # Berechne die Größe des Icons (66% der Gesamtgröße für safe zone)
    icon_size = int(size * 0.66)
    
    # Skaliere das Original-Icon
    resized = source.resize((icon_size, icon_size), Image.Resampling.LANCZOS)
    
    # Zentriere das Icon
    offset = (size - icon_size) // 2
    output.paste(resized, (offset, offset), resized if resized.mode == 'RGBA' else None)
    
    # Speichere das Ergebnis
    output_path = f'android/app/src/main/res/mipmap-{density}/ic_launcher_foreground.png'
    output.save(output_path, 'PNG')
    print(f'Created {output_path}')

print('Done!')
