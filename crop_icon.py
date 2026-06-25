from PIL import Image, ImageChops
import os

def trim(im):
    # Try to trim based on top-left pixel color
    bg = Image.new(im.mode, im.size, im.getpixel((0,0)))
    diff = ImageChops.difference(im, bg)
    diff = ImageChops.add(diff, diff, 2.0, -100)
    bbox = diff.getbbox()
    if bbox:
        return im.crop(bbox)
    return im

try:
    path = 'assets/images/icon.png'
    im = Image.open(path)
    
    # If the image has transparency, make the background white
    if im.mode in ('RGBA', 'LA') or (im.mode == 'P' and 'transparency' in im.info):
        im_rgba = im.convert('RGBA')
        background = Image.new('RGBA', im_rgba.size, (255, 255, 255, 255))
        alpha_composite = Image.alpha_composite(background, im_rgba)
        im = alpha_composite.convert('RGB')
    else:
        im = im.convert('RGB')

    trimmed_im = trim(im)
    
    # Optional: Make it perfectly square by adding white padding if needed
    # But usually app icons are just fine if they are cropped, but it's better if it's square.
    width, height = trimmed_im.size
    max_dim = max(width, height)
    square_im = Image.new('RGB', (max_dim, max_dim), (255, 255, 255))
    offset = ((max_dim - width) // 2, (max_dim - height) // 2)
    square_im.paste(trimmed_im, offset)

    square_im.save(path)
    print("Crop successful!")
except Exception as e:
    print(f"Error: {e}")
