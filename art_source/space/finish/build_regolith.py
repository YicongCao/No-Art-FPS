import numpy as np,struct,zlib
from pathlib import Path
OUT=Path(__file__).resolve().parents[3]/'assets/models/space';N=1024;rng=np.random.default_rng(71114)
f=np.fft.fftfreq(N);x,y=np.meshgrid(f,f);r=np.maximum(np.sqrt(x*x+y*y),.005)
a=np.fft.ifft2(np.fft.fft2(rng.normal(size=(N,N)))/r**.8).real;a=(a-a.mean())/a.std()
grains=rng.normal(size=(N,N));h=a*.015+grains*.008;dy,dx=np.gradient(h)
def png(name,rgb):
 data=np.clip(rgb*255,0,255).astype('uint8');raw=b''.join(b'\0'+line.tobytes() for line in data)
 def chunk(t,d):return struct.pack('>I',len(d))+t+d+struct.pack('>I',zlib.crc32(t+d)&0xffffffff)
 (OUT/name).write_bytes(b'\x89PNG\r\n\x1a\n'+chunk(b'IHDR',struct.pack('>2I5B',N,N,8,2,0,0,0))+chunk(b'IDAT',zlib.compress(raw))+chunk(b'IEND',b''))
v=np.clip(.70+a*.032+grains*.012,.50,.82)
png('regolith-detail.png',np.stack([v*.98,v,v*1.025],-1));png('regolith-detail-normal.png',np.stack([.5-dx*3,.5-dy*3,np.ones_like(v)],-1));print('REGOLITH_DETAIL_PASS')
