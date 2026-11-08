"""Draw an SVG atlas of three split-flap schedules using mechanical tile glyphs."""
from pathlib import Path

GLYPHS = {
    "A": "01110 10001 10001 11111 10001 10001 10001",
    "B": "11110 10001 10001 11110 10001 10001 11110",
    "C": "01111 10000 10000 10000 10000 10000 01111",
    "D": "11110 10001 10001 10001 10001 10001 11110",
    "E": "11111 10000 10000 11110 10000 10000 11111",
    "F": "11111 10000 10000 11110 10000 10000 10000",
    "G": "01111 10000 10000 10111 10001 10001 01111",
    "H": "10001 10001 10001 11111 10001 10001 10001",
    "I": "01110 00100 00100 00100 00100 00100 01110",
    "J": "00111 00010 00010 00010 00010 10010 01100",
    "K": "10001 10010 10100 11000 10100 10010 10001",
    "L": "10000 10000 10000 10000 10000 10000 11111",
    "M": "10001 11011 10101 10101 10001 10001 10001",
    "N": "10001 11001 10101 10011 10001 10001 10001",
    "O": "01110 10001 10001 10001 10001 10001 01110",
    "P": "11110 10001 10001 11110 10000 10000 10000",
    "R": "11110 10001 10001 11110 10100 10010 10001",
    "S": "01111 10000 10000 01110 00001 00001 11110",
    "T": "11111 00100 00100 00100 00100 00100 00100",
    "U": "10001 10001 10001 10001 10001 10001 01110",
    "V": "10001 10001 10001 10001 10001 01010 00100",
    "W": "10001 10001 10001 10101 10101 11011 10001",
    "Y": "10001 10001 01010 00100 00100 00100 00100",
    "0": "01110 10001 10011 10101 11001 10001 01110",
    "1": "00100 01100 00100 00100 00100 00100 01110",
    "2": "01110 10001 00001 00110 01000 10000 11111",
    "3": "11110 00001 00001 01110 00001 00001 11110",
    "4": "00010 00110 01010 10010 11111 00010 00010",
    "5": "11111 10000 10000 11110 00001 00001 11110",
    "6": "01110 10000 10000 11110 10001 10001 01110",
    "7": "11111 00001 00010 00100 01000 01000 01000",
    "8": "01110 10001 10001 01110 10001 10001 01110",
    "9": "01110 10001 10001 01111 00001 00001 01110",
    ":": "00000 00100 00100 00000 00100 00100 00000",
}

FLIGHTS = [
    [
        ("18:20", "NA102", "OSAKA", "A03", "BOARDING"),
        ("18:35", "NA517", "TAIPEI", "A08", "ON TIME"),
        ("18:50", "NA218", "SINGAPORE", "B12", "ON TIME"),
        ("19:05", "NA442", "BUSAN", "B14", "DELAYED"),
        ("19:25", "NA635", "SAPPORO", "A02", "ON TIME"),
    ],
    [
        ("18:20", "NA102", "OSAKA", "A03", "LAST CALL"),
        ("18:35", "NA517", "TAIPEI", "A08", "BOARDING"),
        ("18:50", "NA218", "SINGAPORE", "B12", "ON TIME"),
        ("19:15", "NA442", "BUSAN", "B14", "DELAYED"),
        ("19:25", "NA635", "SAPPORO", "A02", "ON TIME"),
    ],
    [
        ("18:35", "NA517", "TAIPEI", "A08", "LAST CALL"),
        ("18:50", "NA218", "SINGAPORE", "B12", "BOARDING"),
        ("19:15", "NA442", "BUSAN", "B14", "ON TIME"),
        ("19:25", "NA635", "SAPPORO", "A02", "ON TIME"),
        ("19:45", "NA726", "MANILA", "B06", "ON TIME"),
    ],
]


def write_board():
    width, height = 780, 186
    atlas_height = height*len(FLIGHTS)
    svg = [f'<svg xmlns="http://www.w3.org/2000/svg" width="{width}" height="{atlas_height}" viewBox="0 0 {width} {atlas_height}">',
           f'<path fill="#0f151c" d="M0 0H{width}V{atlas_height}H0z"/>']
    for page, flights in enumerate(FLIGHTS):
        for row, flight in enumerate([("TIME", "FLIGHT", "DESTINATION", "GATE", "STATUS"), *flights]):
            time, code, city, gate, status = flight
            line = f"{time:5} {code:6} {city:11} {gate:4} {status:9}"
            for column, char in enumerate(line):
                x, y = column*20, page*height+row*31
                svg.append(f'<path fill="#252d39" d="M{x+1} {y+2}h18v13h-18z"/>'
                           f'<path fill="#1c232e" d="M{x+1} {y+16}h18v13h-18z"/>')
                if char == " ":
                    continue
                pixels = [
                    f"M{x+3.25+dx*2.7:g} {y+6+dy*2.7:g}h2.7v2.7h-2.7z"
                    for dy, pattern in enumerate(GLYPHS[char].split())
                    for dx, dot in enumerate(pattern) if dot=="1"
                ]
                color = "#ffc65a" if row==0 or column>=30 else "#fff2cf"
                svg.append(f'<path fill="{color}" d="{"".join(pixels)}"/>')
    svg.append("</svg>")
    out = Path(__file__).resolve().parents[2]/"assets/art/arena_signs/flight-board-atlas.svg"
    out.write_text("\n".join(svg)+"\n")
