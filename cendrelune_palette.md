# CENDRELUNE — Palette de référence
*Pixel art, monde vert et vivant, tons sourds façon Miyazaki. Valeurs de départ à ajuster après un premier test en jeu.*

---

## Règles d'usage

1. **Saturation** (HSL) : sol et végétation restent sous 36 %, le bâti (chaume, tuiles, bois) et les accents d'équipe sous 50 %. Seul l'or de consignation monte plus haut (environ 61 %), parce qu'il doit se repérer immédiatement. Les tons très clairs comme le vide sortent de cette règle : leur saturation HSL est trompeuse.
2. **Le vide est la couleur la plus claire du jeu.** Aucun autre élément ne s'en approche : les roches restent nettement plus sombres, la pierre des Attentifs reste plus foncée d'un cran.
3. **Le vert n'est jamais pur.** Toujours un vert olive tiré vers le jaune, avec 3-4 variantes par zone pour casser l'aplat.
4. **L'or et le bleu nuit de consignation** sont réservés au héros, au registre, au mur des noms, au Répit et à l'Innommable. Ne les utilise pas ailleurs, sinon le motif perd son sens.
5. **Test de lisibilité** : passe la capture du tableau en niveaux de gris. Les tuiles de terrain qui se touchent souvent (plaine, colline, forêt, eau) doivent rester distinguables par leur luminosité seule : les valeurs ci-dessous donnent un rapport de contraste d'au moins 1,25 entre la plaine et chacune des trois autres. Les rochers sont des objets posés sur une tuile : leur silhouette et leur ombrage les distinguent, pas la luminosité.
   - **Exception connue** : la route et l'eau ont presque la même luminosité. Seule la teinte (brun contre bleu-vert) les sépare, donc un pont devra être nettement plus clair que les deux.

---

## Végétation

| Nom | Hex | Usage |
|---|---|---|
| Herbe base | `#738A48` | Plaine, tuile principale |
| Herbe claire | `#869A56` | Variante, zones ensoleillées |
| Herbe sèche | `#8E9356` | Bords de chemin, touffes sèches |
| Herbe ombre | `#5E7339` | Variante, pieds d'arbres |
| Colline | `#A2A468` | Tuile de colline, nettement plus claire que la plaine |
| Feuillage chêne | `#4A5E33` | Forêts, arbres |
| Sous-bois | `#2F4026` | Ombres profondes, forêt dense |

## Terre et bâti

| Nom | Hex | Usage |
|---|---|---|
| Chemin | `#8A6A44` | Routes de terre |
| Terre ombre | `#6B5236` | Bords et ornières des chemins |
| Labour | `#785B3E` | Champs cultivés |
| Chaume | `#C2A05A` | Toits de paille, meules, blé |
| Bois | `#5C4129` | Poutres, palissades |
| Bois clair | `#7A5B3C` | Murs, enclos, charrettes |
| Toit tuile | `#9A5A3C` | Toits de tuiles rouille |

## Pierre

| Nom | Hex | Usage |
|---|---|---|
| Roche | `#A09888` | Rochers, falaises |
| Roche claire | `#B8B0A0` | Faces éclairées |
| Roche ombre | `#6E675B` | Faces dans l'ombre |
| Pierre Attentifs | `#C9BFA6` | Ruines des Attentifs |
| Attentifs ombre | `#A59A82` | Ombres et reliefs de ces ruines |

## Eau et vide

| Nom | Hex | Usage |
|---|---|---|
| Eau | `#4A7882` | Rivières, étangs |
| Eau profonde | `#38606A` | Centre des rivières |
| Rive | `#C0AE86` | Berge sableuse, sans effet lumineux |
| Vide | `#F2EDE0` | Tuile effacée, papier clair |
| Vide grain | `#E6DFCD` | Fibres et grain de la tuile vide |
| Vide bord | `#CFC6B0` | Liseré d'encre pâle au bord de l'Effacement |

## Factions et accents

| Nom | Hex | Usage |
|---|---|---|
| Ordre charbon | `#2E2A26` | Tissus sombres des Chroniqueurs |
| Ordre cuir | `#5A4330` | Cuir, sangles, registre |
| Chœur cendre | `#8A8A88` | Bannières et pierres du Chœur |
| Chœur prune | `#362532` | Robes et ombres du Chœur |
| Chœur teal | `#5F8F8A` | Lueur du Fossoyeur, accent unique |
| Consignation bleu nuit | `#24384A` | Encre, anneau de consignation |
| Consignation or | `#D1A63F` | Éclat de consignation, Répit |

## Couleurs d'équipe (lisibilité tactique)

| Nom | Hex | Usage |
|---|---|---|
| Joueur | `#4E63A0` | Bouclier, bannière, socle d'unité (indigo, volontairement éloigné du bleu-vert de l'eau) |
| Adversaire | `#9C4338` | Idem |
| Neutre | `#A88A45` | Camps neutres, prisonniers |

Le neutre est un ocre assez proche de l'or de consignation. Ils restent distinguables par la luminosité et par l'usage, mais si tu les confonds à l'écran, passe le neutre vers un gris-vert (`#8F947D` par exemple).

---

## Teintes par type de terrain

| Terrain | Hex de base | Remarque |
|---|---|---|
| Plaine | `#738A48` | Avec les 3 variantes d'herbe |
| Colline | `#A2A468` | Plus jaune et nettement plus claire que la plaine |
| Forêt | `#4A5E33` | La plus sombre des teintes de sol |
| Route | `#8A6A44` | Chaud, contraste net avec la plaine |
| Roche | `#A09888` | Plus clair et plus gris que le sol |
| Eau | `#4A7882` | Seule teinte froide du biome |
| Vide | `#F2EDE0` | La plus claire de toutes |

---

## Phrase à ajouter à tes prompts de génération

```
pixel art, muted earthy palette, olive green grass (#738A48), warm brown dirt paths (#8A6A44), weathered grey-brown stone (#A09888), desaturated teal water (#4A7882), warm straw thatch (#C2A05A), soft natural lighting, Miyazaki-like pastoral mood, no neon colors, no saturated primaries, max 36% saturation on ground and vegetation
```

## Verrouiller la palette

Les générateurs d'images ne respectent les hex codes que de façon approximative. Pour garantir la cohérence entre assets, génère d'abord, puis **remappe sur cette palette** :

- **Aseprite** : importe le fichier `cendrelune_palette.hex` fourni (Palette > Load Palette), puis convertis le sprite en mode indexé avec cette palette.
- **Lospec / GIMP / Krita** : le format `.hex` (un code par ligne) est accepté par la plupart des outils de pixel art.
- **Variante de teinte** : si un asset est correct mais légèrement hors palette, remappe-le sur la palette plutôt que de le régénérer.

Un remap peut dénaturer des dégradés fins. Teste d'abord sur un asset isolé avant de l'appliquer à tout le lot.
