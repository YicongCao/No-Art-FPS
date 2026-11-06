# Adapted original A-site layout calls; MIT, see LICENSE-dust2.txt.
# Levels: site 0.0 | short +2.5 | pit -2.4 | CT -3.5
# ---------------------------------------------------------------- floors
add_box('floor_site', -14, 16, -12, 14, -3.0, 0.0, M_GROUND)
add_box('floor_site_slab', -7, 9, -7, 9, -0.02, 0.04, M_COBBLE, bevel=0.02)          # plant zone stone slab
add_box('floor_long', -66, -14, 6, 14, -3.0, 0.0, M_ROAD)
add_box('floor_long_edge_n', -66, -14, 12.6, 14, -3.0, 0.012, M_GROUND2)
add_box('floor_long_edge_s', -66, -14, 6, 7.2, -3.0, 0.012, M_GROUND2)
add_box('floor_pit', -22, -14, -4, 2, -3.5, -2.4, M_GROUND2)
add_wedge('pit_slope', -22, -14, 2, -2.4, 6, 0.0, -3.5, M_TRIM)
add_box('floor_ct', -4, 16, -42, -28, -5.0, -3.5, M_ROAD)
add_wedge('ramp', 10, 16, -28, -3.5, -12, 0.0, -5.0, M_PAVE)
add_box('floor_short', -46, -8, -11, -6, -3.0, 2.5, M_COBBLE)                          # short corridor + platform (solid)
for i in range(9):                                                                     # stairs short -> site (0.25 m risers)
    add_box(f'stair_{i}', -8 + 0.44*i, -8 + 0.44*(i+1), -11, -6, -1.0, 2.25 - 0.25*i, M_TRIM, bevel=0.01)
add_box('short_parapet', -14, -8, -6.3, -6.0, 2.5, 3.5, M_WALL, bevel=0.02)            # low wall overlooking site
add_box('short_parapet_cap', -14.05, -7.95, -6.35, -5.95, 3.5, 3.6, M_TRIM, bevel=0.02)
add_box('pit_ledge', -14.4, -14, -4, 2, 0.0, 0.7, M_TRIM, bevel=0.02)                 # low wall at pit edge

# ---------------------------------------------------------------- buildings
B_N  = building('B_north',  -66, 22,  14, 22,  -0.5, 6.5, M_WALL,  faces='S', base_z=0)
B_E  = building('B_east',    16, 26, -46, 14,  -5.0, 8.5, M_WALL,  faces='W', base=False)
add_box('B_east_base_site', 15.92, 16.3, -12, 14.08, -0.6, 0.9, M_STONE, bevel=0.02)
add_box('B_east_base_ct', 15.92, 16.3, -46.08, -28, -4.1, -2.6, M_STONE, bevel=0.02)
B_S  = building('B_south',   -4, 10, -30, -12, -5.0, 6.5, M_WALL,  faces='N', base={'N': 0, 'S': -3.5})
B_SW = building('B_southwest', -60, -4, -20, -11, -5.0, 6.0, M_WALL2, faces='N', beams=False, base_z=2.5)
B_W  = building('B_west',   -48, -22,  -6,  6,  -3.5, 6.5, M_WALL,  faces='N', beams=False, base_z=0)
B_PITS = building('B_pitwall', -22, -14, -6, -4, -3.5, 6.0, M_WALL, faces='', parapet=True, base=False, beams=False)
B_CTS = building('B_ctsouth', -4, 26, -48, -42, -5.0, 6.0, M_WALL2, faces='N', base_z=-3.5)
B_CTW = building('B_ctwest', -10, -4, -42, -20, -5.0, 6.5, M_WALL, faces='E', beams=False, base={'E': -3.5})
B_TW = building('B_tspawn_w', -70, -66, 6, 22, -0.5, 6.5, M_WALL, faces='', beams=False)
SH_N = add_box('short_wall_n', -46, -14, -6.0, -5.2, 2.5, 6.5, M_WALL2)
add_box('short_wall_n_cap', -46.1, -13.9, -6.1, -5.1, 6.45, 6.6, M_TRIM, bevel=0.02)

# Long doors: wall across long at x=-56 with a big arched double door (open)
LD = add_box('long_doors_wall', -56.8, -56, 6, 14, -0.5, 6.5, M_WALL2)
arch_cut_y(LD, -56.4, 8.2, 11.8, 3.6, 3.6)
add_box('long_doors_cap', -56.95, -55.85, 5.9, 14.1, 6.0, 6.6, M_WALL2, bevel=0.03)
add_box('long_doors_lintel', -57.0, -55.8, 7.9, 12.1, 3.55, 3.85, M_WOOD, bevel=0.01)
add_box('long_door_L', -56.0, -54.3, 8.05, 8.2, 0.0, 3.3, M_DOOR, bevel=0.01)
add_box('long_door_R', -56.0, -54.3, 11.8, 11.95, 0.0, 3.3, M_DOOR, bevel=0.01)

# Short doors: at x=-46 across the short corridor (Z 2.5)
SD = add_box('short_doors_wall', -46.6, -46, -11, -6, 2.5, 7.0, M_WALL)
arch_cut_y(SD, -46.3, -9.8, -7.2, 2.6, 3.2, z0=2.5)
add_box('short_doors_lintel', -46.7, -45.9, -10.1, -6.9, 5.65, 5.9, M_WOOD, bevel=0.01)
add_box('short_door_L', -46.0, -44.9, -9.75, -9.6, 2.5, 5.4, M_DOOR, bevel=0.01)

# Goose nook (NE corner)
add_box('goose_wall', 10.4, 11.1, 9.0, 14.0, -0.2, 3.4, M_WALL)
add_box('goose_wall_cap', 10.3, 11.2, 8.9, 14.05, 3.35, 3.55, M_TRIM, bevel=0.02)
