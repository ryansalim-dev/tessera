# Regenerates the studio sound effects in assets/audio.
# Usage: python3 tool/gen_sfx.py assets/audio
import numpy as np, wave, sys
SR=22050
out=sys.argv[1]
rng=np.random.default_rng(7)
def t(d): return np.arange(int(SR*d))/SR
def env(x,d,decay): return np.exp(-x*decay)
def bell(f,d,decay=6,parts=((1,1),(2.76,.5),(5.4,.25),(8.93,.12))):
    x=t(d); s=np.zeros_like(x)
    for m,a in parts: s+=a*np.sin(2*np.pi*f*m*x)*np.exp(-x*decay*(1+m*0.35))
    att=np.minimum(1,x/0.003); return s*att
def lp(s,k=6):
    return np.convolve(s,np.ones(k)/k,mode='same')
def save(name,s,gain=0.8):
    s=s/np.max(np.abs(s))*gain
    fade=np.minimum(1,(len(s)-np.arange(len(s)))/(0.01*SR)); s=s*fade
    with wave.open(f"{out}/{name}.wav",'wb') as w:
        w.setnchannels(1); w.setsampwidth(2); w.setframerate(SR)
        w.writeframes((s*32767).astype('<i2').tobytes())
# tap: wooden tick
x=t(0.07); n=lp(rng.standard_normal(len(x)),3)*np.exp(-x*160)
save('tap', n*0.5+np.sin(2*np.pi*1900*x)*np.exp(-x*90), 0.45)
# place: ceramic clink
c=bell(1480,0.35,decay=14); x=t(0.35); thump=np.sin(2*np.pi*220*x)*np.exp(-x*40)
save('place', c+0.6*thump, 0.6)
# erase: soft low tok
x=t(0.12); save('erase', np.sin(2*np.pi*(520-1500*x)*x)*np.exp(-x*45), 0.45)
# error: dull double thud
x=t(0.32); s=np.sin(2*np.pi*150*x)*np.exp(-x*30); s2=np.roll(s,int(0.1*SR)); s2[:int(0.1*SR)]=0
save('error', s+0.8*s2+0.2*lp(rng.standard_normal(len(x)),20)*np.exp(-x*25), 0.55)
# button: pop
x=t(0.09); save('button', np.sin(2*np.pi*(700*x-1800*x*x))*np.exp(-x*50), 0.45)
# solve: chime arpeggio
d=1.6; x=t(d); s=np.zeros_like(x)
for i,f in enumerate([1046.5,1318.5,1568,2093]):
    b=bell(f,d-i*0.09,decay=3.2); o=int(i*0.09*SR); s[o:o+len(b)]+=b*(0.9 if i<3 else 1.1)
sh=lp(rng.standard_normal(len(x)),2)*np.exp(-x*5)*0.05; save('solve', s+sh, 0.75)
# keystone: chord + gong
d=2.6; x=t(d); s=np.zeros_like(x)
for i,f in enumerate([523.25,659.25,783.99,1046.5,1318.5,1568]):
    b=bell(f,d-i*0.07,decay=1.8); o=int(i*0.07*SR); s[o:o+len(b)]+=b
g=bell(130.8,d,decay=1.2,parts=((1,1),(2.0,.4),(2.9,.3))); s+=g*1.2
save('keystone', s, 0.8)
# whoosh
x=t(0.35); n=rng.standard_normal(len(x)); n=lp(n,12); e=np.sin(np.pi*x/0.35)**2
save('whoosh', n*e, 0.25)
