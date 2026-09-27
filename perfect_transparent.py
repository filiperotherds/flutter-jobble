from rembg import remove
from PIL import Image
import os

input_path = "C:/Users/Gabriel/.gemini/antigravity/brain/d03b8576-93b8-453b-930e-e2bea769bbbf/joberto_leaning_5stars_1790362892825.jpg"
output_path = "assets/images/joberto_tips_header.png"

if os.path.exists(input_path):
    print("Loading image...")
    input_image = Image.open(input_path)
    print("Removing background with rembg...")
    output_image = remove(input_image)
    output_image.save(output_path, "PNG")
    print(f"Perfectly removed background and saved to {output_path}")
else:
    print(f"File not found: {input_path}")
