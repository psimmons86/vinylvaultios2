#!/bin/bash

# Script to generate app icons for VinylVault
# This script uses ImageMagick to create app icons based on the description

echo "Generating app icons for VinylVault..."

# Create a temporary SVG file
cat > temp-icon.svg << 'EOL'
<svg width="1024" height="1024" viewBox="0 0 1024 1024" xmlns="http://www.w3.org/2000/svg">
  <!-- Rounded square background with gradient -->
  <defs>
    <linearGradient id="bg-gradient" x1="0%" y1="0%" x2="100%" y2="100%">
      <stop offset="0%" stop-color="#00C9A7" /> <!-- Teal -->
      <stop offset="100%" stop-color="#FF00FF" /> <!-- Magenta -->
    </linearGradient>
    <radialGradient id="reflection" cx="30%" cy="30%" r="60%" fx="30%" fy="30%">
      <stop offset="0%" stop-color="white" stop-opacity="0.3" />
      <stop offset="100%" stop-color="white" stop-opacity="0" />
    </radialGradient>
  </defs>
  
  <!-- Rounded square background -->
  <rect x="0" y="0" width="1024" height="1024" rx="224" ry="224" fill="url(#bg-gradient)" />
  
  <!-- White border -->
  <rect x="10" y="10" width="1004" height="1004" rx="214" ry="214" fill="none" stroke="white" stroke-width="4" />
  
  <!-- Vinyl record with grooves -->
  <circle cx="512" cy="512" r="400" fill="black" />
  
  <!-- Record grooves -->
  <circle cx="512" cy="512" r="380" fill="none" stroke="#222222" stroke-width="1" />
  <circle cx="512" cy="512" r="360" fill="none" stroke="#222222" stroke-width="1" />
  <circle cx="512" cy="512" r="340" fill="none" stroke="#222222" stroke-width="1" />
  <circle cx="512" cy="512" r="320" fill="none" stroke="#222222" stroke-width="1" />
  <circle cx="512" cy="512" r="300" fill="none" stroke="#222222" stroke-width="1" />
  <circle cx="512" cy="512" r="280" fill="none" stroke="#222222" stroke-width="1" />
  <circle cx="512" cy="512" r="260" fill="none" stroke="#222222" stroke-width="1" />
  <circle cx="512" cy="512" r="240" fill="none" stroke="#222222" stroke-width="1" />
  <circle cx="512" cy="512" r="220" fill="none" stroke="#222222" stroke-width="1" />
  
  <!-- Magenta record label -->
  <circle cx="512" cy="512" r="150" fill="#FF00FF" />
  
  <!-- Text on record label -->
  <text x="512" y="500" font-family="Arial, sans-serif" font-size="60" font-weight="bold" text-anchor="middle" fill="white">VINYL</text>
  <text x="512" y="560" font-family="Arial, sans-serif" font-size="60" font-weight="bold" text-anchor="middle" fill="white">VAULT</text>
  
  <!-- Center hole -->
  <circle cx="512" cy="512" r="20" fill="black" />
  
  <!-- Subtle reflection -->
  <circle cx="512" cy="512" r="400" fill="url(#reflection)" />
</svg>
EOL

# Save the SVG to the app icon directory
cp temp-icon.svg VinylVault/Assets.xcassets/AppIcon.appiconset/app-icon.svg

# Generate PNG files for all required sizes with solid background (no transparency)
echo "Generating app-icon-60@2x.png (120x120)..."
convert -background "#00C9A7" -size 120x120 temp-icon.svg -flatten VinylVault/Assets.xcassets/AppIcon.appiconset/app-icon-60@2x.png

echo "Generating app-icon-60@3x.png (180x180)..."
convert -background "#00C9A7" -size 180x180 temp-icon.svg -flatten VinylVault/Assets.xcassets/AppIcon.appiconset/app-icon-60@3x.png

echo "Generating app-icon-76.png (76x76)..."
convert -background "#00C9A7" -size 76x76 temp-icon.svg -flatten VinylVault/Assets.xcassets/AppIcon.appiconset/app-icon-76.png

echo "Generating app-icon-76@2x.png (152x152)..."
convert -background "#00C9A7" -size 152x152 temp-icon.svg -flatten VinylVault/Assets.xcassets/AppIcon.appiconset/app-icon-76@2x.png

echo "Generating app-icon-83.5@2x.png (167x167)..."
convert -background "#00C9A7" -size 167x167 temp-icon.svg -flatten VinylVault/Assets.xcassets/AppIcon.appiconset/app-icon-83.5@2x.png

echo "Generating app-icon-1024.png (1024x1024)..."
convert -background "#00C9A7" -size 1024x1024 temp-icon.svg -flatten VinylVault/Assets.xcassets/AppIcon.appiconset/app-icon-1024.png

# Clean up
rm temp-icon.svg

echo "App icons generated successfully!"
echo "You can now rebuild the app to see the icons."
