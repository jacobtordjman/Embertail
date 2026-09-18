#!/usr/bin/env python3
"""Reproducible, dependency-free original pixel artwork and synthesized audio."""
from pathlib import Path
import math, random, struct, zlib, wave

ROOT = Path(__file__).resolve().parents[1] / 'assets'
for folder in ['sprites', 'tiles', 'backgrounds', 'effects', 'audio']:
    (ROOT / folder).mkdir(parents=True, exist_ok=True)


from pixel_canvas import Canvas, color

OUT='#352a36'; ORANGE='#ef7136'; LIGHT='#ffad4a'; RED='#9e383d'; SHADE='#bf4837'; CREAM='#fff1c2'; GOLD='#ffd773'; WHITE='#fff9e5'; ROBE='#eddfb2'; SAGE='#787464'


# Player art is maintained separately so character-only edits do not regenerate the world.
from generate_player import generate as generate_player
generate_player()

# Original moss-backed brass beetles.
enemies=Canvas(160,64)
for row in range(2):
    for f in range(4):
        c=Canvas(40,32);bob=f%2
        if row==1:
            c.ellipse(20,25,14,3,'#735a55',OUT)
            for k in range(6):
                a=k*math.tau/6;c.rect(18+round(math.cos(a)*(7+f*3)),15+round(math.sin(a)*(5+f*3)),2,2,GOLD)
        else:
            for x in (10,17,24,31):
                c.line((x,22),(x-3+(f%2)*5,28),OUT,2)
            c.ellipse(20,19-bob,14,9,'#506c60',OUT)
            c.poly([(7,20-bob),(11,10-bob),(20,7-bob),(31,12-bob),(34,20-bob)],'#728b66',OUT)
            c.poly([(12,11-bob),(20,8-bob),(23,11-bob),(16,12-bob)],'#b7c88a')
            c.line((20,9-bob),(20,22-bob),'#40524c')
            c.rect(9,20-bob,24,3,'#bba16b')
            c.ellipse(31,21,5,5,'#ac724e',OUT);c.rect(33,18,3,3,GOLD);c.point(35,18,WHITE)
            c.line((32,16),(33,12),OUT);c.point(34,11,GOLD)
            c.rect(11,15-bob,3,3,'#98ab73');c.rect(24,12-bob,3,3,'#91a671')
        enemies.paste(c,f*40,row*32)
enemies.save(ROOT/'sprites/enemy.png')

coins=Canvas(144,24)
for f in range(6):
    c=Canvas(24,24);rx=max(2,round(abs(math.cos(f*math.tau/6))*7))
    c.ellipse(12,12,rx,9,'#af6437',OUT);c.ellipse(12,11,rx-1,8,GOLD)
    c.line((12-rx+2,6),(12-rx+2,15),WHITE)
    c.poly([(12,6),(15 if rx>3 else 13,11),(12,16),(10 if rx>3 else 11,11)],'#e49b41')
    c.point(11,6,WHITE)
    coins.paste(c,f*24,0)
coins.save(ROOT/'sprites/coin.png')
heart=Canvas(16,16)
heart.poly([(8,4),(5,2),(2,3),(1,7),(3,10),(8,14),(13,10),(15,6),(13,2),(10,2)],'#d96868',OUT)
heart.poly([(3,4),(6,4),(6,6),(3,7)],'#ffd5a8');heart.poly([(8,11),(13,6),(12,10),(8,13)],'#a34359')
heart.save(ROOT/'sprites/heart.png')

# Seam-friendly hand-placed tile details, 4 horizontal 32px atlas cells.
rng=random.Random(914)
terrain=Canvas(128,32)
for t in range(4):
    c=Canvas(32,32)
    if t in (0,1):
        c.rect(0,0,32,32,'#775449')
        for _ in range(22):
            x,y=rng.randrange(32),rng.randrange(32)
            c.rect(x,y,rng.randrange(2,6),2,rng.choice(['#946650','#624943','#a67755']))
        if t==0:
            c.rect(0,0,32,5,'#bac786');c.rect(0,5,32,3,'#607d65')
            for x in range(0,32,4):
                c.rect(x,7,2,rng.randrange(1,5),'#607d65')
                c.rect(x,0,2,2,'#e8d99a')
    elif t==2:
        c.rect(0,0,32,32,'#667477');c.rect(0,0,32,2,'#a4b2a0')
        for y in (3,17):
            c.line((0,y+13),(31,y+13),'#354d56')
            for x in (0,16):
                c.rect(x+2,y+1,12,10,'#7e8e87');c.line((x+1,y),(x+1,y+12),'#a4b2a0')
    else:
        c.rect(0,0,32,32,'#82584a')
        for y in (1,9,17,25):
            c.rect(0,y,32,6,'#bc8760');c.line((0,y),(31,y),'#e0b17a');c.line((0,y+6),(31,y+6),'#503e3e')
            c.rect(2,y+2,2,2,'#503e3e');c.rect(28,y+2,2,2,'#503e3e')
    terrain.paste(c,t*32,0)
terrain.save(ROOT/'tiles/terrain.png')

# Atmospheric seamless layers. Alpha sky allows the level's gradient to show.
mountains=Canvas(960,360)
mountains.poly([(0,218),(80,150),(118,182),(194,84),(276,195),(329,125),(416,192),(487,78),(570,173),(633,119),(724,201),(802,97),(879,188),(960,218),(960,360),(0,360)],'#a0aaa0')
mountains.poly([(0,218),(80,150),(58,209),(119,227),(194,84),(170,200),(216,237),(276,195),(308,240),(329,125),(368,225),(416,192),(487,78),(453,205),(510,231),(570,173),(600,229),(633,119),(670,229),(724,201),(802,97),(775,219),(827,240),(879,188),(960,218),(960,360),(0,360)],'#82958e')
mountains.poly([(0,266),(77,214),(145,257),(220,204),(326,262),(430,190),(536,260),(624,212),(703,267),(787,201),(892,254),(960,266),(960,360),(0,360)],'#657f7d')
mountains.poly([(0,303),(130,285),(213,308),(360,279),(458,299),(589,278),(740,307),(869,279),(960,303),(960,360),(0,360)],'#587576')
mountains.save(ROOT/'backgrounds/mountains.png')

trees=Canvas(960,360)
for i in range(17):
    x=i*60+rng.randrange(-12,12);height=rng.randrange(58,150);base=350
    trees.rect(x,base-height,7,height,'#496567')
    for side in (-1,1): trees.line((x+3,base-height+35),(x+side*21,base-height+12),'#496567',3)
    for j in range(4):
        yy=base-height-10+j*19;w=25+j*6
        trees.poly([(x+4,yy-25),(x+w,yy+19),(x+8,yy+15),(x+4,yy+20),(x-w,yy+19)],['#769276','#6e8b73','#627f6d','#587867'][j])
    if i%4==1:
        trees.ellipse(x-5,base-height+6,29,23,'#b99c6d')
        trees.ellipse(x+17,base-height+19,25,22,'#b08f65')
        trees.ellipse(x-12,base-height+26,29,18,'#a88e69')
trees.save(ROOT/'backgrounds/trees.png')

# A small sparkle atlas for use by optional effects.
sparkles=Canvas(64,16)
for f in range(4):
    r=6-f;cx=f*16+8
    sparkles.line((cx-r,8),(cx+r,8),GOLD)
    sparkles.line((cx,8-r),(cx,8+r),GOLD)
    sparkles.rect(cx-1,7,3,3,WHITE)
sparkles.save(ROOT/'effects/sparkle.png')

# PCM mono synthesizer with click-free envelopes; no external samples.
RATE=22050

def save_wav(name, samples):
    with wave.open(str(ROOT/'audio'/name),'wb') as f:
        f.setnchannels(1);f.setsampwidth(2);f.setframerate(RATE)
        f.writeframes(b''.join(struct.pack('<h',max(-32767,min(32767,int(v*32767)))) for v in samples))

def tone(duration, start, end=None, volume=.25, shape='sine', decay=True, seed=0):
    n=int(duration*RATE);phase=0;data=[];noise=random.Random(seed)
    for i in range(n):
        t=i/RATE;progress=i/max(1,n-1);freq=start+((end if end else start)-start)*progress;phase+=math.tau*freq/RATE
        if shape=='triangle': v=2/math.pi*math.asin(math.sin(phase))
        elif shape=='noise': v=noise.uniform(-1,1)*.55+math.sin(phase)*.45
        else: v=math.sin(phase)+math.sin(phase*2)*.13
        env=min(1,t/.008)*min(1,(duration-t)/.03)*((1-progress)**.55 if decay else 1)
        data.append(v*env*volume)
    return data

def sequence(notes, volume=.2):
    out=[]
    for freq,dur in notes: out+=tone(dur,freq,volume=volume,shape='triangle')
    return out
save_wav('jump.wav',tone(.2,250,720,.20,'triangle'))
save_wav('coin.wav',sequence([(880,.07),(1320,.15)],.16))
save_wav('hurt.wav',tone(.3,190,58,.26,'noise',seed=32))
save_wav('enemy.wav',sequence([(250,.06),(170,.06),(420,.15)],.20))
save_wav('checkpoint.wav',sequence([(523.25,.1),(659.25,.1),(783.99,.1),(1046.5,.3)],.18))
save_wav('complete.wav',sequence([(523.25,.14),(659.25,.14),(783.99,.14),(1046.5,.2),(783.99,.14),(1046.5,.45)],.19))
save_wav('dash.wav',tone(.19,650,140,.14,'noise',seed=21))
save_wav('land.wav',tone(.09,80,40,.13,'noise',seed=43))
# Original 16-second pentatonic ambient loop. Sustained notes meet at zero gain.
duration=16;music=[0.0]*int(RATE*duration)
def mix_at(values, seconds):
    start=int(seconds*RATE)
    for i,v in enumerate(values):
        if start+i<len(music): music[start+i]+=v
chords=[(130.81,164.81,196),(110,130.81,164.81),(87.31,130.81,174.61),(98,146.83,196)]
for j,chord in enumerate(chords):
    for f in chord:
        vals=tone(3.95,f,volume=.025,decay=False)
        for i in range(len(vals)):
            t=i/RATE;vals[i]*=min(1,t/.7,(3.95-t)/.7)
        mix_at(vals,j*4)
melody=[(523.25,0),(659.25,1.5),(783.99,3),(659.25,4.5),(523.25,6),(440,7.5),(523.25,9),(698.46,10.5),(587.33,12),(783.99,13.5),(587.33,15)]
for f,t in melody: mix_at(tone(.85,f,volume=.045),t)
save_wav('music.wav',music)
print('Rebuilt player art and generated original enemies, coins, tiles, parallax layers, effects and nine WAV files.')
