Add-Type -AssemblyName System.Drawing
Add-Type -ReferencedAssemblies System.Drawing -TypeDefinition @"
using System;
using System.Drawing;
using System.Drawing.Imaging;

public static class OfficeTextures {
    static int Hash(int x, int y) {
        unchecked {
            int n = x * 374761393 + y * 668265263;
            n = (n ^ (n >> 13)) * 1274126177;
            return n & 0x7fffffff;
        }
    }

    static float Lattice(int x, int y, int period) {
        int px = ((x % period) + period) % period;
        int py = ((y % period) + period) % period;
        return (Hash(px, py) % 10000) / 10000f;
    }

    static float Smooth(float t) { return t * t * (3f - 2f * t); }

    static float Noise(float x, float y, int period) {
        int x0 = (int)Math.Floor(x);
        int y0 = (int)Math.Floor(y);
        float tx = Smooth(x - x0);
        float ty = Smooth(y - y0);
        float a = Lattice(x0, y0, period) + (Lattice(x0 + 1, y0, period) - Lattice(x0, y0, period)) * tx;
        float b = Lattice(x0, y0 + 1, period) + (Lattice(x0 + 1, y0 + 1, period) - Lattice(x0, y0 + 1, period)) * tx;
        return a + (b - a) * ty;
    }

    static void Save(string path, int w, int h, Func<int, int, Color> pixel) {
        using (var bmp = new Bitmap(w, h, PixelFormat.Format24bppRgb)) {
            for (int y = 0; y < h; y++) {
                for (int x = 0; x < w; x++) bmp.SetPixel(x, y, pixel(x, y));
            }
            bmp.Save(path, ImageFormat.Png);
        }
    }

    static int C(float v) { return Math.Max(0, Math.Min(255, (int)(v * 255f))); }

    static Color Mix(float n, float r, float g, float b, float amp) {
        return Color.FromArgb(C(r + (n - 0.5f) * amp), C(g + (n - 0.5f) * amp), C(b + (n - 0.5f) * amp));
    }

    public static void Make(string dir) {
        Save(System.IO.Path.Combine(dir, "carpet.png"), 512, 512, (x, y) => {
            float n = Noise(x / 32f, y / 32f, 16);
            float f = Noise(x / 8f, y / 8f, 64);
            return Mix(n * 0.7f + f * 0.3f, 0.20f, 0.18f, 0.16f, 0.10f);
        });
        Save(System.IO.Path.Combine(dir, "wall.png"), 512, 512, (x, y) => {
            float n = Noise(x / 48f, y / 48f, 10);
            float f = Noise(x / 6f, y / 6f, 80);
            return Mix(n * 0.65f + f * 0.35f, 0.63f, 0.59f, 0.52f, 0.06f);
        });
        Save(System.IO.Path.Combine(dir, "ceiling.png"), 512, 512, (x, y) => {
            float n = Noise(x / 40f, y / 40f, 12);
            float f = Noise(x / 5f, y / 5f, 100);
            return Mix(n * 0.6f + f * 0.4f, 0.58f, 0.57f, 0.52f, 0.05f);
        });
        Save(System.IO.Path.Combine(dir, "wood.png"), 256, 512, (x, y) => {
            float band = Noise(x / 18f, 0.2f, 14);
            float grain = Noise(2f, y / 10f, 50);
            float n = band * 0.75f + grain * 0.25f;
            return Mix(n, 0.36f, 0.20f, 0.11f, 0.16f);
        });
        Save(System.IO.Path.Combine(dir, "fabric.png"), 256, 256, (x, y) => {
            float n = Noise(x / 16f, y / 16f, 16);
            float f = Noise(x / 4f, y / 4f, 64);
            return Mix(n * 0.6f + f * 0.4f, 0.28f, 0.30f, 0.32f, 0.08f);
        });
    }
}
"@

$dest = "C:\projects\floor-404\assets_src\textures"
New-Item -ItemType Directory -Force -Path $dest | Out-Null
[OfficeTextures]::Make($dest)
Get-ChildItem $dest -Filter *.png | Select-Object Name, Length
