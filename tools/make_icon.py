import math
from PIL import Image, ImageDraw

S = 1024
img = Image.new("RGB", (S, S), "#0B1220")
d = ImageDraw.Draw(img)

# Diagonal gradient sky -> indigo
c1 = (2, 132, 199)     # sky 600
c2 = (79, 70, 229)     # indigo 600
c3 = (14, 165, 233)    # sky 500

for y in range(S):
    t = y / (S - 1)
    # two-stop blend with slight highlight at top
    r = int(c1[0] * (1 - t) + c2[0] * t)
    g = int(c1[1] * (1 - t) + c2[1] * t)
    b = int(c1[2] * (1 - t) + c2[2] * t)
    d.line([(0, y), (S, y)], fill=(r, g, b))

# Radial glow top-left
glow = Image.new("L", (S, S), 0)
gd = ImageDraw.Draw(glow)
gd.ellipse([-320, -420, 760, 520], fill=90)
glow = glow.filter(ImageFilter_Gaussian := __import__("PIL.ImageFilter", fromlist=["ImageFilter"]).GaussianBlur(180))
img.paste(Image.new("RGB", (S, S), (125, 211, 252)), (0, 0), glow)

d = ImageDraw.Draw(img)

# Frosted rounded square (glass card) in center
pad = 214
box = [pad, pad, S - pad, S - pad]
card = Image.new("RGBA", (S, S), (0, 0, 0, 0))
cd = ImageDraw.Draw(card)
cd.rounded_rectangle(box, radius=180, fill=(255, 255, 255, 46), outline=(255, 255, 255, 90), width=6)
img = Image.alpha_composite(img.convert("RGBA"), card).convert("RGB")
d = ImageDraw.Draw(img)

# Play triangle
cx, cy = S / 2 - 26, S / 2
size = 208
pts = [
    (cx - size * 0.42, cy - size * 0.62),
    (cx - size * 0.42, cy + size * 0.62),
    (cx + size * 0.68, cy),
]
d.polygon(pts, fill=(255, 255, 255))

# Download arrow (bottom-right, accent)
ax, ay = S * 0.70, S * 0.645
w = 18
d.rounded_rectangle([ax - w / 2, ay - 74, ax + w / 2, ay + 22], radius=9, fill=(254, 240, 138))
d.polygon([
    (ax - 44, ay + 4),
    (ax + 44, ay + 4),
    (ax, ay + 66),
], fill=(254, 240, 138))
d.rounded_rectangle([ax - 52, ay + 78, ax + 52, ay + 104], radius=13, fill=(254, 240, 138))

img.save("/var/minis/workspace/VideoParse-iOS/Resources/Assets.xcassets/AppIcon.appiconset/icon-1024.png")
print("icon written", img.size)
