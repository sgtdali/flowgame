# Node editör mockup v1 — üretim istemi

Araç: yerleşik image_gen. Tarih: 2026-10-20.

## İlk üretim

Use case: ui-mockup.
Create a single high fidelity desktop game UI mockup for FLOWGAME, a node based industrial production strategy game designed in a local Obsidian game_design vault. This is a polished proposed game screen, not a webpage, not an infographic, not a diagram presentation. Landscape 16:9, preferably 2560x1440 or higher. Straight-on full-screen interface, no monitor frame, no perspective, no external margins. All visible UI language is TURKISH with correct Turkish glyphs.

Visual direction: premium, restrained industrial workstation aesthetic; very dark blue-grey infinite canvas with extremely subtle dotted grid, slightly lighter slate machine cards, crisp off-white text, warm amber selection and metal products, cool desaturated blue for rods/plate, copper orange for coil paths, soft mint for running state. Avoid harsh neon, oversaturated glow, grunge, sci-fi holograms. Clear hierarchy and lots of breathing room, professional game UI, tactile but clean card components. Distinct small elegant isometric machine illustrations or detailed machine icons within card headers, actual industrial CNC, rolling machine, coil winding machine, press. The majority of each card is readable UI, not artwork. Consistent sans typography and tabular numbers.

Composition:
A slim top bar with FLOWGAME, "Üretim Ağı" active, "Araştırma", pause and "1×" controls, save icon. Small "GÖRSEL TASARIM ÖNERİSİ" badge so the screen is explicitly conceptual.
A narrow left machine library with search "Makine ara..." and machine entries "CNC Tezgâhı", "Torna", "Pres", "Hadde Tezgâhı", "Bobin Sarma". Compact icons, no large illustrations. Main canvas occupies around 75 percent of screen width. Right side a restrained inspector for the selected CNC, about 18 percent width. Thin bottom bar with zoom and small minimap in the bottom-right of canvas, tasteful guidance.

Core content is a legible production graph with only SIX large clearly separated cards and no overlapping wires over text:
Three upstream cards on canvas left: "Hadde Tezgâhı" output "Demir çubuk · 24/dk"; "Bobin Sarma" output "Bakır bobin · 18/dk"; "Levha Presi" output "Çelik levha · 6/dk". Their resources may enter from off-screen left to suggest a larger system, without adding more cards.
Middle selected larger card "CNC Tezgâhı", warm amber selected outline, small CNC machine image. Input left port "Demir çubuk", output right port "Dişli". Recipe displayed exactly "2 demir çubuk → 1 dişli". Below "20 iş/sn", "5,0 sn / çevrim", "Kapasite 12/dk". Input buffer "Giriş 6/8", output buffer "Çıkış 0/8". Horizontal progress around 62%, state "Çalışıyor". The rolling machine feeds CNC at 24 rods/minute.
Two downstream cards on right side of canvas, NOT inspector: upper "Araştırma Merkezi", lower "Montaj Tezgâhı". CNC produces 12 gears/minute and fans out into two equal automatic flow branches, each labelled "Dişli · 6/dk", no manual split sliders or percentages. A tiny tasteful "Otomatik paylaşım" tag near the Y branch. Every connection begins and ends at visible circular ports. At the research card the gear, copper coil and steel plate wires arrive at THREE distinct input ports. Route coil and plate wires in gently curved lower lanes away from card bodies and away from gear fork. Lines easy to trace, few gentle curves, small moving bead accents optional. Do not cross through any node.
Research card title "Araştırma Merkezi", subtitle "Endüstriyel Otomasyon I", progress "24 / 60 deney". Compact input rows: "Dişli 6 / 12 dk", "Bakır bobin 18 / 18 dk", "Çelik levha 6 / 6 dk". Warm amber small warning "Dişli darboğazı". Make the required versus incoming rates understandable; the lack of gears is deliberate because production is shared. Montage card shows "Dişli girişi 6/dk", a small input buffer and a mint "Çalışıyor" state, no invented complicated motor recipe or additional demands.

Inspector for selected CNC:
Header "CNC TEZGÂHI", tiny "Seçili makine".
"Reçete" / "Dişli"
"2 demir çubuk → 1 dişli"
"Gereken iş" "100 birim"
"İşleme hızı" "20 birim/sn"
"Çevrim süresi" "5,0 sn"
"Üretim kapasitesi" "12 adet/dk"
A thin separator and clear process explanation "100 ÷ 20 = 5 saniye".
Small pair of inlet/outlet inventory bars and simple "Durdur" button. No sliders for allocation, no per-card machine counts, no upgrade costs.
Bottom subtle legend "Mavi: metal girdiler   Bakır: bobin   Sarı: dişli" and small zoom "100%".

Constraints: Cards must represent MACHINES, not abstract product-only boxes. Use discrete-cycle production, recipe workload divided by compatible machine rate, buffers and automatic equal distribution. These are the established mechanics. Do not invent money, power grids, enemies, unit counts, quality grades, regional shipping controls, speed-up premium currency, group capacity controls, huge quests or 3D world terrain. Research details and selected UI presentation are conceptual proposals; no claims of already implemented features. Typography should be sharp and plausible at game scale, do not cram dense paragraphs. Show an attractive usable editor with a clearly readable manufacturing network. Output ONLY the finished image.

## Bağlantı düzeltmesi

Edit this existing FLOWGAME UI mockup. Preserve the exact overall composition, all cards, typography, colors, machine illustrations, and numeric production rates. Make only these precise corrections: The blue steel plate wire from the Levha Presi currently goes into the lower Montaj Tezgâhı card, which is wrong. Remove that blue input port and its final rising wire segment at the Montaj Tezgâhı. Instead route that existing blue steel-plate connection upward through the clear narrow vertical corridor just to the LEFT of the research card, and connect it to a NEW THIRD blue input port on the LEFT EDGE of the Araştırma Merkezi card, below its yellow gear port and copper coil port. The research center must now have THREE distinct inbound connections: yellow gear from CNC, orange coil from Bobin Sarma, blue steel plate from Levha Presi. The Montaj Tezgâhı must have ONLY the yellow gear inlet from the CNC fork; it must not have any blue inlet. Do not obscure any text or machine card body with the rerouted line. Also remove the tiny bottom keyboard hint 'R: Dönüştür' because that action has not been designed; preserve the other bottom controls. All else unchanged. This is a surgical correction of the UI mockup, not a redesign.
