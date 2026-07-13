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
3. **Compétences actives de héros** — une action spéciale avec cooldown en tours
   (ex. soin de zone, boule de feu, cri de guerre buffant les alliés adjacents).
4. **Villages capturables** — +or par tour et soin de l'unité qui s'y trouve.
   Enjeux territoriaux locaux sans économie profonde ni multiples types de bâtiments.
5. **Recrutement autour du héros** avec l'or (pas d'usines à la AW) — un seul
   point de production mobile, UI simple, renforce le dilemme exposition/sécurité
   du héros.
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

## Feuille de route

Chaque phase doit laisser un jeu jouable.

- [x] **Phase 1** — cœur tactique : carte iso, terrains, déplacement (Dijkstra), combat, IA simple
- [x] **Phase 2** — types d'unités (Infanterie/Char/Archer), portée, visuels SVG, idle 2 frames
- [x] **Phase 3** — conditions de victoire/défaite : élimination + écran de fin, compteur de tours
- [ ] **Phase 4** — héros : unité unique par camp, victoire par assassinat, XP, +stats par niveau
- [ ] **Phase 5** — économie : villages capturables, or, recrutement autour du héros
- [ ] **Phase 6** — compétences de héros (une active par niveau, choix entre deux)
- [ ] **Phase 7** — creeps neutres et récompenses
- [ ] **Phase 8** — vétérance des unités
- [ ] **Phase 9+** — scénarios, campagne, recall des vétérans, boss fights en climax de scénario

## État technique actuel (rappel)

Godot 4.7, GDScript, rendu GL Compatibility. Carte 12×10 isométrique, 5 terrains
(coûts de mouvement par type d'unité, bonus de défense), 3 types d'unités avec
portée et riposte conditionnelle, IA qui garde ses distances avec les unités à
portée, sprites SVG maison teintés par équipe, animation d'idle 2 frames.
Victoire/défaite par élimination avec écran de fin et compteur de tours.
Prochaine brique : le héros (phase 4).
