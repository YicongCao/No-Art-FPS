# Graffiti paint

Three original RGBA textures generated with the built-in imagegen tool on 2026-11-06. The PNGs are saved unchanged; transparent paint gaps are retained. Godot import enables mipmaps, and the wall shader uses anisotropic filtering.

- `sector-01.png`: SECTOR 01, 2021×778.
- `sixty-yard.png`: THE SIXTY YARD, 2172×724.
- `warehouse.png`: WARE / HOUSE, 1610×977.

The shader blends artwork alpha into the wall's base color in one opaque pass. It projects by world position onto the actual wall/panel/rib surfaces. It does not use a floating plane, depth offset, transparency sorting, or a second material pass. This prevents the depth conflict of the initial overlay approach. Regions outside the painting retain the original palette and lighting.

## Prompts (verbatim)

### sector-01.png

Use case: stylized-concept. Asset type: transparent spray-painted graffiti lettering texture for a bright low-poly FPS, painted directly onto a brick-red corrugated shipping container. Exact text: "SECTOR 01". Create one large lively graffiti piece with SECTOR as a chunky forward-slanting uppercase hand-painted word and an oversized 01 to its right, arranged in a wide compact composition approximately 2.6:1. Uneven energetic letter widths and baseline, overlapping angular strokes, subtle drips, sparse spray specks and one sweeping underline. Cream #FFF1CB and warm yellow #E9BA50 fills with teal #548876 accent strokes, a tight charcoal #243440 outline and small hard painted cobalt shadows. Flat 2D spray paint, not extruded typography, no glossy finish. Readable at a distance and coherent with simple low-poly block geometry. Organic irregular silhouette: NO rectangular background, NO plaque, NO wall, NO building, NO border box, NO sticker rim, NO characters, NO other words. Only the paint itself on genuine alpha transparency, including transparent negative spaces within letters. Orthographic straight-on artwork. Fill the canvas with the lettering while leaving a small transparent margin. Wide landscape image.

### sixty-yard.png

Use case: stylized-concept. Asset type: transparent graffiti mural lettering texture for a bright low-poly FPS. Exact text: "THE SIXTY YARD". Arrange THE as a small hand-painted word above left, SIXTY YARD as the large dominant words across an irregular wide 3:1 composition. Expressive bold angular graffiti lettering, slanted energetic strokes and uneven baseline, confident hand-painted spray art. Deep cobalt #304F9D and muted teal #548876 letter fills with warm cream #FFF1CB highlights and tight charcoal #243440 outlines, small warm yellow #E9BA50 paint accents. A few tapering drips, scratchy paint gaps, sparse spray flecks, a sweeping brush underline integrated into the lettering. Designed to be painted directly on a pale cream and ochre wall, matching a toy-like colorful low-poly game with crisp geometric silhouettes. Flat 2D paint, readable words, no glossy or 3D extrusion. NO rectangular background, NO signboard, NO wall, NO plaque, NO sticker rim, NO border frame, NO extra text or objects. Only isolated colored paint on true transparent alpha, with transparent spaces around and within letters. Orthographic artwork filling a wide landscape canvas with a little transparent padding.

### warehouse.png

Use case: stylized-concept. Asset type: transparent graffiti mural paint texture for a bright low-poly FPS warehouse wall. Exact text: "WAREHOUSE", split on two bold stacked lines "WARE" above "HOUSE". Make one cohesive hand-sprayed graffiti piece in a roughly 1.65:1 composition, large expressive angular block letters leaning forward, lively uneven baselines, connected strokes and rough paint breaks. Cream #FFF1CB and warm ochre yellow #E9BA50 fill, a few muted teal #548876 and cobalt #304F9D accent swashes, tight dark charcoal #243440 outline. Slight color variation, restrained drips and paint speckles, one dynamic underline. Legible graffiti with a colorful blocky comic-game feel, flat paint with NO 3D extrusion or shine. The mural will be painted directly across a green/cream industrial wall. Show only the painted lettering and sparse paint accents, without a wall, board, plaque, solid background, sticker rim, rectangular border, characters or extra words. True alpha transparent background and transparent letter holes. Straight-on orthographic artwork with small transparent margins. Landscape canvas.
