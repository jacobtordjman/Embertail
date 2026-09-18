#!/usr/bin/env python3
"""Import supplied fox art with local Godot; retain a procedural fallback.

The fallback uses Python's standard library and a shared fixed-length pixel rig.
Source PNGs remain unchanged; the importer writes the runtime atlas and frames.
"""
from pathlib import Path
import math
from pixel_canvas import Canvas

ROOT = Path(__file__).resolve().parents[1]
SIZE, COLS, FOOT = 128, 12, 119
ANIMS = [('idle',12,8,True), ('run',12,24,True), ('jump',6,20,False),
         ('fall',8,12,True), ('dash',6,34,False), ('hurt',4,18,False),
         ('death',10,15,False), ('land',6,36,False)]
INK='#35232b'; EDGE='#66302c'; DARK='#8d362a'; RUST='#bd4522'
FUR='#ef6a20'; ORANGE='#ff902d'; LIGHT='#ffb447'; GOLD='#ffd37e'; TIP='#ffe8af'
CLOTH='#f5ebcf'; WHITE='#fff9e7'; FOLD='#c9c6af'; DEEP_FOLD='#969782'
RED='#963b37'; RED_LIGHT='#d16446'; BELT='#542b32'; PANTS='#857b5b'; PANTS_LIGHT='#ada082'


def bezier(start, control1, control2, end, steps=12):
    result=[]
    for i in range(steps+1):
        t=i/steps; u=1-t
        result.append((u*u*u*start[0]+3*u*u*t*control1[0]+3*u*t*t*control2[0]+t*t*t*end[0],
                       u*u*u*start[1]+3*u*u*t*control1[1]+3*u*t*t*control2[1]+t*t*t*end[1]))
    return result


def path(start, *segments):
    out=[start]
    for c1,c2,end in segments:
        out+=bezier(out[-1],c1,c2,end)[1:]
    return out


def rotate(point, origin, angle):
    x,y=point[0]-origin[0],point[1]-origin[1]
    c,s=math.cos(angle),math.sin(angle)
    return origin[0]+x*c-y*s, origin[1]+x*s+y*c


def mix(a,b,t):
    return a+(b-a)*t


def smooth(t):
    t=max(0,min(1,t)); return t*t*(3-2*t)


class Brush:
    def __init__(self, canvas, transform=lambda p:p):
        self.c=canvas; self.transform=transform
    def poly(self, points, fill, edge=INK, width=1):
        self.c.poly([self.transform(p) for p in points],fill,edge,width)
    def line(self,a,b,fill,width=1):
        self.c.line(self.transform(a),self.transform(b),fill,width)
    def dot(self,x,y,fill):
        self.c.point(*self.transform((x,y)),fill)
    def ellipse(self,x,y,rx,ry,fill,edge=None):
        self.poly([(x+math.cos(i*math.tau/32)*rx,y+math.sin(i*math.tau/32)*ry) for i in range(32)],fill,edge)


# Seven individually authored flame-shaped tails, ordered back to front.
# Each cream tip follows its own curve; the outlines never change between poses.
TAILS = [
 (path((63,85),((46,77),(44,61),(36,48)),((31,39),(27,36),(24,33)),((43,31),(52,43),(53,55)),((56,68),(65,68),(69,78))),
  [(24,33),(34,35),(41,39),(44,44),(40,42),(42,48),(37,44),(37,50),(32,40)],
  [(40,47),(48,58),(52,73),(64,81),(62,85),(46,75)]),
 (path((64,85),((42,84),(38,69),(25,60)),((18,55),(11,53),(8,54)),((17,41),(31,39),(41,48)),((54,56),(58,71),(67,76))),
  [(8,54),(15,47),(26,44),(35,48),(36,53),(31,51),(31,56),(26,52),(24,57),(20,53)],
  [(24,61),(38,64),(48,75),(61,84),(47,83),(34,73)]),
 (path((63,86),((44,95),(32,84),(23,79)),((16,75),(10,74),(6,77)),((12,60),(28,58),(40,65)),((49,70),(52,80),(65,79))),
  [(6,77),(13,66),(23,63),(31,66),(34,72),(27,69),(28,74),(23,70),(19,73),(15,71)],
  [(21,80),(32,82),(43,87),(56,85),(62,86),(49,93),(34,87)]),
 (path((65,82),((77,69),(92,61),(93,44)),((94,40),(93,33),(92,29)),((107,40),(107,57),(100,69)),((93,83),(78,87),(65,87))),
  [(92,29),(98,37),(102,47),(101,55),(97,57),(98,52),(94,56),(96,48),(94,51),(96,42)],
  [(100,58),(99,72),(85,83),(69,86),(71,79),(85,76)]),
 (path((65,87),((88,87),(103,71),(108,60)),((111,54),(111,51),(110,47)),((122,63),(118,80),(107,88)),((94,99),(78,96),(65,90))),
  [(110,47),(116,58),(116,69),(112,75),(108,77),(109,71),(105,75),(108,68),(105,70),(112,59)],
  [(114,76),(106,88),(92,93),(72,92),(76,86),(96,87)]),
 (path((64,89),((49,105),(31,110),(20,100)),((12,95),(10,87),(11,82)),((19,94),(31,96),(43,90)),((51,85),(59,85),(64,84))),
  [(11,82),(18,91),(27,96),(34,96),(31,100),(25,99),(28,102),(21,100),(23,103),(17,99),(13,92)],
  [(17,99),(30,103),(44,101),(57,93),(55,98),(44,106),(29,108),(20,103)]),
 (path((66,90),((83,99),(101,95),(114,85)),((116,95),(111,101),(103,106)),((89,112),(78,104),(64,94))),
  [(114,85),(112,94),(106,99),(98,102),(96,99),(90,101),(93,97),(88,98),(101,95)],
  [(110,102),(98,109),(84,108),(68,97),(76,97),(88,104),(101,104)])
]


def solve_knee(hip, ankle, side, upper=14, lower=13):
    dx,dy=ankle[0]-hip[0],ankle[1]-hip[1]
    d=min(upper+lower-.01,max(.01,math.hypot(dx,dy)))
    base=math.atan2(dy,dx)
    bend=math.acos(max(-1,min(1,(upper*upper+d*d-lower*lower)/(2*upper*d))))
    angle=base+side*bend
    return (hip[0]+math.cos(angle)*upper,hip[1]+math.sin(angle)*upper)


def segment(b,a,c,wa,wc,fill,edge=INK):
    dx,dy=c[0]-a[0],c[1]-a[1]; length=max(.01,math.hypot(dx,dy))
    nx,ny=-dy/length,dx/length
    b.poly([(a[0]+nx*wa,a[1]+ny*wa),(c[0]+nx*wc,c[1]+ny*wc),
            (c[0]-nx*wc,c[1]-ny*wc),(a[0]-nx*wa,a[1]-ny*wa)],fill,edge)


def pose(frame, anim, count):
    phase=frame/count*math.tau; t=frame/max(1,count-1)
    p=dict(bob=0.,lean=0.,head=0.,crouch=0.,phase=phase,tail=0.,reach=0.,blink=False,dead=False)
    if anim=='idle':
        p.update(bob=-math.sin(phase)*.65,head=math.sin(phase)*.012,blink=frame==9)
    elif anim=='run':
        p.update(bob=abs(math.sin(phase))*2.3,lean=.13,tail=-.15)
    elif anim=='jump':
        p.update(bob=-1,lean=mix(.10,-.035,t),tail=mix(-.14,.04,t),reach=-.2)
    elif anim=='fall':
        p.update(lean=-.025,tail=.06+math.sin(phase)*.025,reach=.35,bob=math.sin(phase)*.5)
    elif anim=='land':
        compression=[1,3.0,2.4,1.3,.45,0][frame]
        p.update(crouch=compression,bob=compression,lean=.04*(1-t),tail=.11*math.sin(t*math.pi))
    elif anim=='dash':
        p.update(lean=[.24,.33,.36,.36,.30,.18][frame],tail=-.37,bob=[2,3,3,3,2,1][frame],reach=1)
    elif anim=='hurt':
        p.update(lean=-.16*(1-t*.3),tail=.13,bob=1,reach=-.5,blink=True)
    elif anim=='death':
        p.update(lean=-.08,bob=0,tail=.15,reach=-.6,blink=True,dead=True)
    return p


def fox(frame,anim,count):
    c=Canvas(SIZE,SIZE); p=pose(frame,anim,count)
    phase=p['phase']; t=frame/max(1,count-1); bob=p['bob']
    def body_transform(q):
        x,y=rotate(q,(66,91),p['lean']); return x,y+bob
    body=Brush(c,body_transform)
    # Tail roots follow the hips; tip movement lags the torso by a quarter cycle.
    for i,(outline,tip,shadow) in enumerate(TAILS):
        sway=math.sin(phase-i*.54)*(.025 if anim!='run' else .045)
        sweep=p['tail']*(.45+i*.08)
        def tf(q, angle=sway+sweep):
            x,y=rotate(q,(65,86),angle); return x,y+bob*.5
        b=Brush(c,tf)
        b.poly(outline,RUST,INK,2)
        # Smaller nested planes provide warm edge shading, without texture noise.
        b.poly([(mix(65,x,.94),mix(86,y,.94)-1) for x,y in outline],FUR,None)
        b.poly(shadow,DARK,None)
        b.poly([(mix(65,x,.94),mix(86,y,.94)-2) for x,y in tip],LIGHT,None)
        b.poly(tip,GOLD,None)
        b.line(tip[0],tip[1],TIP)
        if len(tip)>3: b.line(tip[1],tip[2],TIP)
    # Legs are articulated behind the tunic; each shares the same lengths.
    for index in [0,1]:
        side=-1 if index==0 else 1
        hip=(66+side*6,91+bob)
        ankle=(66+side*9,114.)
        if anim=='run':
            a=phase+index*math.pi
            ankle=(66+side*3+math.sin(a)*14,114-max(0,math.cos(a))*12)
        elif anim=='jump':
            ankle=(66+side*(10+4*t),105+index*3+3*t)
        elif anim=='fall':
            ankle=(66+side*11,113-index*3)
        elif anim=='dash':
            ankle=(49+index*14,106+index*5)
        elif anim=='hurt':
            ankle=(66+side*12,113-index*3)
        assert math.dist(hip,ankle) <= 27.001, (anim, frame, "leg would stretch")
        knee=solve_knee(hip,ankle,1 if index==0 else -1)
        b=Brush(c)
        segment(b,hip,knee,6,5,PANTS if index==0 else PANTS_LIGHT)
        segment(b,knee,ankle,4.5,3.3,RUST)
        segment(b,hip,knee,3,3,PANTS_LIGHT if index else PANTS, None)
        b.line((knee[0]-3,knee[1]),(knee[0]+3,knee[1]+1),FOLD)
        ax,ay=ankle
        b.poly([(ax-3,ay-4),(ax+3,ay-4),(ax+4,ay+1),(ax+8,ay+4),(ax+7,ay+5),(ax-4,ay+5)],RUST,INK)
        b.poly([(ax-2,ay-3),(ax+1,ay-3),(ax+2,ay+2),(ax+5,ay+3),(ax-2,ay+3)],FUR,None)
        b.line((ax-3,ay+5),(ax+7,ay+5),EDGE)
        b.dot(ax+1,ay+3,LIGHT);b.dot(ax+4,ay+3,ORANGE)
    # Arms swing oppositely to planted feet; shoulder/sleeve/hand share one transform.
    for index in [0,1]:
        shoulder=(49 if index==0 else 82,63)
        angle=(math.sin(phase+index*math.pi)*.48 if anim=='run' else 0)
        if anim=='dash': angle=.9 if index==0 else -1.40
        elif anim=='jump': angle=.18 if index==0 else -.3
        elif anim=='fall': angle=.38 if index==0 else -.48
        elif anim=='hurt': angle=-.4 if index==0 else .35
        def arm_tf(q,origin=shoulder,a=angle): return body_transform(rotate(q,origin,a))
        arm=Brush(c,arm_tf)
        sx,sy=shoulder
        arm.poly([(sx-4,sy-2),(sx+4,sy-1),(sx+6,sy+8),(sx+5,sy+17),(sx-6,sy+18),(sx-7,sy+11)],CLOTH,INK,1)
        arm.poly([(sx-6,sy+3),(sx-3,sy+6),(sx-3,sy+13),(sx+4,sy+15),(sx-6,sy+16)],FOLD,None)
        arm.line((sx+3,sy+4),(sx+4,sy+12),WHITE,2)
        arm.line((sx-6,sy+15),(sx+5,sy+15),RED,3)
        arm.line((sx-6,sy+14),(sx+4,sy+14),GOLD)
        arm.poly([(sx-4,sy+17),(sx+3,sy+17),(sx+4,sy+25),(sx+1,sy+28),(sx-4,sy+26),(sx-5,sy+21)],RUST,INK)
        arm.poly([(sx-2,sy+18),(sx+1,sy+18),(sx+2,sy+24),(sx-1,sy+26),(sx-3,sy+23)],FUR,None)
        arm.line((sx-2,sy+24),(sx+1,sy+24),DARK)
    # Fixed kimono pattern, sculpted sleeves, overlap, double sash, and embroidered apron.
    body.poly([(58,57),(71,56),(78,61),(77,76),(81,94),(75,99),(67,96),(55,99),(48,94),(53,77),(52,64)],CLOTH,INK,2)
    body.poly([(54,63),(59,67),(56,82),(51,94),(57,94),(61,82),(62,72)],FOLD,None)
    body.poly([(75,64),(73,78),(78,94),(75,97),(68,92),(69,76)],FOLD,None)
    body.line((51,93),(56,96),RED,3);body.line((56,96),(66,91),RED,3)
    body.line((51,92),(56,94),GOLD)
    body.poly([(59,56),(68,57),(74,61),(66,76),(56,62)],RED,INK)
    body.poly([(57,58),(64,65),(72,59),(67,69),(64,73),(54,62)],WHITE,None)
    body.line((55,60),(65,71),RED,2)
    body.line((73,59),(62,78),RED,2)
    body.line((74,60),(65,77),GOLD)
    body.line((58,68),(56,76),DEEP_FOLD)
    body.line((72,70),(72,77),WHITE,2)
    body.poly([(52,78),(77,77),(79,84),(76,87),(52,87)],BELT,INK)
    body.line((53,79),(76,78),GOLD)
    body.line((54,82),(77,81),RED_LIGHT,2)
    body.line((54,85),(76,84),FOLD)
    body.poly([(64,85),(73,85),(76,100),(63,101)],RED,INK)
    body.poly([(65,87),(71,87),(74,98),(65,98)],CLOTH,None)
    body.line((65,89),(65,97),GOLD)
    body.poly([(69,94),(72,97),(69,100),(66,97)],ORANGE,None)
    body.poly([(69,96),(70,97),(69,98),(68,97)],TIP,None)
    body.poly([(77,81),(81,80),(81,85),(77,86)],RED,INK)
    body.line((80,85),(83,94),RED,2);body.line((78,86),(79,95),GOLD)
    # Head is a rigid authored design, offset with the neck, never scaled per frame.
    neck=body_transform((67,57))
    def head_tf(q):
        x,y=rotate(q,(67,57),p['head']+p['lean']*.35)
        return x+neck[0]-67,y+neck[1]-57
    b=Brush(c,head_tf)
    b.poly([(53,40),(51,19),(54,12),(65,29),(77,29),(86,16),(89,14),(88,40),(92,47),(88,56),(80,61),(69,60),(58,56),(49,49)],FUR,INK,2)
    b.poly([(53,22),(55,17),(63,32),(57,35)],RUST,None)
    b.poly([(55,22),(60,31),(57,33)],TIP,None)
    b.poly([(79,31),(86,20),(86,34),(82,37)],DARK,None)
    b.poly([(82,31),(86,23),(85,34)],GOLD,None)
    b.poly([(55,39),(61,33),(74,31),(81,34),(78,36),(65,35)],ORANGE,None)
    b.poly([(52,43),(59,41),(60,44),(57,45),(61,47),(54,48),(58,51),(52,50),(48,48)],RUST,INK)
    b.poly([(77,35),(84,38),(85,42),(81,44),(76,42)],RUST,None)
    b.poly([(54,48),(60,46),(65,48),(71,49),(78,46),(86,45),(93,48),(90,54),(84,58),(75,59),(65,55),(58,53)],TIP,EDGE)
    b.poly([(57,49),(64,50),(72,53),(84,53),(88,51),(85,56),(77,58),(68,55)],'#f0c47f',None)
    b.poly([(84,46),(91,46),(93,48),(90,51),(87,50)],INK,None)
    b.line((85,51),(83,54),EDGE)
    b.line((83,54),(78,55),EDGE)
    b.line((78,55),(75,54),RUST)
    b.dot(89,47,'#956050')
    # Small amber eyes, angled brows and cheek fur preserve the reference's confidence.
    b.poly([(59,40),(64,38),(70,40),(71,42),(65,40),(60,42)],DARK,None)
    b.poly([(79,39),(84,39),(86,41),(80,40)],DARK,None)
    if p['blink']:
        b.line((61,44),(68,44),INK);b.line((79,43),(83,43),INK)
    else:
        b.poly([(60,44),(64,41),(68,42),(70,45),(65,46)],INK,None)
        b.line((63,43),(64,44),GOLD,2);b.line((66,42),(66,45),EDGE)
        b.dot(63,42,WHITE)
        b.poly([(78,43),(81,41),(84,43),(83,45),(79,45)],INK,None)
        b.dot(81,42,GOLD);b.dot(82,42,WHITE)
    b.line((64,35),(68,35),GOLD);b.line((68,35),(70,37),LIGHT)
    b.dot(59,47,ORANGE)
    if anim=='death':
        # Ease from recoil into a real side-fall; preserve all anatomy via a rigid transform.
        out=Canvas(SIZE,SIZE)
        amount=smooth(min(1,t/.70)); angle=-math.pi*.46*amount
        source_origin=(66,79)
        occupied=[rotate((x,y),source_origin,angle) for y in range(SIZE) for x in range(SIZE) if c.data[(y*SIZE+x)*4+3]]
        minimum_x=min(x for x,y in occupied); maximum_x=max(x for x,y in occupied)
        shift_x=max(0,3-minimum_x)-max(0,maximum_x-124)
        # Keep the whole rigid fall inside its cell and plant the settled silhouette.
        target=(source_origin[0]+shift_x,source_origin[1]+FOOT-max(y for x,y in occupied))
        co,si=math.cos(-angle),math.sin(-angle)
        for y in range(SIZE):
            for x in range(SIZE):
                dx,dy=x-target[0],y-target[1]
                sx=round(source_origin[0]+dx*co-dy*si)
                sy=round(source_origin[1]+dx*si+dy*co)
                if 0<=sx<SIZE and 0<=sy<SIZE:
                    offset=(sy*SIZE+sx)*4
                    if c.data[offset+3]:out.point(x,y,tuple(c.data[offset:offset+4]))
        return out
    return c


def generate_procedural(review=False):
    sheet=Canvas(SIZE*COLS,SIZE*len(ANIMS))
    for row,(name,count,rate,loop) in enumerate(ANIMS):
        for f in range(COLS):
            # Unused cells repeat the last pose, avoiding accidental transparent frames.
            sheet.paste(fox(min(f,count-1),name,count),f*SIZE,row*SIZE)
    output=ROOT/'assets/sprites/player.png'
    sheet.save(output)
    total=sum(spec[1] for spec in ANIMS)
    lines=[f'[gd_resource type="SpriteFrames" load_steps={total+2} format=3]',
           '[ext_resource type="Texture2D" path="res://assets/sprites/player.png" id="1"]']
    for row,(name,count,rate,loop) in enumerate(ANIMS):
        for frame in range(count):
            lines += [f'[sub_resource type="AtlasTexture" id="{name}_{frame}"]',
                      'atlas = ExtResource("1")', f'region = Rect2({frame*SIZE}, {row*SIZE}, {SIZE}, {SIZE})']
    lines += ['[resource]','animations = [']
    for index,(name,count,rate,loop) in enumerate(ANIMS):
        lines += ['{','"frames": [']
        for frame in range(count):
            lines += ['{"duration": 1.0, "texture": SubResource("%s_%d")}%s' % (name,frame,',' if frame<count-1 else '')]
        lines += ['],',f'"loop": {str(loop).lower()},',f'"name": &"{name}",',f'"speed": {float(rate)}','}'+(',' if index<len(ANIMS)-1 else '')]
    lines += [']']
    (ROOT/'assets/sprites/player_frames.tres').write_text('\n'.join(lines)+'\n')
    if review:
        directory=ROOT/'docs/character'; directory.mkdir(parents=True,exist_ok=True)
        # Unfiltered 4× detail preview.
        sprite=fox(0,'idle',12); preview=Canvas(512,512,'#d5d8d3')
        for y in range(SIZE):
            for x in range(SIZE):
                offset=(y*SIZE+x)*4
                if sprite.data[offset+3]:preview.rect(x*4,y*4,4,4,tuple(sprite.data[offset:offset+4]))
        preview.save(directory/'idle-detail.png')
        contact=Canvas(128*8,128*3,'#d5d8d3')
        for column,(name,count,_,_) in enumerate(ANIMS):
            for row,index in enumerate([0,count//2,count-1]):contact.paste(fox(index,name,count),column*128,row*128)
        contact.save(directory/'pose-review.png')
    print(f'Player: {total} authored frames, {SIZE}px, eight states -> {output}')

def generate(review=False):
    # Once user sprites are present, regeneration must preserve that chosen design.
    if (ROOT/'assets/sprites/source_fox/fox_r00_c00.png').exists():
        import os, shutil, subprocess
        godot = os.environ.get('GODOT_BIN') or shutil.which('godot') or shutil.which('godot4')
        if not godot:
            raise SystemExit('Godot 4 is required to import the supplied character sprites. Set GODOT_BIN.')
        result = subprocess.run([godot, '--headless', '--path', str(ROOT), '--script', 'res://tools/import_player_sprites.gd'], text=True, stdout=subprocess.PIPE, stderr=subprocess.STDOUT)
        print(result.stdout, end='')
        if result.returncode or 'ERROR:' in result.stdout:
            raise SystemExit(result.returncode or 1)
    else:
        generate_procedural(review)

if __name__=='__main__':
    import sys
    generate('--review' in sys.argv)
