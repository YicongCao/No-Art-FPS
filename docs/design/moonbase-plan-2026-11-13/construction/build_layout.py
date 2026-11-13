from pathlib import Path
import html
OUT=Path(__file__).resolve().parent
sx=lambda x:470+x*14
sz=lambda z:430+z*14
svg=['<svg xmlns="http://www.w3.org/2000/svg" width="1440" height="1000" viewBox="0 0 1440 1000"><rect width="1440" height="1000" fill="#e6ece9"/><text x="35" y="45" font-size="25" fill="#1d3e50">MOONBASE / EXTERIOR SITE PLAN v1.1</text><text x="35" y="76" font-size="14" fill="#5c7680">44 × 48 m / X east, Z south / dimensions in metres / proposed greybox, not a measured built map</text><defs><pattern id="grid" width="14" height="14" patternUnits="userSpaceOnUse"><path d="M14 0H0V14" fill="none" stroke="#c7d4d3" stroke-width=".5"/></pattern><marker id="arrow" markerWidth="7" markerHeight="7" refX="6" refY="3" orient="auto"><path d="M0 0L6 3L0 6" fill="none" stroke="#b95e3a"/></marker></defs>']
svg.append(f'<rect x="{sx(-22)}" y="{sz(-24)}" width="616" height="672" fill="url(#grid)" stroke="#395f70" stroke-width="2"/>')
def rect(x,z,w,d,label,color='#adbfbe'):
 svg.append(f'<rect x="{sx(x-w/2)}" y="{sz(z-d/2)}" width="{w*14}" height="{d*14}" rx="4" fill="{color}" stroke="#345768" stroke-width="1.3"/><text x="{sx(x)}" y="{sz(z)}" text-anchor="middle" dominant-baseline="middle" font-size="12" fill="#203f50">{html.escape(label)}</text>')
rect(0,-20.5,28,5,'A02 / CLOSED BASE','#cad0c4');rect(0,-16.5,28,3,'EXTERIOR DECK  Y=2.4','#bdc9ca')
for x in [-1.5,5]:rect(x,-11,3,8,'RAMP','#b0c1c8')
rect(-12.5,-1,12,14,'A01 / SHIP','#9fb8c2');rect(16,-10,6.5,6,'A03 / O2','#b6c7bc');rect(16,2,7.5,2.8,'A04','#b6c7bc');rect(19,-16,3,2,'A07','#8faaba');rect(16,-3,5,1.5,'A12','#d4bd91')
rect(-9,15,6,3.5,'A08 / CARGO','#d0c7b4');rect(10,15,6.5,4,'A05 / SERVICE','#d0c7b4')
for x,z,w,d in [(-2,-2,3,.8),(3,5,.8,3),(-4,9,3,.8)]:rect(x,z,w,d,'COVER','#b9c2b8')
# Route is a design intent; widths remain verified against every art replacement.
route=[(-20.25,17),(-20.25,-10),(-4.75,-10),(-4.75,-5),(0,-5),(7,-5),(9,-1),(9,8),(3,11),(0,16),(-4,19.5),(-16,19.5),(-20.25,19.5),(-20.25,17)]
svg.append('<polyline points="'+' '.join(f'{sx(x)},{sz(z)}' for x,z in route)+'" fill="none" stroke="#bd603a" stroke-width="3" stroke-dasharray="9 6" marker-end="url(#arrow)"/>')
for label,x,z,c in [('P',0,18,'#507e7d'),('E1',-17,-17,'#a66a50'),('E2',0,-16,'#a66a50'),('E3',11,-14,'#a66a50'),('E4',17,13,'#a66a50')]:svg.append(f'<circle cx="{sx(x)}" cy="{sz(z)}" r="13" fill="{c}"/><text x="{sx(x)}" y="{sz(z)+4}" text-anchor="middle" font-size="10" fill="white">{label}</text>')
# Minimum west-side path annotated with physical distance.
y=sz(0);svg.append(f'<path d="M{sx(-22)} {y}H{sx(-18.5)}" stroke="#466d78" stroke-width="2"/><text x="{sx(-20.25)}" y="{y-8}" text-anchor="middle" font-size="10" fill="#33596b">3.5 m</text>')
notes=[('LOCKED INTENT','Base interior is closed. Windows use dark backing.'),('MAIN ROUTE','3.5–5 m main path; 3 m service paths.'),('SHIP WEST GAP','X=-22 to -18.5 = 3.5 m at this proxy size.'),('RAMP DATUM','Deck top Y=2.4; run 8 m; rise 2.4 m.'),('PIPE BRIDGE','Under-beam target >=3.8 m; test real jump.'),('LOW COVER','0.9–1.2 m; destruction keeps the main shell.'),('BOUNDARY','Low wall + visible rock/cliff closure, no fake exit.'),('SPAWNS','P/E marks are candidates; retain fair spawn checks.'),('REFERENCE VIEWS','C0 (-3,1.65,16), C1 (-17,1.65,9),'),('','C2 (10,1.65,7); validate camera clearance.')]
for i,(a,b) in enumerate(notes):
 yy=135+i*65;svg.append(f'<text x="850" y="{yy}" font-size="14" fill="#a3492b">{a}</text><text x="850" y="{yy+24}" font-size="13" fill="#345667">{html.escape(b)}</text>')
svg.append('<text x="160" y="820" font-size="14" fill="#355c6c">Orange dashes: intended route, not navigation bake. Green/Brown circles: candidate spawns.</text><text x="160" y="855" font-size="14" fill="#355c6c">A06 antenna: base roof. A10 perimeter and A11 pad omitted as full geometry to keep plan legible.</text><text x="160" y="890" font-size="14" fill="#355c6c">Do not auto-place full A09 assemblies repeatedly; place individual cover units and retest sight lines.</text></svg>')
if __name__=='__main__':(OUT/'layout-v1.1.svg').write_text(''.join(svg))
