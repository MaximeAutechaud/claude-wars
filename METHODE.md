# Claude Wars — Méthode de travail

> Principes d'organisation du développement. À relire au début de chaque feature.

## Principe central : la tranche verticale

On ne travaille jamais par discipline (« d'abord tout le code, ensuite tous les
graphismes ») : on livre des **tranches verticales** — une fonctionnalité complète
qui traverse toutes les disciplines nécessaires et laisse **un jeu jouable**.

Le fun ne se prédit pas sur papier, il se découvre en jouant : il faut pouvoir
jouer tôt, souvent, et après chaque tranche.

## La checklist par feature

Pour chaque phase de la roadmap ([DESIGN.md](DESIGN.md)), dérouler dans l'ordre :

1. **Règles** — fixer le comportement exact sur papier avant de coder
   (un paragraphe dans DESIGN.md ou une discussion rapide). Le user valide.
2. **Système** — le code pur de la mécanique, avec art placeholder si besoin
   (le « programmer art » est assumé). Testable en headless.
3. **Feedback UI** — le joueur voit-il ce qui se passe ? Surlignages, barres,
   labels, écrans. Souvent 40 % du travail réel d'un jeu de stratégie.
4. **IA** — l'ennemi sait-il jouer avec la nouvelle mécanique ? Une mécanique
   que l'IA ignore est à moitié livrée.
5. **Art + juice** — sprites propres, petite animation, effet. En dernier,
   car c'est ce qui change le plus quand on itère sur les règles.
6. **Playtest + équilibrage** — le user joue, on ajuste les chiffres.
   Tâche récurrente, jamais « finie ».

Chaque ligne est une tâche de taille raisonnable pour une session.

## Règles d'or

- **Séparer système et contenu.** Le système, c'est « le jeu sait charger une
  carte » ; le contenu, c'est « voici 10 cartes ». Toute donnée de gameplay
  (stats, coûts, cartes, compétences) vit dans une table facile à éditer
  (ex. `Unit.STATS`) — jamais en dur dans la logique. C'est ce qui rendra la
  production de contenu (scénarios, unités) rapide plus tard.
- **Le polish se stratifie, il ne se rattrape pas.** Une petite couche de juice
  à chaque tranche (comme l'idle de la phase 2), pas de grande « phase
  animation » repoussée à la fin : le jeu reste mignon en permanence et on ne
  polit jamais une mécanique qu'on va jeter.
- **Un jeu jouable après chaque tranche.** Si une tranche laisse le jeu cassé,
  elle est trop grosse : la découper.
- **Vérifier en jouant, pas seulement en compilant.** Tests headless pour la
  logique + captures d'écran pour le rendu + playtest humain pour le feel.

## Les disciplines (grille de lecture)

Pour ne rien oublier au moment de découper une feature :

| Discipline | Chez nous |
|---|---|
| Game design | DESIGN.md, règles avant le code |
| Code systèmes | Scripts GDScript, testables headless |
| Code UI / feedback | Surlignages, labels, menus |
| IA | `ai_player.gd` + comportements par mécanique |
| Art 2D | SVG maison dans `assets/` |
| Animation / juice | Idle 2 frames, futurs effets |
| Audio | (rien encore — à stratifier comme le reste) |
| Contenu | Cartes, scénarios, tables de stats |
| Équilibrage / playtest | Le user joue, on ajuste |

## Rôles

- **Le user** : décide des règles, tranche les choix de design, playteste.
- **Claude** : propose le découpage en début de phase, implémente tranche par
  tranche, vérifie (tests + captures), tient DESIGN.md et ce fichier à jour.
