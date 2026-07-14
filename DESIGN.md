# Claude Wars — Document de design

> Trace de la réflexion sur les mécaniques de jeu et conditions de victoire (13 juillet 2026).
> Méthode de travail et checklist par feature : voir [METHODE.md](METHODE.md).

## Vision

**Un « Warcraft 3 au tour par tour », solo avant tout** : des héros qui montent en
niveau et débloquent des compétences, des unités qui scalent, une carte vivante
qu'on contrôle et qu'on farm. Le cœur systémique est emprunté à Battle for
Wesnoth, l'habillage tactique à Advance Wars, et la dimension scénarisée de
Fire Emblem est une évolution possible une fois le cœur en place.

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
   classes complet ; la permadeath existe déjà de fait.
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
- [ ] **Phase 8** — vétérance des unités
- [ ] **Phase 9+** — scénarios, campagne, recall des vétérans, boss fights en
	  climax de scénario. Aussi (souhaits du 14/07/2026) : **cartes plus
	  grandes** et **brouillard de guerre** — l'IA n'irait plus en frontal dès
	  le tour 1 mais attendrait de repérer l'attaque du joueur, ce qui donne
	  du sens au scouting et aux camps éloignés

## État technique actuel (rappel)

Godot 4.7, GDScript, rendu GL Compatibility. Carte 12×10 **hexagonale**
(flat-top, odd-q — toute la géométrie passe par `Pathfinder.get_neighbors` et
`Pathfinder.distance`), 5 terrains
(coûts de mouvement par type d'unité, bonus de défense), 3 types d'unités avec
portée et riposte conditionnelle, IA qui garde ses distances avec les unités à
portée, sprites SVG maison teintés par équipe, animation d'idle 2 frames.
Héros par camp (20 PV, XP partagée façon WC3, niveaux avec pips et barre d'XP) ;
victoire par assassinat du héros adverse (l'élimination totale reste une
condition secondaire), écran de fin, compteur de tours. Sorts de héros
(`Spells.POOL`), villages capturables à soin seul (`Villages`), pas d'or ni
de recrutement libre. Creeps neutres (`Creeps`, camps et prisonniers dans
`Creeps.CAMPS`, tour neutre après l'IA) : vaincre un camp libère son
prisonnier (détection via le signal `UnitsLayer.unit_killed`) et le camp
devient un point de repos allié.
Tests headless dans `tests/` (ex. `godot --headless --path . res://tests/test_phase7.tscn`).
Prochaine brique : vétérance des unités (phase 8).
