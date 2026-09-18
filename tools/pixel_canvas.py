"""Small deterministic RGBA rasterizer shared by the local art generators."""
import math, struct, zlib

def color(value):
    if isinstance(value, tuple): return value if len(value) == 4 else value + (255,)
    value = value.lstrip('#')
    return tuple(int(value[i:i+2], 16) for i in (0, 2, 4)) + (255,)


class Canvas:
    def __init__(self, w, h, fill=(0, 0, 0, 0)):
        self.w, self.h = w, h
        self.data = bytearray(color(fill) * (w*h))
    def point(self, x, y, c):
        x, y = int(round(x)), int(round(y))
        if 0 <= x < self.w and 0 <= y < self.h:
            i = (y*self.w+x)*4
            self.data[i:i+4] = bytes(color(c))
    def rect(self, x, y, w, h, c):
        for yy in range(int(y), int(y+h)):
            for xx in range(int(x), int(x+w)): self.point(xx, yy, c)
    def line(self, a, b, c, width=1):
        dx, dy = b[0]-a[0], b[1]-a[1]
        steps = max(1, int(max(abs(dx), abs(dy))))
        for i in range(steps+1):
            x, y = a[0]+dx*i/steps, a[1]+dy*i/steps
            self.rect(round(x)-width//2, round(y)-width//2, width, width, c)
    def poly(self, pts, c, outline=None, width=1):
        for y in range(math.floor(min(p[1] for p in pts)), math.ceil(max(p[1] for p in pts))+1):
            nodes = []
            for i, p in enumerate(pts):
                q = pts[(i+1)%len(pts)]
                if (p[1] <= y < q[1]) or (q[1] <= y < p[1]):
                    nodes.append(p[0]+(y-p[1])*(q[0]-p[0])/(q[1]-p[1]))
            nodes.sort()
            for i in range(0, len(nodes)-1, 2):
                for x in range(math.ceil(nodes[i]), math.floor(nodes[i+1])+1): self.point(x, y, c)
        if outline:
            for i,p in enumerate(pts): self.line(p, pts[(i+1)%len(pts)], outline, width)
    def ellipse(self, x, y, rx, ry, c, outline=None):
        if outline: self.ellipse(x, y, rx+1, ry+1, outline)
        for yy in range(math.floor(y-ry), math.ceil(y+ry)+1):
            for xx in range(math.floor(x-rx), math.ceil(x+rx)+1):
                if ((xx-x)/rx)**2 + ((yy-y)/ry)**2 <= 1: self.point(xx, yy, c)
    def paste(self, img, x, y):
        for yy in range(img.h):
            for xx in range(img.w):
                i=(yy*img.w+xx)*4
                if img.data[i+3]: self.point(x+xx, y+yy, tuple(img.data[i:i+4]))
    def save(self, path):
        raw=b''.join(b'\0'+bytes(self.data[y*self.w*4:(y+1)*self.w*4]) for y in range(self.h))
        def chunk(kind, data): return struct.pack('!I',len(data))+kind+data+struct.pack('!I',zlib.crc32(kind+data)&0xffffffff)
        path.write_bytes(b'\x89PNG\r\n\x1a\n'+chunk(b'IHDR',struct.pack('!2I5B',self.w,self.h,8,6,0,0,0))+chunk(b'IDAT',zlib.compress(raw,9))+chunk(b'IEND',b''))
