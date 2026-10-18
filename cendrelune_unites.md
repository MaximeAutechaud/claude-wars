# CENDRELUNE — Prompts de sprites d'unités
*Pixel art, générateur de sprites (PixelLab ou équivalent). Prompts en anglais pour de meilleurs résultats. Couleurs tirées de `cendrelune_palette.md`. Version 2 : skins de classe pour les compagnons, skins propres pour ennemis et neutres.*

---

## 1. Principe des skins

| Famille | Skin en jeu | Où vit l'individualité |
|---|---|---|
| **Aurel** (héros) | Sprite unique, jamais lié à une classe | Sprite lui-même, plus portraits et artworks |
| **Compagnons** (Sella, Orwen, Maelys, Reya, Corwin) | **Skin de classe** (voir §5) + **marqueur d'identité** (§6) en surcouche | Portraits et artworks de dialogue |
| **Unités génériques du joueur** | Skin de classe, sans marqueur | Aucune |
| **Ennemis** (Chœur, pillards, boss) | Skins propres (§8) | Sprite lui-même |
| **Neutres** (prisonniers, civils) | Skins propres (§9) | Sprite lui-même |

### Pourquoi un marqueur d'identité
Si Sella a exactement le sprite d'une archère générique, le joueur ne la repère plus sur le plateau, alors que tout le jeu repose sur l'attachement. Chaque compagnon porte donc **deux marqueurs** sur son sprite de classe :
1. une couleur de cheveux ou de couvre-chef distincte ;
2. un accessoire signature.

Le marqueur se fait en **surcouche** (palette swap des cheveux plus un petit élément dessiné). On dessine chaque sprite de classe une seule fois, et le compagnon est une variante. Le nom s'affiche en bandeau à la sélection et au survol, jamais sur le sprite : l'or reste réservé à la consignation.

---

## 2. Mode d'emploi

### Ce qui change par rapport aux unités actuelles
Les unités du tableau test sont trop petites, trop saturées et trop « génériques fantasy ». Ces prompts corrigent trois choses :
- **Échelle** : le sprite occupe environ 85 % de la hauteur du canevas, corps entier.
- **Palette** : tissus sourds et cuirs, pas d'aplats saturés. Chaque faction a ses couleurs (voir §3).
- **Identité** : l'Ordre est pauvre et rapiécé (pas de plate), le Chœur est propre, calme et sans emblème.

### Bloc de style commun (à coller au début de chaque prompt)
```
pixel art game unit sprite, full body, low top-down three-quarter view, character fills about 85% of the canvas height, transparent background, muted earthy palette, desaturated fabrics and worn leather, no neon, no glossy metal, selective outline using a darker shade of the local color instead of pure black, 1px lighter rim on the lit side so the sprite stays readable against dark forest tiles, soft flat shading, hand-painted pixel art, Miyazaki-like pastoral mood,
```

### Prompt négatif (si ton outil en propose un)
```
plate armor, shiny chrome metal, saturated primary colors, anime style, large emblem or heraldry, glowing magic aura, fantasy cliché, black outline, 3D render, blurry, text, watermark
```

### Réglages à vérifier dans ton outil (les noms varient)
- Vue : plongée légère (low top-down), 4 directions minimum (8 si possible).
- Contour : sélectif/coloré plutôt que noir. Ombrage : simple. Niveau de détail : moyen.
- Taille : garde celle de tes sprites actuels pour ne pas casser la grille, mais le personnage doit remplir le canevas.

### Couleur d'équipe
Chaque prompt contient `TEAM_COLOR`. Remplace-le selon le camp :
- **Joueur** (Ordre, compagnons, recrues) : `indigo blue (#4E63A0)`
- **Adversaire** (Chœur, pillards) : `brick red (#9C4338)`
- **Neutre** : `muted ochre (#A88A45)`

Elle est placée sur un élément fin et dégagé (écharpe, cordon ou bandeau, 3-4 px), jamais sur de grandes surfaces. Ne mets aucun tissu rouge ou bleu indigo ailleurs sur le sprite, sinon l'équipe devient illisible. Fais ton remap sur la palette après génération, puis vérifie que cette couleur est restée distincte.

### Taille relative
Adulte = 100 %. Corwin = environ 80 %. Fossoyeur = environ 115 %. Orwen = même hauteur qu'un adulte, mais environ 110 % de largeur. Les cavaliers sont plus hauts à cause de la monture : garde-les dans l'emprise d'une case.

---

## 3. Palettes de faction

| Faction | Couleurs dominantes (hex) | Règle |
|---|---|---|
| Ordre des Chroniqueurs | charbon `#2E2A26`, cuir `#5A4330`, cuir clair `#7A5B3C` | Tissus rapiécés et asymétriques, un registre ou une plume visible |
| Chœur Silencieux | cendre `#8A8A88`, prune `#362532`, accent teal `#5F8F8A` | Propre, ordonné, sans aucun emblème ni inscription |
| Civils et neutres | lin `#C9BFA6`, brun `#7A5B3C`, olive `#8E9356` | Vêtements simples, pas d'équipement militaire |
| Pillards | cuir rouille `#6B5236`, brun `#5C4129`, tissu sale `#6E675B` | Équipement dépareillé, visage couvert |

L'or de consignation (`#D1A63F`) n'apparaît que sur Aurel, et seulement en petite touche : le héros ne doit pas avoir l'air d'un mage.

---

## 4. Aurel — le héros (sprite unique)

Scribe-soldat, fatigué, rapiécé. Portrait de référence : cheveux noirs en bataille, cicatrice en croix sur la joue.
```
[STYLE BLOCK] a weary young chronicler-soldier, short messy black hair, small X-shaped scar on the cheek, hood pulled down on the shoulders, patched asymmetrical charcoal cloak (#2E2A26) with visible stitched repairs, brown leather shoulder strap (#5A4330) carrying a worn leather-bound ledger on the hip, a quill tucked into a pouch with a tiny gold glint on the quill tip only (#D1A63F), short sword at the belt, quiet hollow expression, slightly slumped shoulders, scarf in TEAM_COLOR
```
Note : aucune lueur magique, aucune veine dorée sur la main. Le pouvoir est discret, c'est le fil conducteur du foreshadowing. Il est le seul à porter une capuche rabattue sur les épaules, avec le Chœur : voir §10 pour éviter la confusion.

---

## 5. Les 6 classes de base (skins niveau 1)

Ce sont les sprites que portent à la fois les unités génériques du joueur et les compagnons (avec leur marqueur, voir plus bas). Écris les prompts en neutre, **sans marqueur individuel**.

### Éclaireur
Guetteur de l'Ordre. Léger, rapide. Pas de capuche (réservée à Aurel et au Chœur).
```
[STYLE BLOCK] a lean scout of a poor monastic order, light brown leather jerkin (#7A5B3C) over a worn undyed linen shirt, short patched charcoal cape (#2E2A26) clasped at one shoulder, no hood, leather headband, light satchel and a coil of rope, short knife at the belt, soft-soled boots, alert watchful posture, a thin cord in TEAM_COLOR around the arm
```

### Guerrier
Ancien « Soldat de l'Ordre ». Il est aussi la troupe de base de l'Ordre.
```
[STYLE BLOCK] a common soldier of a poor monastic order, patched charcoal tabard (#2E2A26) over brown leather (#5A4330), plain round wooden shield without any emblem, short sword, simple leather cap or bare head, a small ledger-shaped pouch at the belt, tired honest face, sash in TEAM_COLOR
```

### Cavalier
Estafette de l'Ordre. Monture de travail, pas de destrier de parade.
```
[STYLE BLOCK] a courier-rider of a poor monastic order on a plain brown working horse (#5C4129), no barding, simple leather saddle with saddlebags, rider in a patched charcoal coat (#2E2A26) with brown leather vambraces (#5A4330), short sword at the hip, upright alert posture, a strip of cloth in TEAM_COLOR tied to the saddle bag and the arm
```

### Archer
Chasseur ou paysan-tireur. Aucune armure.
```
[STYLE BLOCK] a rural archer, olive-brown wool tunic (#8E9356) under a worn brown leather jerkin (#7A5B3C), sleeves rolled up, simple longbow in hand and a quiver of plain arrows on the back, no armor, practical boots, narrow cloth sash in TEAM_COLOR
```

### Apothicaire
Infirmier, herboriste. Pas de croix rouge ni d'emblème.
```
[STYLE BLOCK] a field apothecary, undyed linen apron (#C9BFA6) over a brown wool tunic (#7A5B3C), a leather satchel full of dried herbs and rolled bandages, a small clay jar in hand, rolled sleeves, kind tired face, no emblem, a ribbon in TEAM_COLOR tied at the waist
```

### Alchimiste *(ex-Mage des braises)*
Pas un mage : un artisan du feu (charbonnier, chaufournier). Aucune aura magique.
```
[STYLE BLOCK] a soot-stained craftsman alchemist, thick scorched leather apron (#5A4330) over a charcoal shirt (#2E2A26), bandolier of corked clay flasks with dull muted glass, leather gloves, cloth wrapped over the lower face, tongs at the belt, small ember glow at a rag fuse only, no magic aura, wary focused posture, a strip of cloth in TEAM_COLOR on the arm
```

---

## 6. Compagnons : marqueurs d'identité (surcouche)

À appliquer sur le sprite de classe correspondant, y compris sur ses 3 spécialisations. La couleur des cheveux ou du couvre-chef est le premier repère, l'accessoire le second.

| Compagnon | Classe | Marqueur 1 (cheveux / couvre-chef) | Marqueur 2 (accessoire) | Autre repère |
|---|---|---|---|---|
| Sella | Archer | cheveux bruns en tresse courte | **bourse de graines** cousue à la ceinture, bien lisible (objet-mémoire si elle tombe) | tenue d'olive et de brun |
| Orwen | Guerrier | cheveux et barbe gris, coupe courte | **cordon d'équipe sur le haut du bras**, plus visible que sur les autres | silhouette plus large (110 %), posture calme |
| Maelys | Éclaireur | cheveux bruns très courts | **couverture grise sur les épaules** et **fragment de chaîne brisée au poignet** | sans arme visible tant qu'elle ne se spécialise pas Assassin |
| Reya | Cavalier | cheveux sombres tirés en arrière | **tube à cartes** et petit carnet à la selle | manteau le plus net du groupe |
| Corwin | Apothicaire *(provisoire)* | cheveux châtains en bataille | **tunique trop grande**, manches retroussées | échelle réduite (80 %), jamais de cicatrice ni d'armure |

Note : Corwin garde sa fragilité visible même en spécialisation. Ne le durcis pas.

---

## 7. Spécialisations (18) : différences visuelles

Chaque spécialisation reprend le prompt de la classe de base et ajoute **une seule ligne** de différence. Règle de lisibilité : les trois branches d'une même classe doivent se distinguer par la silhouette (arme, bouclier, monture), pas seulement par un détail interne.

### Éclaireur
- **Ombre** : `darker matte cloak, cloth-wrapped boots, cloth over half the face, low crouched stealthy posture, no pack`
- **Survivaliste** : `lone trapper look, fur-trimmed collar, hatchet at the belt, bedroll on the back, rugged posture`
- **Assassin** : `leaner build, short blade in each hand, leather bracers, no pack or satchel, predatory posture`

### Guerrier
- **Rempart** : `thicker padded gambeson, tall plain rectangular wooden shield with iron bands, bulkier silhouette, plain open helmet`
- **Vengeur** : `dented round shield held out in a counter stance, short spear, battle notches on the sash, alert expression`
- **Berserker** : `no shield, two hand axes, bare forearms, open shirt, wild hair, unarmored (avoid any red cloth)`

### Cavalier
- **Percée** : `light rider, short sword drawn, cloak flying, lean horse with light saddlebags`
- **Sagittaire** : `short horse bow in hand, quiver at the saddle, no sword, light rider`
- **Cataphracte** : `heavy horse with a padded felt caparison, rider in a quilted coat, long lance, no plate of any kind`

### Archer
- **Rôdeur** : `snare rope coil and weighted hobbling arrows at the belt, leaf-brown short cloak, no hood`
- **Tireur d'élite** : `noticeably longer bow, cloth-wrapped bow arm, bracer, steady still stance, feather-fletched arrows`
- **Arbalétrier** : `small heavy crossbow, padded shoulder pauldron of boiled leather, short sword, planted stance`

### Apothicaire
- **Guérisseur** : `staff with a bundle of herbs, pale linen shawl, holding a small clay jar out in front`
- **Médecin de guerre** : `bandolier of linen strips, open field satchel with tools, sleeves rolled, ready to move, short knife`
- **Droguiste** : `bandolier of corked clay vials with pale green and yellow contents, cloth over the lower face, throwing posture` *(à ne pas confondre avec l'Alchimiste : herbes et lin, pas de suie)*

### Alchimiste
- **Incendiaire** : `clay oil jars at the belt, a rag fuse lit with a small flame, scorched sleeves`
- **Boutefeu** : `long slow-match cord coiled over the shoulder, one heavy flask, leather goggles pushed up on the forehead`
- **Enfumeur** : `beekeeper-style tin smoker with a pale grey smoke wisp, cloth over face, bellows at the belt` *(la fumée est un gris neutre, pas le teal du Chœur)*

---

## 8. Le Chœur Silencieux (ennemis)

Silhouette de référence : robes longues, mains vides, aucun bouclier rond. Le Chœur ne doit jamais ressembler à l'Ordre en silhouette (voir §10).

### Le Fossoyeur — boss de l'Acte I
Calme, convaincu, jamais cruel. Pas d'arme.
```
[STYLE BLOCK] a tall gaunt commander, about 115% of normal height, shaved head, serene half-closed eyes, long ash-grey robes (#8A8A88) with prune lining (#362532), no emblem or inscription anywhere, one open palm extended forward with a faint pale teal glow (#5F8F8A) and a few light dust particles, barefoot, no weapon, perfectly calm expression, thin cord in TEAM_COLOR at the waist
```
Note : le calme est le point d'ancrage. Aucun symbole, aucune arme : il ne doit surtout pas ressembler à un méchant de dark fantasy.

### Soldat du Chœur
Unité de base. Propre, ordonnée, sans visage menaçant. **Modifié : plus de bouclier rond** (il se confondait avec le Guerrier de l'Ordre).
```
[STYLE BLOCK] a cultist soldier in a long hooded ash-grey padded tunic down to the knees (#8A8A88), two-handed plain spear held upright, no shield, neat uniform look, calm expressionless face, no emblem, no decoration, clean fabric without dirt or blood, thin cord in TEAM_COLOR around the arm
```

### Acolyte du Chœur
Soutien/portée. Il « libère » plutôt qu'il ne tue.
```
[STYLE BLOCK] a robed acolyte with a shaved head, long plain grey-plum robe (#362532), hands open in front, a staff wrapped in blank pale cloth with no writing, barefoot, faint pale dust (#E6DFCD) drifting from the open palm, serene almost kind face, thin cord in TEAM_COLOR at the waist
```
Note : la poussière pâle renvoie à la couleur du vide. Elle ne doit pas être plus lumineuse que le reste du sprite.

### Pillard
Ennemi de tableau (Tableaux 1 et 2).
```
[STYLE BLOCK] a ragged bandit raider, mismatched worn gear, rust-brown leather vest (#6B5236), dirty cloth wrapped around the lower face (#6E675B), hand axe, patched trousers, one oversized pauldron of plain dull iron, hunched aggressive posture, cloth strip in TEAM_COLOR on the arm
```

---

## 9. Neutres

### Prisonnier
Détenu d'un camp neutre. Il doit se lire comme quelqu'un qui vient de sortir de captivité. Il garde ce sprite tant qu'il est neutre.
```
[STYLE BLOCK] a thin captive prisoner, torn undyed linen shirt (#C9BFA6), rope belt, bare forearms with a broken iron shackle still hanging from one wrist, no weapon, hunched exhausted posture, tired but determined face, scarf in TEAM_COLOR knotted at the neck
```
Note : la chaîne cassée est le détail narratif qui compte. Elle dit « consigné ou sauvé » sans texte. **À trancher côté design** : une fois libéré et recruté, le prisonnier devient-il directement une classe de base (laquelle ?), ou garde-t-il un sprite dédié jusqu'au niveau 1 ? La première option est plus simple et cohérente avec la règle des niveaux.

---

## 10. Vigilances

- **Silhouettes Aurel / Éclaireur / Chœur.** Aurel porte une capuche rabattue, le Chœur des capuches et des robes. Les différencier à distance : Aurel a le manteau court, le registre à la hanche et une épée courte ; le Chœur a des robes longues, les mains vides et jamais de bouclier rond ; l'Éclaireur n'a jamais de capuche.
- **Guerrier vs Soldat du Chœur.** La couleur d'équipe est trop petite pour les séparer. Les différences de silhouette (bouclier rond contre lance à deux mains, tabard court contre tunique longue) doivent faire le travail.
- **Les teintes de peau** ne sont pas dans la palette. Au remap, elles seront poussées vers les bruns les plus proches. Regarde les visages après remap : si ça les ternit, ajoute 2 teintes de peau à la palette plutôt que de forcer.
- **Lisibilité sur forêt** : les unités vertes ou grises se confondront avec le feuillage. Le liseré clair de 1 px est là pour ça. Vérifie-le sur une case de forêt avant de valider tout le lot. Cible en priorité l'Archer (olive) et le Chœur (gris).
- **Coût réel des spécialisations.** 6 bases plus 18 spécialisations font 24 sprites (jusqu'à 96 vues à 4 directions). Fais d'abord les 6 bases, puis les spécialisations de la classe qui contient un compagnon d'Acte I.
- **Cohérence entre générations** : génère d'abord un sprite, puis garde le même bloc de style et les mêmes réglages pour tous les autres. Change seulement la description.
- **Les prompts sont une base** : le rendu dépend beaucoup de ton outil. Compte 2 à 3 itérations par sprite de classe, une seule pour les génériques.
- **Ordre conseillé (Acte I)** : Aurel, Guerrier (Orwen), Archer (Sella), Soldat du Chœur, Pillard, Éclaireur (Maelys), Cavalier (Reya), Apothicaire (Corwin), Fossoyeur, Prisonnier. Les spécialisations viennent plus tard, car la promotion ne se débloque qu'après le niveau 3.
