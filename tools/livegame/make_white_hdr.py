"""Write a uniform white equirect .hdr (Radiance RGBE) for UE to import as a neutral ambient cubemap."""
import struct
import sys

out = sys.argv[1] if len(sys.argv) > 1 else "WhiteAmbient.hdr"
w, h = 64, 32
with open(out, "wb") as f:
    f.write(b"#?RADIANCE\nFORMAT=32-bit_rle_rgbe\n\n" + f"-Y {h} +X {w}\n".encode())
    # 1.0 in RGBE = mantissa 128, exponent 129 (0.5 * 2^1)
    f.write(bytes([128, 128, 128, 129]) * (w * h))
print("wrote", out)
