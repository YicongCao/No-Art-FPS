"""Compose an original 144 BPM E-minor MIDI score and render the SAME note events.
Run with Blender's bundled NumPy: blender --background --python tools/build_music.py
The renderer uses original oscillators/noise, not a third-party soundfont.
"""
from pathlib import Path
import math, struct, wave
import numpy as np
ROOT=Path(__file__).resolve().parents[1]
OUT=ROOT/'assets/music'
OUT.mkdir(parents=True,exist_ok=True)
PPQ=480
BPM=144
TEMPO=round(60000000/BPM)
RATE=32000
DURATION=60.0
tracks=[[],[],[],[]]

def note(track,beat,pitch,length,velocity):
    tracks[track].append((round(beat*PPQ),round(length*PPQ),pitch,velocity))

for bar in range(36):
    root=[40,36,45,35][bar%4]
    third=4 if bar%4 in (1,3) else 3
    base=bar*4
    for beat in [0,.75,1.5,2,2.75,3.5]:note(0,base+beat,root+(12 if beat==3.5 else 0),.34,100 if beat in (0,2) else 82)
    arp=[root+24,root+31,root+24+third,root+36,root+31,root+24+third,root+34,root+31]
    count=16 if bar>=30 else 8
    for i in range(count):
        # Leave small gaps in each phrase; final ten seconds remove those gaps.
        if bar<30 and bar%4==3 and i in [5,7]:continue
        note(1,base+i*4/count,arp[i%8]+(12 if bar>=34 else 0),.18,60+(i%2)*8)
    for pitch in [root+12,root+12+third,root+19]:note(2,base,pitch,3.85,40)
    for beat in [0,1.5,2,2.75]:note(3,base+beat,36,.22,112 if beat in (0,2) else 80)
    for beat in [1,3]:note(3,base+beat,38,.18,95)
    for i in range(16 if bar>=24 else 8):
        count_hat=16 if bar>=24 else 8
        note(3,base+i*4/count_hat,42,.08,52 if i%2==0 else 35)
    if bar%4==3:
        for beat in [3.25,3.5,3.75]:note(3,base+beat,38,.1,45+int((beat-3)*45))

# Standard MIDI file, format 1, conductor + four independently editable tracks.
def vlq(value):
    value=int(value); data=[value&127]; value>>=7
    while value:data.insert(0,(value&127)|128);value>>=7
    return bytes(data)
def chunk(data):return b'MTrk'+struct.pack('>I',len(data))+data
def meta(kind,data):return b'\xff'+bytes([kind])+vlq(len(data))+data
conductor=b'\x00'+meta(3,b'SIXTY / No-Art-FPS original score')
conductor+=b'\x00'+meta(0x51,TEMPO.to_bytes(3,'big'))
conductor+=b'\x00'+meta(0x58,bytes([4,2,24,8]))
conductor+=b'\x00'+meta(0x59,bytes([1,1])) # E minor, one sharp
conductor+=vlq(36*4*PPQ)+meta(0x2f,b'')
midi=b'MThd'+struct.pack('>IHHH',6,1,5,PPQ)+chunk(conductor)
names=['Pulse bass','Glass arpeggio','Tension pad','Breakbeat']
channels=[0,1,2,9]
programs=[38,81,89,0]
for index,events in enumerate(tracks):
    channel=channels[index]
    data=b'\x00'+meta(3,names[index].encode())
    if index<3:data+=b'\x00'+bytes([0xc0|channel,programs[index]])
    ordered=[]
    for start,dur,pitch,vel in events:
        ordered.append((start,1,bytes([0x90|channel,pitch,vel])))
        ordered.append((start+dur,0,bytes([0x80|channel,pitch,0])))
    last=0
    for time,_,event in sorted(ordered):
        data+=vlq(time-last)+event;last=time
    data+=vlq(max(0,36*4*PPQ-last))+meta(0x2f,b'')
    midi+=chunk(data)
(OUT/'sixty.mid').write_bytes(midi)

rng=np.random.default_rng(61105)
audio=np.zeros((round(DURATION*RATE),2),dtype=np.float32)
for index,events in enumerate(tracks):
    for start,dur,pitch,vel in events:
        offset=round(start/PPQ*60/BPM*RATE)
        duration=dur/PPQ*60/BPM
        duration=max(duration,.22 if index==3 else .09)
        t=np.arange(round((duration+.08)*RATE))/RATE
        frequency=440*2**((pitch-69)/12)
        if index==0:
            signal=(np.sin(2*np.pi*frequency*t)+.25*np.sin(4*np.pi*frequency*t)+.12*np.sin(6*np.pi*frequency*t))
            envelope=np.minimum(t/.004,1)*np.exp(-t*10)
            gain=.24
        elif index==1:
            signal=np.sin(2*np.pi*frequency*t)+.25*np.sin(2*np.pi*frequency*2*t)
            envelope=np.minimum(t/.003,1)*np.exp(-t*18)
            gain=.12
        elif index==2:
            signal=(np.sin(2*np.pi*frequency*t)+np.sin(2*np.pi*frequency*1.003*t))*.5
            envelope=np.minimum(t/.12,1)*np.minimum(np.maximum(duration+.08-t,0)/.2,1)
            gain=.075
        else:
            if pitch==36:
                phase=2*np.pi*(48*t+110*(1-np.exp(-t*32))/32)
                signal=np.sin(phase)
                envelope=np.exp(-t*20)
                gain=.5
            elif pitch==38:
                noise=rng.uniform(-1,1,len(t))
                signal=noise*.8+np.sin(2*np.pi*180*t)*.2
                envelope=np.exp(-t*27)
                gain=.3
            else:
                noise=rng.uniform(-1,1,len(t))
                signal=noise-np.roll(noise,1)
                envelope=np.exp(-t*80)
                gain=.095
        values=signal*envelope*gain*vel/127
        pan=0 if index in [0,3] else (-.22 if index==1 else .22)
        count=min(len(values),len(audio)-offset)
        if count<=0:continue
        audio[offset:offset+count,0]+=values[:count]*math.sqrt((1-pan)/2)
        audio[offset:offset+count,1]+=values[:count]*math.sqrt((1+pan)/2)
# Slight stereo eighth-note echo, then a controlled ending (not a looping arbitrary cut).
delay=round(60/BPM*.5*RATE)
dry=audio.copy()
audio[delay:]+=dry[:-delay,::-1]*.15
fade=round(.12*RATE)
audio[-fade:]*=np.linspace(1,0,fade)[:,None]
peak=float(np.max(np.abs(audio)))
audio*=.85/max(peak,.85)
with wave.open(str(OUT/'sixty.wav'),'wb') as f:
    f.setparams((2,2,RATE,0,'NONE','not compressed'))
    f.writeframes((audio*32767).astype('<i2').tobytes())
print('MUSIC_OK: 144 BPM, E minor, 36 bars, 60 seconds, 5 MIDI tracks, same events rendered to stereo PCM')
print('Peak',float(np.max(np.abs(audio))),'RMS',float(np.sqrt(np.mean(audio**2))))
