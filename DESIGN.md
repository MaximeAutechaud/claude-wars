# Claude Wars — Document de design

> Trace de la réflexion sur les mécaniques de jeu et conditions de victoire (13 juillet 2026).
> Méthode de travail et checklist par feature : voir [METHODE.md](METHODE.md).

## Vision

**Un « Warcraft 3 au tour par tour », solo avant tout** : des héros qui montent en
niveau et débloquent des compétences, des unités qui scalent, une carte vivante
qu'on contrôle et qu'on farm. Le cœur systémique est emprunté à Battle for
Wesnoth, l'habillage tactique à Advance Wars, et la dimension scénarisée de
Fire Emblem est une évolution possible une fois le cœur en place.

**La partie type visée** (formulée le 14/07/2026) : une campagne qui passe de
**tableau en tableau** — chaque tableau est une carte faite main, couverte de
brouillard de guerre, avec ses camps de bandits prédéfinis. Le joueur explore,
rase les camps pour l'XP et les prisonniers, grossit ses rangs, puis débusque
et affronte l'armée adverse en climax — l'IA ne se rue pas sur lui, elle
attend d'être trouvée (ou de le repérer).

## Analyse des références

| | Advance Wars | Battle for Wesnoth | Fire Emblem |
|---|---|---|---|
| **Nature** | Économie & attrition | Intermédiaire | Puzzle tactique narratif |
| **Unités** | Consommables, produites en continu | Recrutées, gagnent de l'XP | Roster fixe de personnages |
| **Victoire** | Capture du QG / annihilation | Tuer le leader | Objectifs variés par carte |
| **Économie** | Villes → income → usines | Villages (or + soin), recrutement au leader | Aucune (pré-carte) |
| **Attachement** | Nul | Vétérans | Maximal (permadeath) |
| **Coût de dev** | Systémique, rejouable | Systémique, rejouable | Exige du contenu scénarisé à la main |

Enseignements :
- La victoire « tue le leader » (Wesnoth) donne un **point focal** à la partie et
  élimine le *mop-up* interminable d'Advance Wars — la partie se termine au
  moment dramatique.
- Le modèle Fire Emblem ne « tourne » pas tout seul : il demande des scénarios
  dessinés et équilibrés un par un. À garder pour plus tard, pas comme fondation.
- Wesnoth est le meilleur rapport plaisir/coût et absorbe le meilleur des deux autres.

## Décisions

1. **Jeu solo** — l'IA est le contenu principal, pas d'équilibrage compétitif
   symétrique. Le power fantasy (héros + vétérans qui scalent) est une feature ;
   le garde-fou est le rythme (l'ennemi doit scaler aussi).
2. **Héros / commandant par camp** — victoire = tuer le héros adverse, défaite =
   perdre le sien. Contrairement au leader Wesnoth (planqué au donjon), le héros
   est une pièce spectaculaire à la WC3 : XP sur les kills, niveaux, et à chaque
   niveau un choix entre deux améliorations/compétences.
   *(Amendé le 15/07/2026, playtest phase 9 : la victoire vise le **chef**
   adverse — son héros, ou son **boss** si le scénario fait mener l'armée par
   un boss (`UnitsLayer.get_leader`). Le boss-climax n'est pas un camp neutre
   optionnel : c'est l'ennemi à abattre pour finir le tableau.)*
3. **Compétences actives de héros** — cooldown en tours, **un seul sort par
   tour**. Coût par sort : les sorts utilitaires (Bond, Cri de guerre) sont
   **gratuits** (le héros garde son attaque — fantasme d'engage à la WC3),
   les gros sorts (Soin, Boule de feu) **consomment l'action** comme une
   attaque. Décidé le 13/07/2026 : le sentiment gamechanger vient du design
   des sorts, pas de l'empilement d'actions ; tag `free` par sort dans
   `Spells.POOL`, facile à retuner au playtest. **Un seul héros par camp**
   (confirmé) ; d'éventuels héros secondaires de campagne seraient des
   lieutenants sans condition de défaite attachée.
4. **Villages capturables** — +or par tour et soin de l'unité qui s'y trouve.
   Enjeux territoriaux locaux sans économie profonde ni multiples types de bâtiments.
   *(Amendé le 14/07/2026 : le revenu disparaît avec l'économie — voir décision 12 ;
   la capture et le soin restent.)*
5. **Recrutement autour du héros** avec l'or (pas d'usines à la AW) — un seul
   point de production mobile, UI simple, renforce le dilemme exposition/sécurité
   du héros. *(Remplacé le 14/07/2026 par les prisonniers des camps — décision 12.)*
6. **Creeps neutres** — camps d'une équipe neutre passive-agressive (n'attaque
   que si on approche) gardant or/récompenses. Arbitrage farm vs push, donne du
   contenu tactique même avec une IA adverse simple.
7. **Vétérance des unités** — après 2-3 kills : +1 atk, +2 PV max, galon sur le
   sprite. Le frisson Fire Emblem (« pas mon archer vétéran ! ») sans système de
   classes complet ; la permadeath existe déjà de fait. *(Amendé le 18/07/2026
   par la décision 16 : la promotion passe à l'XP partagée et débloque une
   compétence de classe en plus des stats.)*
8. **Combat déterministe conservé** — pas de jets de dés à la Wesnoth/FE :
   lisibilité, sentiment de justice, IA beaucoup plus simple.
9. **Plus tard : scénarios / campagne** — objectifs variés (survivre N tours,
   tenir un pont, s'échapper), héros et vétérans persistants de mission en
   mission (recall à la Wesnoth). La boucle de rétention idéale du format solo.
10. **Boss fights** — en climax de scénario, un ennemi unique très puissant avec
	des spells et mécaniques propres, à la manière d'un boss de roguelike.
	Principes :
	- **Patterns lisibles et télégraphiés** : le combat étant déterministe, on
	  peut afficher à l'avance ce que le boss fera au prochain tour (cases
	  ciblées par son AoE, invocation à venir…) — le combat devient un puzzle
	  d'échecs, pas une loterie de stats.
	- **Phases par paliers de PV** : à 66 % / 33 %, le boss change de
	  comportement ou débloque un nouveau spell.
	- **Mécaniques uniques par boss** : invocation d'adds, zones de danger au
	  sol, bouclier à briser, malus d'aura… une signature par boss plutôt que
	  des gros chiffres.
	- **Des machines à dilemmes, pas des sacs à PV** (référence : Darkest
	  Dungeon). Le boss doit mettre le joueur dans la merde et forcer des
	  choix forts — sacrifier une unité pour en sauver deux, abandonner une
	  position, brûler un cooldown trop tôt. Exemples de mécaniques à dilemme :
	  le boss **agrippe** une unité (la libérer coûte des tours, l'abandonner
	  la tue), il **marque** une cible qu'il exécutera au prochain tour
	  (protéger ou laisser mourir), il punit le regroupement OU la dispersion.
	  La victoire doit avoir un **coût** : l'état de l'armée en sortant du boss
	  fait partie de l'histoire. Prérequis : la vétérance (phase 8) — le
	  sacrifice ne fait mal que si on tient à ses unités.
	- Techniquement, un boss réutilise les briques existantes : le système de
	  compétences des héros (phase 6) + l'équipe neutre des creeps (phase 7).
	  C'est du contenu premium par-dessus les systèmes, pas un système à part.

11. **Grille hexagonale** (décision du 13/07/2026, priorité gameplay > design).
	Hexagones flat-top, colonnes décalées (odd-q), à la Wesnoth. Raisons :
	6 adjacences → l'encerclement devient une vraie tactique, distances rondes
	(la portée 2 de l'archer couvre un disque de 18 cases), AoE naturelles pour
	les futurs sorts de héros et zones de boss. Le jeu visé est punitif donc
	stratégique : les bons joueurs doivent être récompensés par le
	positionnement. Coût assumé : abandon de la perspective isométrique pour
	une vue à plat.
12. **Suppression de l'économie** (décision du 14/07/2026, après playtest de la
	phase 7). Une économie ouverte récompense le turtling et rend la production
	d'unités potentiellement infinie ; la rustine classique (limite de tours à
	la Wesnoth) est refusée — désagréable en tant que joueur, et externe au jeu.
	L'équité économique n'a de valeur qu'en PvP ; en solo scénarisé, l'IA reçoit
	son **armée complète au départ** (l'équilibrage se fait par le contenu du
	scénario) et ne recrute pas. Conséquences :
	- **Plus d'or nulle part** : revenu des villages, coûts d'unités, bounty des
	  creeps, bouton Recruter — tout est retiré.
	- **Les renforts passent par les camps de bandits** : chaque camp garde un
	  **prisonnier prédéfini par le scénario et visible sur la carte** (icône en
	  cage). Vaincre le camp le fait rallier le camp du dernier coup porté ; il
	  apparaît sur le camp, épuisé le tour même. Prédéfini + visible = dilemme
	  informé (« il nous faut un char, le gros camp en garde un ») et non une
	  loterie ; même carte, mêmes chances pour tous les joueurs. Si un camp
	  frustre au playtest, il pourra offrir un choix entre 2 prisonniers (une
	  ligne de données).
	- **Camp vaincu = camp de repos** : allié au vainqueur, il soigne +3/tour
	  comme un village.
	- Les renforts sont donc finis et payés en risque (PV, position, tempo),
	  pas en attente — cohérent avec la victoire par assassinat et la vétérance
	  à venir (unités rares et irremplaçables).
13. **Structure de campagne par tableaux** (14/07/2026). Le jeu est une suite
	de tableaux faits main : carte dessinée, camps et prisonniers prédéfinis,
	armée adverse placée à la création. Boucle par tableau : explorer (sous
	brouillard) → farmer les camps → grossir/monter le héros → localiser
	l'armée adverse → assaut final. Conséquences :
	- **Le tableau est l'unité de contenu** → il faut un format de scénario en
	  données (terrain, villages, camps, armées, positions des héros) à la
	  place du codé-en-dur actuel — règle « séparer système et contenu ».
	- **Vigilance playtest** : IA attentiste + zéro pression temporelle =
	  l'optimal sera toujours « raser 100 % des camps puis engager ». C'est le
	  power fantasy assumé, mais pour éviter que tous les tableaux se jouent
	  pareil, la pression viendra du design de scénario (camps trop durs pour
	  l'armée actuelle, patrouilles dans le brouillard, objectifs secondaires,
	  événements) — jamais d'une limite de tours globale.
14. **Outils de survie** (16/07/2026). Le jeu est punitif et la mort d'une
	unité coûte cher (vétérance, renforts finis) : le joueur doit pouvoir
	*gérer* la survivabilité. Le levier n'est pas le soin (l'attrition entre
	les combats est déjà résolue par les villages/camps de repos et l'absence
	de pression temporelle — les morts arrivent en combat, en 1-2 tours de
	burst) mais la prévention et le contrôle du focus. Trois mécaniques :
	- **Prévision de dégâts** : au survol d'une cible attaquable, l'issue
	  exacte du combat est affichée (« Attaque : −4 / Riposte : −2 », fatalité
	  signalée). Le combat étant déterministe (décision 8), chaque mort
	  devient une erreur de lecture *évitable* — condition du « punitif mais
	  juste ». Calculs partagés avec `do_combat` (`preview_combat`).
	- **Posture Défendre** : remplace l'action du tour, +2 déf jusqu'à la
	  prochaine action de l'unité (bouger/attaquer/sort la casse, riposter
	  non). Donne un sens au tour « je tiens la ligne » ; l'IA non alertée se
	  met en garde (garnison), bouclier dessiné sur le sprite.
	- **Zone de contrôle (ZoC)** façon Wesnoth : entrer sur une case voisine
	  d'un ennemi (visible) stoppe net le mouvement ; les cases occupées par
	  un ennemi sont infranchissables. Deux unités contrôlent un couloir →
	  le body-block devient une vraie ligne de front, une retraite se couvre.
	  Règle symétrique (l'IA et les creeps la subissent), le Bond l'ignore
	  (mais atterrir en ZoC coupe les PM restants), et les ennemis cachés
	  dans le brouillard n'exercent pas de ZoC pour le joueur (pas de fuite
	  d'information). Si l'arrêt net s'avère trop rigide au playtest,
	  l'alternative douce est le surcoût de PM à la Civilization.

15. **Sauvegarde et écran d'accueil** (16/07/2026, première brique de la
	phase 11 — la campagne exigera de poser le jeu et de le reprendre).
	- **Une sauvegarde manuelle unique** (`user://save.json`, JSON pur —
	  mêmes contraintes que le format de scénario : données portables, zéro
	  référence de classe). Bouton « Sauvegarder » en jeu, actif pendant le
	  tour du joueur uniquement (l'état d'un tour IA/neutre en cours n'est
	  pas capturable proprement). Elle capture tout : unités des deux camps
	  (PV, PM, XP, sorts, cooldowns, vétérance, posture, état de boss),
	  camps de bandits (réveil, propriétaire, membres vivants), villages,
	  brouillard exploré, compteur de tours, alerte IA.
	- **Écran d'accueil** (`scenes/title.tscn`, scène principale du projet) :
	  Continuer (grisé sans sauvegarde, affiche le tour), Nouvelle partie,
	  Quitter. Boutons « Menu principal » en jeu et sur l'écran de fin.
	- Chargement par relais : l'accueil dépose la sauvegarde lue dans
	  `SaveGame.pending`, main._ready l'applique à la place du spawn du
	  scénario (`SaveGame.apply` purge puis restaure).
	- Pas d'autosave ni d'emplacements multiples pour l'instant — à revoir
	  avec la campagne (phase 11) si le besoin apparaît au playtest.

16. **Roster d'unités : un verbe par classe, vétérance à compétences**
	(18/07/2026). Sans économie, le raisonnement Advance Wars « je produis le
	contre » n'existe pas : une unité ne se définit pas contre une autre mais
	par ce qu'elle permet de faire que les autres ne font pas — un **verbe
	unique**, de préférence géométrique (le combat déterministe + ZoC +
	Défendre récompense les identités de position, pas les lignes de stats).
	Les prisonniers des camps sont l'arbre de tech : un type rare est une
	récompense de scénario et un jalon de progression de campagne.
	- **Chacun son thème** (refonte des stats) : le Guerrier prend les PV et
	  la riposte — c'est lui qui encaisse —, le Cavalier rend des PV et garde
	  les PM et le burst, l'Archer garde la portée. Il était incohérent que
	  le Cavalier cumule plus de PV que le Guerrier *et* la mobilité.
	- **Le roster** (verbe de base toujours actif → compétence débloquée à la
	  vétérance) :
	  - **Guerrier** (14 PV, 3 PM, atk 3, riposte 3) — le mur : forêt à
		coût 1, seul à l'aise en montagne, ZoC + Défendre. Atk à réduire
		(3 → 2) si le mur s'avère trop rentable au playtest. Vétéran :
		**Provocation** — les ennemis adjacents sont forcés de le cibler.
	  - **Archer** (8 PV, 3 PM, atk 3, portée 2) — l'usure gratuite : frappe
		à 2 sans riposte. Vétéran : **Flèche d'entrave** — la cible touchée
		tombe à 1 PM au prochain tour (stoppe une charge, ralentit un boss).
	  - **Cavalier** (11 PV, 5 PM, atk 4, riposte 2) — la punition :
		**Charge** (+2 atk s'il a parcouru ≥ 3 cases avant d'attaquer),
		forêt à coût 2 — la charge veut de la plaine ; il ne tient pas la
		ligne, il traverse la carte pour exécuter ce qui s'isole. Vétéran :
		**Percée** — après un kill, il peut dépenser ses PM restants.
	  - **Éclaireur** *(nouveau — 7 PV, 4 PM, atk 2, vision 5)* —
		l'information : tout terrain à coût 1 (sauf fleuve), et **Endurci**
		(amendement du 18/07) : se soigne de 2 PV à chaque début de tour —
		il survit en territoire hostile, loin des villages et de
		l'Apothicaire, car sa seule valeur est d'être en vie. Moins bien
		qu'un village (+3), sans effet en combat (les dégâts vont de 3
		à 6) : du tempo d'exploration, pas de la tank ; pas de cumul avec
		le soin de village (prendre le meilleur des deux). Trouve les
		camps, évite les chain-pulls, capture loin, sert d'appât. Vétéran :
		**Infiltration** — ne réveille plus les camps de creeps.
	  - **Apothicaire** *(nouveau — 8 PV, 3 PM, atk 1)* — la seconde
		chance : soigne 4 PV à un adjacent (l'action du tour). C'est du
		contrôle de focus **en combat** (décision 14), pas un doublon du
		soin hors combat des villages. Rare par nature : une par tableau,
		prix du camp le plus dur. Vétéran : **Guérison** — soin 5 et
		dissipe les malédictions (marques de boss et états à venir).
	  - **Mage des braises** *(nouveau — 7 PV, 2 PM, atk 4, portée 2-3,
		portée minimale 2 : nul au corps à corps, injouable sans escorte)* —
		le brise-tortue : ses dégâts **ignorent les bonus de défense**
		(terrain + posture). L'anti-retranchement que nos propres mécaniques
		défensives rendent nécessaire, et le miroir des mécaniques de boss
		côté joueur. Vétéran : **Terre brûlée** — son attaque enflamme la
		case de la cible (2 dégâts à quiconque y termine son tour).
	  - **Écartés** : le Piquier anti-cavalerie (contre pur, sans objet si
		le scénario n'aligne pas de cavalerie en face) et le porte-étendard
		à aura (doublon du Cri de guerre du héros).
	- **XP de vétérance partagée** (remplace le compteur de last-hits — une
	  Apothicaire ou un Éclaireur ne tuent jamais, mais ne sont pas censés
	  mourir) : chaque kill donne **+1 XP à toutes les unités alliées à
	  ≤ 3 hex de la victime** (rayon à retuner, 4 si trop lent), **+1 bonus
	  au tueur** (2 au total) ; **finir un tableau vivant donne +1 XP**
	  (remplace la « récompense de survie » du 14/07). Promotion à **5 XP** :
	  un pur tueur promeut à son 3e kill, comme avant ; les soutiens
	  promeuvent en accompagnant les combats et en survivant. La promotion
	  conserve le bonus de stats (+1 atk, +2 PV max) et débloque la
	  compétence de classe — compétence fixe, pas de choix entre deux : le
	  choix au level-up reste la signature du héros. L'XP du héros (niveaux,
	  gains d'équipe) ne change pas.
	- Garde-fou playtest : si les compétences actives (Provocation, Entrave)
	  alourdissent la manipulation, les passer en passif automatique — le
	  déterminisme le permet sans rien casser.

## Feuille de route

Chaque phase doit laisser un jeu jouable.

- [x] **Phase 1** — cœur tactique : carte iso, terrains, déplacement (Dijkstra), combat, IA simple
- [x] **Phase 2** — types d'unités (Infanterie/Char/Archer), portée, visuels SVG, idle 2 frames
- [x] **Phase 3** — conditions de victoire/défaite : élimination + écran de fin, compteur de tours
- [x] **Phase 4** — héros : unité unique par camp, victoire par assassinat, XP
	  (+2 kill du héros / +1 kill allié, paliers 2/5/9/14, cap niv. 5,
	  +4 PV max +1 atk +1 riposte par niveau). IA : cible le héros adverse en
	  priorité ; son héros joue en commandant — il agit après son armée, escorte
	  sans venir au contact, ne frappe que pour achever une cible, replie sous
	  40 % de PV, et ne se bat en première ligne que s'il est seul
- [x] **Phase 5** — économie : villages à revenu, or, recrutement au héros.
	  *(Retirée le 14/07/2026 par la décision 12 — il reste les 5 villages
	  capturables avec soin +3, sans revenu.)*
- [x] **Phase 6** — compétences de héros (avancée avant la phase 5) : pool de
	  4 sorts (Soin, Boule de feu avec friendly fire, Bond, Cri de guerre),
	  choix entre 2 sorts à chaque level-up, 1 sort/tour, Bond et Cri gratuits,
	  Soin et Boule de feu = l'action du tour (possible après déplacement),
	  cooldowns en tours ; IA : auto-soin et boule de feu sur groupe sans allié
- [x] **Phase 7** — creeps neutres (équipe 2, or) : 3 camps — deux petits
	  (Infanterie + Archer) sur les flancs, un gros au centre (chef Char +
	  Infanterie + Archer) qui garde le village central. Passif-agressif :
	  un camp dort tant qu'aucune unité ne finit son tour à ≤ 2 cases (ou
	  qu'un creep n'est pas blessé, même à distance), puis attaque en restant
	  leashé à ≤ 3 cases de son centre ; il se rendort une fois rentré au
	  camp. Tour neutre après celui de l'IA (Joueur → IA → Creeps). XP de
	  kill normale sur les creeps. Ignorés par les conditions de victoire,
	  ne capturent pas les villages. *(Le bounty en or de la première version
	  a été remplacé le jour même par les prisonniers — phase 7bis.)*
- [x] **Phase 7bis** — les camps remplacent l'économie (décision 12) :
	  suppression totale de l'or, chaque camp garde un prisonnier prédéfini
	  et visible (flanc joueur → Archer, flanc IA → Infanterie, camp central →
	  Char) qui rallie le camp du dernier coup porté et apparaît sur le camp,
	  épuisé. Camp vaincu = camp de repos allié (+3 PV/tour). L'IA ne recrute
	  plus : armée complète au départ, à équilibrer par scénario
- [x] **Phase 8** — vétérance : à 3 kills, +1 atk et +2 PV max (remplis à la
	  promotion), galon doré sur le sprite, « vétéran » dans le nom. Tout le
	  monde y a droit sauf les héros (qui ont leurs niveaux d'XP) — creeps
	  inclus : nourrir un camp peut créer un bandit vétéran
- [x] **Phase 9** — format de scénario en données (décision 13) : le tableau
	  vit dans `Scenario.CURRENT` (données pures : terrain en strings — un
	  caractère par case —, villages, armées, camps/prisonniers ; types
	  d'unités en strings via `Unit.TYPE_BY_ID`, portable vers des fichiers
	  plus tard). Premier tableau fait main : **« La Marche du Bord »**,
	  22×16 — un fleuve infranchissable coupé par deux ponts (routes), 8
	  villages, 5 camps (11 creeps — dont un gardant la sortie du pont nord
	  et le camp du gué, le plus dur, qui garde le village central et
	  récompense d'un prisonnier Char *vétéran*), et l'armée ennemie (6
	  unités) menée par le premier boss : **Le Fossoyeur** — c'est lui le
	  chef à abattre pour gagner (décisions 2 et 10). Mécaniques du boss
	  (30 PV, `"type": "boss"` dans le scénario, logique partagée dans
	  `boss.gd`) : **malédiction télégraphiée** un tour sur deux (zone
	  violette affichée pendant tout le tour du joueur, 5 dégâts au tour
	  suivant à tout ce qui y est resté — ses propres troupes comprises) et
	  **phases à 66 %/33 %** où il sacrifie son soldat le plus faible
	  (+6 PV, +1 atk permanent). Tuer un boss rapporte +3 XP bonus au héros.
	  Effectifs resserrés après playtest du 15/07 (« trop d'unités, l'XP
	  monte trop vite ») : joueur 4, IA 6, creeps 11 ; le galon de vétéran a
	  été refait (deux chevrons dorés pleins au-dessus de la tête, lisibles).
	  La grande carte a imposé la **caméra libre** : flèches ou WASD/ZQSD
	  (touches physiques), zoom molette, caméra qui démarre sur le héros.
	  Outils : capture « carte entière révélée »
	  (`tests/screenshot_full.tscn`) pour vérifier un tableau à sa création,
	  test de fumée de la boucle complète (`tests/test_smoke.tscn`)
- [x] **Phase 10** — brouillard de guerre + IA attentiste (avancée avant la 9) :
	  deux couches façon Wesnoth — voile noir (jamais exploré, terrain caché)
	  et brouillard gris (exploré hors de vue : terrain/villages/camps
	  visibles, unités ennemies et creeps cachées). Vision par type dans
	  `Unit.STATS` : Infanterie 3, Archer 3, Char 2, Héros 4 (des unités de
	  reconnaissance dédiées viendront plus tard). Le joueur ne peut cibler
	  que ce qu'il voit. L'IA voit tout (triche assumée) mais **tient sa
	  position** — elle ne fait que se défendre — jusqu'au premier contact
	  (unité joueur à portée de vision d'une unité IA, blessure ou perte) ;
	  l'alerte est alors définitive : « Repérés ! » et l'armée passe à
	  l'attaque
- [x] **Phase 10b** — outils de survie (décision 14) : prévision de dégâts au
	  survol (`UnitsLayer.preview_combat`, mêmes calculs que `do_combat`),
	  posture Défendre (+2 déf jusqu'à la prochaine action, bouton dédié,
	  bouclier sur le sprite, garnison IA en garde avant l'alerte), zone de
	  contrôle façon Wesnoth (`Pathfinder.get_reachable` + ctx de
	  `UnitsLayer.move_context` : arrêt en case voisine d'un ennemi visible,
	  cases ennemies infranchissables, PM coupés à l'entrée — Bond compris)
- [x] **Phase 11a** — sauvegarde/chargement + écran d'accueil (décision 15) :
	  `scripts/save_game.gd` (capture/apply JSON de l'état complet),
	  `scenes/title.tscn` (Continuer / Nouvelle partie / Quitter, nouvelle
	  scène principale), boutons Sauvegarder et Menu principal en jeu,
	  test headless `tests/test_save.tscn` (aller-retour disque complet)
- [ ] **Phase 11+** — campagne : enchaînement des tableaux, persistance
	  héros/vétérans (recall à la Wesnoth), boss fights en climax de scénario.
	  L'XP de survie en fin de tableau (+1 XP aux survivants) est définie par
	  la décision 16
- [x] **Phase 12a** — le roster en jeu (décision 16, 18/07/2026) : refonte
	  des stats (Guerrier 14 PV/riposte 3, Cavalier 11 PV/atk 4 + Charge),
	  les trois nouveaux types avec leurs verbes de base (Éclaireur Endurci,
	  Apothicaire soin +4 adjacent, Mage portée 2-3/perce-défense) et leurs
	  sprites chibi ; intégrés au scénario (Éclaireur dans l'armée de départ,
	  Mage prisonnier du pont nord, Apothicaire prix du camp du gué). Carte
	  de test « Terrain d'essai » depuis l'accueil (`Scenario.active`,
	  roster complet des deux côtés, sans brouillard, sauvegarde coupée).
	  **Animations de déplacement** validées au playtest : locomotion par
	  bonds sur le chemin réel du Dijkstra (arc en cloche, squash/stretch,
	  inclinaison, poussière à l'arrivée, flip directionnel, idle accéléré),
	  logique instantanée / sprite qui rattrape (`Unit.walk_along`,
	  `wait_walks` pour séquencer IA et creeps)
- [ ] **Phase 12b** — XP de vétérance partagée (rayon 3, +1 au tueur, +1 de
	  survie en fin de tableau, promotion à 5 XP) et les six compétences de
	  vétéran (décision 16)

## État technique actuel (rappel)

Godot 4.7, GDScript, rendu GL Compatibility. Carte **hexagonale**
(flat-top, odd-q — toute la géométrie passe par `Pathfinder.get_neighbors` et
`Pathfinder.distance`) chargée depuis `Scenario.CURRENT` (taille libre ;
tableau actuel : « La Marche du Bord », 22×16), 5 terrains
(coûts de mouvement par type d'unité, bonus de défense), 3 types d'unités avec
portée et riposte conditionnelle (+ le type `BOSS` pour les boss de camp), IA
qui garde ses distances avec les unités à
portée, sprites SVG maison teintés par équipe, animation d'idle 2 frames.
Caméra libre (flèches/WASD physique, zoom molette, clamp aux limites de la
carte). Fiche d'unité (`UnitPanel` dans main.tscn, `main._show_unit_panel`) :
portrait teinté équipe, nom, PV, stats (attaque/riposte/portée/PM/vision/
défense totale avec garde), grade de vétérance (ou phase de boss), XP du
héros — affichée à la sélection et au clic d'inspection sur toute unité
visible (le brouillard bloque l'inspection). Survie (décision 14) :
`preview_combat`/`attack_damage`/`counter_damage`/`defense_of` dans
UnitsLayer (partagés combat/prévision), `Unit.defending` +
`Unit.DEFEND_BONUS`, ZoC via `move_context` (zoc/blocked) passée à
`Pathfinder.get_reachable` par tous les appelants (joueur, IA, creeps) ;
`move_unit` et le Bond coupent les PM à l'arrivée en ZoC. Tests :
`tests/test_survival.tscn`. Boss (`boss.gd`, statique, état sur l'unité : `doom_cells` /
`doom_armed` / `boss_phase`) : malédiction télégraphiée (zones dessinées en
violet par `UnitsLayer`), phases avec sacrifice. Un boss peut mener une armée
(chef à abattre, `get_leader`) ou habiter un camp neutre ; prisonnier vétéran
via `prize_veteran`.
Héros par camp (20 PV, XP partagée façon WC3, niveaux avec pips et barre d'XP) ;
victoire par assassinat du héros adverse (l'élimination totale reste une
condition secondaire), écran de fin, compteur de tours. Sorts de héros
(`Spells.POOL`), villages capturables à soin seul (`Villages`), pas d'or ni
de recrutement libre. Creeps neutres (`Creeps`, camps et prisonniers dans
`Creeps.CAMPS`, tour neutre après l'IA) : vaincre un camp libère son
prisonnier (détection via le signal `UnitsLayer.unit_killed`) et le camp
devient un point de repos allié.
Vétérance à 3 kills (compteur `Unit.kills` incrémenté dans
`UnitsLayer._on_kill`, constantes `VETERAN_*` dans unit.gd).
Brouillard de guerre (`Fog`, nœud au-dessus de UnitsLayer) : `explored` /
`visible_now`, recompute hooké dans spawn/move/kill/cast, unités non joueur
masquées via `visible`, villages et camps dessinés seulement si explorés ;
IA attentiste dans main.gd (`ai_alerted`, `AIPlayer.detects_player`).
Tests headless dans `tests/` (ex. `godot --headless --path . res://tests/test_phase7.tscn` ;
`test_phase9` couvre le scénario et le boss, `test_smoke` joue deux tours
complets ; `screenshot_full.tscn` capture la carte entière révélée).
Vigilance connue : l'IA alertée navigue à la distance hexagonale, pas au
chemin — face au fleuve, ses unités peuvent longer la rive au lieu de
rejoindre un pont (peu visible tant que le climax se joue près de sa base,
à traiter si un tableau l'exige).
Sauvegarde/chargement (décision 15) : `SaveGame` (statique) capture l'état
complet en JSON (`user://save.json`), l'écran d'accueil (`title.tscn`, scène
principale) le recharge via `SaveGame.pending` appliqué par main._ready.
Prochaine brique : la campagne (phase 11 : enchaînement de tableaux,
persistance des héros/vétérans entre tableaux) ; équilibrage en attente —
réduire les prisonniers des camps (chaque perte doit faire mal, distiller
les unités anonymes).

**Outil narratif — boîte de dialogue (premier jet, non rattaché à une phase).**
Système générique façon Phoenix Wright (`scripts/dialogue_box.gd` +
`scenes/dialogue_box.tscn`) : portrait qui « parle » (bump vertical pendant
la révélation du texte), texte en typewriter avec blip sonore **procédural**
(`AudioStreamWAV` synthétisé en mémoire, pitché par locuteur — aucun asset
audio requis), boîte de nom, pause plus longue sur la ponctuation, flèche
« continuer », avance au clic/Entrée/Espace/Z. `DialogueBox.play(lines)`
prend un script de dialogue en données (`[{"speaker", "text", "color"?}]`),
zéro contenu narratif en dur dans le système. Portraits en silhouette
générée (`dialogue_portrait.gd`, `_draw`) : placeholder assumé en attendant
un vrai artwork par personnage. Démo jouable : bouton « Dialogue (test) »
sur l'écran d'accueil → `scenes/dialogue_demo.tscn` (texte et noms de
personnages provisoires). À intégrer plus tard aux scènes de campagne
(cutscenes d'ouverture d'acte, dialogues de boss) une fois les personnages
et leur écriture stabilisés côté `cendrelune_compte_rendu.md`.
