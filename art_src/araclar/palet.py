"""Ortak makine paleti (STANDART.md). Makine görsellerinde sadece bu renkler kullanılır."""

PALET = {
    # çelik gövde, koyudan açığa
    'ink': '#111b28', 'deep': '#1a2938', 'dark': '#283c4e', 'steel': '#425c70',
    'mid': '#617e91', 'light': '#9db4bf', 'shine': '#d2dcd4',
    # pas, bakır ve sarı vurgu
    'rust': '#693d30', 'orange': '#b96537', 'amber': '#e69b53', 'gold': '#f2c078',
    # yeşil gösterge
    'mintdark': '#277564', 'mint': '#70d6b2',
    # toz ve cevher
    'dustdark': '#6e6656', 'dust': '#a69b83', 'oredark': '#5e4640', 'ore': '#8a6a5e',
    # ateş ve eriyik metal
    'ember': '#7a2418', 'red': '#c8442a', 'flame': '#f07a2a', 'yellow': '#ffd24a',
    'hot': '#fff3c4',
    # kömür
    'coal': '#24242a', 'coallight': '#3a3a44',
    # duman
    'smoke1': '#a9b3b9', 'smoke2': '#7d8a93', 'smoke3': '#5a6670',
    # mavi ışık
    'blue': '#4fa3d1',
}
assert len(PALET) <= 32
