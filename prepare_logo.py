from rembg import remove
from PIL import Image
import os

input_path = '/home/SYS_USER_PLACEHOLDER/Study/IoT/final/unnamed.png'
output_path = '/home/SYS_USER_PLACEHOLDER/Study/IoT/final/logo_processed.png'

print(f"[*] Processing {input_path}...")

# 1. Remove background using AI (rembg)
with open(input_path, 'rb') as i:
    input_image = i.read()
    output_image = remove(input_image)

# 2. Save temporary transparent image
temp_path = '/home/SYS_USER_PLACEHOLDER/Study/IoT/final/temp_transparent.png'
with open(temp_path, 'wb') as o:
    o.write(output_image)

# 3. Open with PIL for final scaling/cropping
img = Image.open(temp_path)

# Auto-crop transparency
bbox = img.getbbox()
if bbox:
    img = img.crop(bbox)

# 4. Scale to APK logo size (512x512 with aspect ratio maintained)
target_size = (512, 512)
img.thumbnail(target_size, Image.Resampling.LANCZOS)

# Create a new 512x512 transparent canvas to center the logo
final_img = Image.new("RGBA", target_size, (0, 0, 0, 0))
offset = ((target_size[0] - img.size[0]) // 2, (target_size[1] - img.size[1]) // 2)
final_img.paste(img, offset)

# 5. Final Save
final_img.save(output_path)
os.remove(temp_path)

print(f"[+] Success! APK Logo saved to: {output_path}")
