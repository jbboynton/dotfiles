import fontforge
import os

# Iterate over all files in the current directory
for filename in os.listdir('.'):
    if filename.endswith(".ttf"):
        print(f"Processing {filename}...")
        # Open the font file
        font = fontforge.open(filename)
        # Define the output filename with .woff extension
        output_woff = filename.replace(".ttf", ".woff")
        output_woff2 = filename.replace(".ttf", ".woff2")
        # Generate the WOFF font file
        font.generate(output_woff)
        font.generate(output_woff2)
        font.close()
        print(f"Successfully generated {output_woff} and {output_woff2}")
