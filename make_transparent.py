from PIL import Image
import os

input_path = 'assets/images/joberto_tips_header.jpg'
output_path = 'assets/images/joberto_tips_header.png'

def remove_white(in_path, out_path):
    img = Image.open(in_path).convert("RGBA")
    datas = img.getdata()
    
    new_data = []
    threshold = 240
    for item in datas:
        if item[0] > threshold and item[1] > threshold and item[2] > threshold:
            new_data.append((255, 255, 255, 0))
        else:
            new_data.append(item)
            
    img.putdata(new_data)
    img.save(out_path, "PNG")
    print(f"Processed and saved to {out_path}")

if os.path.exists(input_path):
    remove_white(input_path, output_path)
else:
    print(f"File not found: {input_path}")
