# Claude Wars — Direction artistique

> Registre des décisions de direction artistique (ouvert le 17/10/2026).
> Les mécaniques de jeu sont dans [DESIGN.md](DESIGN.md), la méthode de travail
> dans [METHODE.md](METHODE.md).

## Structure du monde

**Cinq biomes, plus une couche transversale : l'Effacement.** L'Effacement
n'est pas un biome. C'est un calque qui s'applique à tous les autres. Ça
économise beaucoup d'assets et ça colle au lore, puisqu'il peut frapper
n'importe quel lieu.

| Biome | Actes | Rôle |
|---|---|---|
| Terres habitées | I (retours possibles) | Le monde normal qu'on protège |
| Terres sauvages | I à IV | Liaison, embuscades, arène du Fossoyeur |
| Territoires du Chœur | I, IV | Avant-postes, geôles, doctrine |
| Ruines des Attentifs | II, III | Archives, sceau, Gardien |
| La Faille | V | L'Innommable |

## Trois règles de DA tirées du lore

1. **Un monde vivant et vert.** Le vide est la seule chose « morte ». Il est
   pâle (beige papier), jamais noir. C'est ce contraste qui porte le pitch.
2. **Une rupture nette.** La bible dit qu'un lieu est là ou n'est plus là, sans
   dégradé. Les premiers artworks (arbre à moitié dissous, silhouettes
   translucides) racontent plutôt une érosion progressive. En jeu, la grille hex
   impose naturellement un bord net : un hex est plein ou vide, et les objets
   sont tranchés à la limite (une moitié d'arbre, une moitié de maison).
   → Le fondu est réservé à **l'animation de l'instant d'effacement** et aux
   **artworks**.
3. **La règle de l'écriture.** L'Ordre et les Attentifs écrivent. Le Chœur n'a
   rien d'écrit (stèles vierges, inscriptions effacées) et l'Effacement est
   blanc. Le Chœur et le vide se ressemblent visuellement, ce qui prépare
   l'Acte IV.

## Les biomes

### Terres habitées

- **Sol :** prairies, champs cultivés, chemins de terre, pâturages, vergers.
- **Bâti :** maisons à colombages, fermes isolées, moulin, auberge
  (Aubry-le-Bas), grange, ponts de pierre, puits de Vessial.
- **Vie :** fumée de cheminée, enclos, animaux, le carré cultivé de Sella.
- **L'Ordre :** la garnison (palissade, tour modeste, bannière sombre et sobre)
  et, au camp, un **mur des noms** qui se remplit des consignés.
- 🟡 **À valider :** les glyphes des Attentifs survivent ici comme décoration
  folklorique (linteaux, margelles) que plus personne ne sait lire. Ça ferait
  écho à l'Ordre, qui a oublié le sens de son propre rite.

### Terres sauvages

- Forêt de feuillus, claire ou dense, sous-bois, collines, rochers, rivières
  avec gués, marais.
- Falaises et landes côtières, avec le **plateau du Fossoyeur**.
- Ruines banales : mur écroulé, ferme abandonnée *ou* effacée (l'ambiguïté fait
  partie du ton).
- **Prop signature :** le chemin qui s'arrête net.

### Territoires du Chœur

- Stèles sans nom, fosses non marquées, cercles de pierre vides, bannières
  grises sans emblème lisible.
- Avant-postes avec cellules (Maelys), chapelle dépouillée dont l'écriture
  s'efface des murs.
- **Palette :** gris cendre, charbon, un accent teal éteint (celui du
  Fossoyeur).
- **Pas de terre brûlée ni de repaire gothique.** Leurs camps sont propres,
  ordonnés, presque sereins, sur une nature qui reste verte. C'est cohérent avec
  des gens convaincus, pas cruels.

### Ruines des Attentifs

- Architecture-archive : pierre pâle, grands murs-registres, alcôves à noms,
  sols circulaires incrustés.
- **Géométrie ronde** pour éviter le « gothique générique » (que le premier
  artwork avait) : anneaux concentriques, voûtes basses, dômes, lumière
  zénithale.
- Statues commémoratives, réutilisées par le **Gardien du Sceau** pour pétrifier
  les unités. Salle du sceau avec ses mécanismes anciens.
- La végétation reprend ses droits : lierre, mousse, feuillage vert.

### La Faille

- Presque abstraite, donc peu coûteuse : vide pâle et îlots flottants.
- Les îlots réutilisent des fragments des autres biomes, désaturés ou
  semi-transparents (bouts de village, de ruine, armures d'époques
  différentes). Ça évoque les cycles empilés sans jamais donner de chiffre.
- Anneaux géants et écriture qui flotte.

## La couche Effacement

- **Tuile vide :** beige pâle avec un léger grain de fibres, ni noir ni blanc
  pur.
- **Tuiles de bord :** 6 orientations hex, bord net, avec éventuellement un
  liseré d'encre pâle.
- **Animation d'effacement :** l'hex se vide en quelques frames et les props
  disparaissent, sans effet spectaculaire.
- **Répit :** les contours de l'hex se redessinent en traits d'encre.
- **Motif de consignation :** un anneau bleu nuit et or, très discret, présent
  sur les registres, les sols des Attentifs, le mur des noms et le Répit. Il
  revient sur l'Innommable à l'Acte V (fil de foreshadowing visuel).

## Production des assets

- **Palette de référence : [cendrelune_palette.md](cendrelune_palette.md)**
  (codes dans `cendrelune_palette.hex`). Les tons sont sourds, façon Miyazaki
  en pixel art, pas un vert de jeu mobile. On génère, puis on **remappe sur la
  palette** plutôt que de régénérer.
- **Style : pixel art, généré avec PixelLab.** C'est le pack de
  `assets_pixelart/`, que la scène `tests/pixelart_preview.tscn` applique au jeu.
  On ne part jamais de zéro : on donne un asset existant en référence de style.
- **Sol vert olive pour tous les biomes** (règle 1 et palette). Herbe de base
  `#738A48`, traits en herbe claire, sèche et ombre. Les variantes ajoutent des
  taches de teinte décalées de 30 % seulement, effacées près du bord pour ne pas dessiner la
  grille. Les fleurs sont de petites touches rares et irrégulières (jaune pâle
  `#D9D0A0`, blanc cassé `#DDD6C3`), plus sombres que le vide.
- **Chaque tuile déborde d'un pixel** sur ses voisines, sinon le fond passe
  entre deux hexagones en diagonale (pointillés sombres le long de la grille).
- **Forêt en arbres individuels**, dans la même famille que les chênes du
  décor. Chaque case de forêt porte 3 arbres (`decor/oak_N.png`, 16 générés
  et remappés sur la palette), décalés selon la case et débordant sur les
  voisines, comme dans Wesnoth. En dessous, un sous-bois d'herbe ombrée un cran
  plus sombre que la plaine. Le disque d'herbe au pied de chaque arbre devient
  une ombre portée douce.
- **Rochers** : rampe gris-brun (`#A09888`, ombre `#6E675B`). Le beige pâle
  est réservé au vide.
- **Eau** : moyenne sur Eau (`#4A7882`), l'eau profonde en simple accent.
  Remap par quantiles, parce que la texture d'origine est surtout sombre.
  Contraste avec la plaine : 1,29 (la palette visait 1,27).
- **Berge** : un liseré de sable Rive (`#C0AE86`) de 5 px à bord dur. Plus de
  fondu ni d'écume animée, deux dégradés lisses qui faisaient halo.
- **Chemin** : rampe Chemin (`#8A6A44`) bordée de Terre ombre (`#6B5236`).
  Le tracé ne passe plus par le centre des cases : il se rapproche du milieu
  de ses voisines et dévie de quelques pixels selon la case. On lit une trace
  de passage, plus la vague régulière due au décalage des colonnes.
- **Unités** : voir la section [Unités](#unités) plus bas. Couleurs d'équipe
  de la palette (indigo `#4E63A0`, rouille `#9C4338`, ocre `#A88A45`),
  éclaircies seulement pour le texte de l'interface.
- **Le décor n'a aucun effet de jeu.** Champs, vergers, bâtiments et bêtes
  passent par la clé `"decor"` du format de tableau (couche `Decor`). La case
  garde son terrain et ses règles.
- **Archive des générations** : `C:\Users\maxim\Pictures\assets\autogen\biome1\`.

### Terres habitées : props disponibles (`assets_pixelart/decor/`)

| Famille | Props |
|---|---|
| Bâti | `house` (colombages), `farmhouse`, `barn`, `inn` (auberge), `windmill`, `windmill_b`, `well` (puits de Vessial), `well_small`, `shed`, `bread_oven`, `chicken_coop` |
| L'Ordre | `garrison` (palissade, tour, bannière sombre sans emblème) |
| Cultures | `wheat`, `cabbages` (carré de Sella), `scarecrow` (champ labouré), `apple_tree` (verger), `beehives`, `haystack` |
| Vie | `sheep_pen`, `cow`, `flower_bush` |
| Arbres | `oak_0` à `oak_15` (chênes, jeunes pousses, buisson, souche, hêtre, peuplier) |
| Objets | `cart`, `barrels`, `firewood` |

Tableau vitrine : **Aubry-le-Bas** (`Scenario.HABITEES`).

## Unités

Le jeu est d'abord scénaristique : il repose sur des personnages principaux
auxquels on s'attache. Les prompts et toutes les règles sont dans
**[cendrelune_unites.md](cendrelune_unites.md)**. En résumé :

- **Skins.** Aurel a un sprite unique, lié à aucune classe. Les compagnons
  (Sella, Orwen, Maelys, Reya, Corwin) portent le skin de leur classe, plus
  un **marqueur d'identité** en surcouche : une couleur de cheveux ou de
  couvre-chef, et un accessoire signature. Les génériques du joueur ont le
  skin de classe nu. Les ennemis (Chœur, pillards, Fossoyeur) et les neutres
  (prisonniers) ont leurs propres skins.
- **Le nom** s'affiche en bandeau à la sélection et au survol, jamais sur le
  sprite. L'or reste réservé à la consignation : sur une unité, seul Aurel en
  porte, en petite touche au bout de sa plume.
- **Factions.** L'Ordre est pauvre et rapiécé (charbon, cuir, jamais de
  plate). Le Chœur est propre et sans emblème (cendre, prune, teal éteint).
  Les civils portent du lin, du brun et de l'olive. Les pillards ont un
  équipement dépareillé et le visage couvert.
- **Échelle.** Le personnage remplit environ 85 % du canevas. Corwin fait
  80 %, le Fossoyeur 115 %, et Orwen est 110 % plus large.
- **Couleur d'équipe** : un élément fin (écharpe, cordon, bandeau), jamais
  une grande surface. Il n'y a aucun autre tissu indigo ou rouge sur le
  sprite.
- **Silhouettes.** Aurel a un manteau court et une capuche rabattue.
  L'Éclaireur n'a jamais de capuche. Le Chœur porte des robes longues, a les
  mains vides et n'a jamais de bouclier rond. Le Guerrier porte un bouclier
  rond, le Soldat du Chœur une lance à deux mains.

Correspondance avec les types du jeu :

| Type | Skin |
|---|---|
| `hero` | Aurel |
| `infantry` | Guerrier |
| `tank` | Cavalier |
| `archer` | Archer |
| `scout` | Éclaireur |
| `medic` | Apothicaire |
| `mage` | Alchimiste (ex-Mage des braises) |
| `boss` | Fossoyeur |

Le Soldat du Chœur, l'Acolyte, le Pillard et le Prisonnier n'ont pas encore
de type ni de skin dans le jeu.

**Production.**
- **Génération.** Une seule vue de face par unité, la seule que le jeu
  affiche, en `generate-image-v2` (96×96, 4 propositions, environ 10
  générations par appel). Les couleurs sont imposées à la génération :
  palette Cendrelune plus 3 peaux (`#E3C3A0`, `#C49A78`, `#8E6650`).
- **Style commun.** Aurel a été fait sans référence. Il sert d'image de
  style, pour le contour, le détail et l'ombrage, à toutes les autres unités.
- **Couleur d'équipe.** On génère en indigo, puis l'indigo devient le magenta
  clé du shader `team_color`. Quand une proposition n'a pas de couleur
  d'équipe, on recolore un bout de tissu clair au lieu de régénérer.
- **Installation.** Le choix est rogné et installé dans
  `assets_pixelart/units_hd/`.
- **Idle.** `animate-with-text-v3`, 4 frames demandées (5 renvoyées, la
  première redessine la source), action « subtle breathing idle, standing
  still, slight cloak and hair sway ». Environ 1 génération et 3 minutes par
  unité. Boucle installée : le sprite source puis les 4 frames générées
  (`<type>.png`, `_2` … `_5`), ramenées aux couleurs exactes de la source et
  rognées ensemble. En jeu, la boucle garde le cycle d'une seconde de
  l'ancienne paire (0,2 s par frame, `Unit.idle_frames`).
- **Archive.** `C:\Users\maxim\Pictures\assets\autogen\units_v2\`, avec les
  scripts `gen_units.py`, `install_units.py`, `gen_idle.py` et
  `install_idle.py`.

**Sprites de base installés (18/10/2026) :** Aurel, Guerrier, Archer,
Éclaireur, Cavalier, Apothicaire, Alchimiste, Fossoyeur. Les anciens sprites
remappés sont archivés dans `autogen\biome1\units_hd_muted_v1\`.

## Questions ouvertes

- Glyphes des Attentifs utilisés comme décor folklorique dans les Terres
  habitées (voir plus haut).
- Liseré d'encre pâle sur les tuiles de bord de l'Effacement : oui ou non.
- **Pont de pierre** : il manque encore. Aujourd'hui une case de route coupe
  la rivière en deux bassins, donc un pont dessiné n'aurait rien à enjamber.
  Il faut d'abord faire passer l'eau sous la route dans `rivers.gd`.
- **Mur des noms** du camp de l'Ordre : prop sur la carte ou élément d'interface ?
- **Skins par faction en jeu** : aujourd'hui, l'adversaire utilise les mêmes
  types (et donc les mêmes sprites) que le joueur. Il faut qu'une unité du
  tableau puisse porter un skin (Soldat du Chœur, Pillard…), ce qui demande
  du code.
- **Compagnons** : ils n'existent pas encore en jeu. Leurs marqueurs seront
  des variantes du sprite de classe.
- **Prisonnier recruté** : devient-il directement une classe de base
  (laquelle ?) ou garde-t-il un sprite dédié ? Voir `cendrelune_unites.md`
  §9.
- **Directions** : le jeu n'affiche qu'une vue de face, retournée en miroir
  selon le camp. Les 4 directions conseillées par `cendrelune_unites.md` ne
  servent à rien tant que le jeu ne les affiche pas.
- **Fossoyeur** : il a la même taille que les autres (le canevas de 96 px
  plafonne), alors qu'il devrait faire 115 %. La lueur teal de sa paume n'est
  pas sortie non plus.
- **Couleur d'équipe peu lisible** : un cordon de 3-4 px se voit en indigo et
  en rouille, mais l'ocre neutre se perd dans les cuirs. Pour séparer les
  camps, il faudra compter sur les silhouettes de faction, ou ajouter un
  repère hors sprite (socle, bandeau).
- **Animation d'idle (v3)** : à valider en jeu. Il y a une action par classe,
  liée à l'accessoire signature. La lueur teal du Fossoyeur ne sort toujours
  pas : le modèle l'ignore, même quand l'animation la demande. Mieux vaut la
  faire en jeu (particules ou shader) que dans le sprite.
- **Lumière** : uniforme. Il manque une variation chaude (soleil bas) et des
  ombres sous les grands objets.
- **Interface** : gris par défaut, curseur hex jaune vif. À passer sur la
  palette (cuir, charbon, or de consignation).
- **Colline** (`#A2A468`) : la palette prévoit une tuile de colline, le jeu
  n'en a pas encore. La montagne est de la roche posée sur la plaine, donc de
  même luminosité qu'elle (contraste 1,03) : elle se distingue par sa
  silhouette, comme la palette le prévoit pour les rochers.
- **Banc de poissons** : il apparaît parfois sur l'herbe à côté de la rivière
  (bug déjà présent avant).

## Journal des décisions

- **17/10/2026** : socle de DA posé (5 biomes + couche Effacement, 3 règles
  issues du lore, contenu par biome).
- **17/10/2026** : pixel art (PixelLab) retenu pour les assets. Le sol passe
  au vert dans tout le pack, le décor reste purement visuel, et le premier
  jeu de props des Terres habitées est fait avec le tableau Aubry-le-Bas.
- **17/10/2026** : premier retour DA. Bâtiments, props, chêne, chemin et
  rivière sont validés. Le sol, les rochers, l'eau, les unités et les couleurs
  d'équipe sont recalés sur la palette Cendrelune (sans régénération). La forêt
  et le style des unités restent à refaire.
- **17/10/2026** : deuxième retour DA. Eau éclaircie, berge à bord dur, chemin
  recoloré et moins régulier, taches d'herbe adoucies, unités remappées et
  contour sélectif.
- **17/10/2026** : la forêt passe en arbres individuels (16 chênes générés et
  remappés sur la palette), une seule approche pour tout l'écran.
- **18/10/2026** : unités. Aurel a un sprite unique, les compagnons ont un
  skin de classe et un marqueur d'identité, les ennemis et les neutres leurs
  propres skins. Prompts, palettes de faction et règles de silhouette dans
  `cendrelune_unites.md`.
- **18/10/2026** : les 8 sprites de base sont générés et installés (Aurel
  pilote, puis 7 unités dans son style), une vue de face chacun. Les
  compagnons et les spécialisations viendront plus tard.
- **18/10/2026** : idle `animate-with-text-v3` installé sur 6 unités v2. Puis
  Maxime trouve que les unités v2 se ressemblent trop : on ne reconnaît pas
  la classe au premier coup d'œil (mêmes silhouettes, même brun-charbon, même
  pose de face) et le côté chibi lui manque. Décision : **v3 « juste
  milieu »**. Proportions et pose de l'ancien pack chibi (tête environ un
  quart de la hauteur, pose d'action, accessoire signature surdimensionné),
  contenu et palette Cendrelune. La couleur d'équipe passe à de **grandes
  masses** (écharpe, doublure, fanion, rebord de bouclier) au lieu d'un
  cordon de 3-4 px : ça remplace la règle de `cendrelune_unites.md` §2.
  Roster v3 généré et choisi (Aurel 1, Guerrier 3, Archer 0, Éclaireur 3,
  Cavalier 0, Apothicaire 0, Alchimiste 3, Fossoyeur 1).
  Archive et planches : `autogen\units_v3\`, script `gen_chibi.py`.
- **18/10/2026** : roster v3 installé dans `units_hd/`, avec un idle par classe
  (`gen_idle_v3.py`, `install_v3.py`). Aurel lit son registre, le Guerrier
  tient sa garde, l'Archer reste en allonge, l'Éclaireur balaie l'horizon à
  la longue-vue, le cheval du Cavalier piaffe sous le fanion, l'Apothicaire
  fait tourner sa fiole, la mèche de l'Alchimiste fume et le Fossoyeur reste
  immobile. La `last_frame` est la source elle-même, donc la boucle revient à
  la pose de départ (source + 3 frames). Les sprites v2 sont archivés dans
  `autogen\units_v2\installed_v2_backup\`.
- **18/10/2026** : la boucle d'idle est remplacée par une **respiration
  procédurale** (étirement vertical de 2 % ancré aux pieds, rythme tiré au
  hasard pour chaque unité, `Unit.gestures`) et un **geste unique** par unité.
  Le geste dure 8 frames, se joue à 0,11 s par frame et se déclenche toutes
  les 6 à 15 s, au hasard. Il part de la pose de repos et y revient
  (`gen_geste.py`, `install_geste.py`, fichiers `<type>_geste_N.png`). Aurel
  a désormais pour pose de repos le registre fermé sous le bras
  (`units_v3\aurel_ferme\`, candidat 2). Son geste « ouvre, lit, referme »
  a échoué : avec les deux extrémités ancrées sur le repos, le modèle refuse
  les grands mouvements et se contente de baisser la tête.
  Correction (`gen_geste_aller.py`, `install_geste_aller.py`) : on ne génère
  que l'**aller** du geste, et le jeu le rejoue à l'envers pour revenir au
  repos. Pour Aurel, c'est une interpolation entre deux poses connues
  (registre fermé, puis registre ouvert de l'Aurel v3) avec une pause de
  lecture au milieu. Pour l'Archer (il baisse l'arc puis rebande) et
  l'Alchimiste (il lance le flacon puis le rattrape), on donne seulement la
  pose de départ. C'est **la bonne méthode pour les grands gestes**.
  L'aperçu ajoute l'Apothicaire, l'Alchimiste et le Fossoyeur aux armées
  d'Aubry-le-Bas pour qu'on voie tout le roster ; le tableau lui-même n'est
  pas modifié.
- **18/10/2026** : Maxime trouve le geste d'Aurel parfait. On retravaille
  les autres unités **une par une** sur ce modèle en trois temps : aller,
  pause, retour (`gen_geste3.py`, `install_geste3.py`). Premier fait, le
  **Guerrier** : il plante son bouclier au sol, s'appuie dessus, s'essuie le
  front en soufflant, puis reprend sa garde (22 frames, environ 4
  générations). Dans la pause, le modèle a dessiné une deuxième lame dans la
  main qui essuie le front. On l'a recolorée en cuir de gant, ce qui donne
  l'avant-bras (`retouche_guerrier_pause.py`, frames brutes conservées).
  Maxime n'est pas convaincu. **Version 2** en plusieurs étapes enchaînées :
  il pose le bouclier, plante son épée verticalement dans le sol, souffle,
  puis reprend ses armes (38 frames, environ 4 s). Le modèle n'a pas compris
  « rengainer » : il relevait l'épée au lieu de la ranger (essai archivé).
  Planter l'épée, un geste vers le bas, a marché du premier coup. La pause
  ne fait pas le geste d'essuyer le front : il souffle, les yeux fermés, et
  secoue sa main. L'installation comble les petits trous transparents (le
  modèle trouait l'umbo du bouclier). La v1 est archivée dans
  `geste3_v1_appui\`. Maxime laisse le Guerrier de côté pour le moment.
- **18/10/2026** : **Archer**, « sentir le vent ». Il se redresse et baisse
  l'arc jusqu'au flanc, humecte son index, lève le bras tout en haut, tourne
  la tête ; une rafale fait voler sa cape, il hoche la tête puis rebande
  (30 frames, environ 3,3 s, environ 4 générations). Maxime trouvait la
  scène trop discrète et demandait un mouvement **marqué**. Pour ça : un
  aller plus ample, une pause de 12 frames et un temps d'arrêt (frames
  doublées, `PAUSE_HOLD`) sur le bras levé. Maxime adore.
- **18/10/2026** : **Cavalier**, « le cheval broute ». Le cheval baisse la
  tête jusqu'à l'herbe, la lance du cavalier bascule sur son épaule. Le
  cheval broute et fouette de la queue, le cavalier se penche pour lui
  tapoter l'encolure, puis tout revient (31 frames, environ 4 générations).
  Le comblement des trous de l'installation est désormais réservé au
  Guerrier : sur le cheval, il bouchait les vrais vides entre les jambes et
  les rênes. Maxime valide.
- **18/10/2026** : **Éclaireur**, « le moineau ». Un moineau arrive, tourne
  au-dessus de sa tête et se pose au bout de sa longue-vue. L'Éclaireur le
  regarde en souriant pendant que l'oiseau sautille, puis le moineau
  s'envole : c'est son arrivée rejouée à l'envers (31 frames, environ 4
  générations). Faire apparaître un élément nouveau a marché du premier
  coup. En revanche, le recalage sur les couleurs du repos, en RVB brut,
  rendait l'oiseau couleur chair. Pour cette unité, on recale sur toute la
  palette Cendrelune, et dans l'espace Lab (`PALETTE_ETENDUE`). Maxime
  valide.
- **19/10/2026** : **Apothicaire**, « la cueillette ». C'est un vrai cycle,
  sans aller-retour à l'envers, sinon elle « replanterait » la fleur. Elle
  range sa fiole dans sa sacoche, s'accroupit, cueille une petite fleur
  blanche, la respire les yeux fermés en souriant, la range, puis ressort
  sa fiole et la relève (34 frames, environ 10 générations). La dernière
  étape (`fin`) se termine sur la pose de repos. Premier essai raté : avec
  la fiole en main, elle ne cueillait rien, d'où l'étape qui libère d'abord
  la main. Le modèle laissait une touffe d'herbe au sol, effacée à
  l'installation (`ILOTS`, îlots détachés de 150 px au plus).
- **19/10/2026** : **Alchimiste**, « la fiole explose », d'après une idée de
  Maxime. Sa fiole lui explose dans la main (éclair, bouffée de fumée), il
  chasse la fumée d'une main devant son visage, puis prend une fiole neuve
  à sa bandoulière et la relève (27 frames, environ 14 générations, essais
  compris). Le modèle a refusé trois fois de lui faire **battre des bras** :
  avec deux formulations, puis avec `enhance_prompt`. La solution de Maxime,
  une seule main qui fait un va-et-vient à hauteur du visage, a marché.
  Retenu : sur ce personnage massif, pas de grands gestes des deux bras.
  Sous l'éclair, le foulard d'équipe tombait sur un des bleus de la palette :
  la palette étendue exclut désormais les bleus, l'indigo d'équipe reste le
  seul.
