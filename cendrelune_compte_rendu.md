# CENDRELUNE — Compte rendu de conception
*Document de suivi, mis à jour au fil des échanges*

---

## 1. CONCEPT GÉNÉRAL

Jeu tactique 2D isométrique sur grille hexagonale, style Battle for Wesnoth. Solo, campagne à fort scénario structurée en tableaux. Unités rares, gagnent de l'XP pour créer de l'attachement, mais permadeath dur façon Darkest Dungeon. Un héros par armée avec compétences spéciales façon Warcraft 3, mais au tour par tour. Ambition assumée : un "Warcraft 4" non officiel, mais avec une identité propre distincte de l'heroic fantasy classique.

---

## 2. UNIVERS & MYTHOLOGIE

### Échelle de la menace
Décision prise : **une seule nation**, pas le monde entier. Nom de travail : **Cendrelune** (ou "Marchpell" en variante). Ancien territoire vaste, aujourd'hui réduit à une fraction de sa taille historique à cause de l'Effacement. Le reste du monde existe, va globalement bien, et est indifférent ou ignorant du problème.

### Le phénomène central : l'Effacement
Un cataclysme qui grignote le territoire — des régions entières disparaissent avec leurs habitants. Quiconque n'est pas "consigné" avant la disparition d'une zone est oublié de tous, comme s'il n'avait jamais existé. Ce n'est **pas** un désastre naturel : c'est un sceau ancien qui cède, lui-même lié à un cycle bien plus vaste (voir section 6).

### Registre / temporalité
Décision prise : rejet du heroic fantasy flamboyant façon Warcraft (expansion, magie omniprésente, héros charismatiques). Registre choisi : **"automne d'un âge d'or"**, plus proche de Dark Souls (la flamme qui s'éteint) que de tout empire en expansion. Datation suggérée par rapport à l'Effacement lui-même ("300 ans depuis la Première Rupture") plutôt qu'un calendrier fantasy classique.

### Gouvernement
Conseil ou monarchie dont la légitimité s'effrite en même temps que le territoire — sièges vacants ou occupés par des gens dont l'origine est floue (écho thématique). Aristocratie en déni face à l'Ordre des Chroniqueurs-Soldats qui vit la catastrophe au quotidien. Le déni du pouvoir ne porte pas sur les faits (les disparitions sont connues et reconnues comme réelles) mais sur leur **échelle** — chaque disparition est vue comme un incident isolé (malédiction locale, accident), personne sauf le héros ne relie les points.

### Guerres
Décision prise : pas de guerres externes classiques entre royaumes. Le seul vrai conflit est interne et idéologique, décliné sur trois échelles temporelles : les Attentifs contre leur propre effondrement (passé lointain), l'Ordre contre le Chœur Silencieux (présent), et bientôt le héros contre lui-même (futur proche).

### Famines
Liées directement et causalement à l'Effacement : la réduction du territoire réduit les terres agricoles, donc crise alimentaire chronique plutôt qu'épisode ponctuel. Justifie la rareté des unités et donne une raison non-combattante de rejoindre le Chœur (épuisement, pas seulement deuil).

### Qui sait quoi (niveaux de connaissance)
- **Grand public / gouvernement** : connaît l'existence de catastrophes/zones isolées, mais ne perçoit pas le phénomène systémique.
- **Le héros** : seul à voir la continuité et l'urgence, grâce à son héritage Attentif — perçu comme un illuminé pour cette raison précise, pas parce qu'il invente une menace.
- **L'Ordre des Chroniqueurs-Soldats** : institution quasi-monastique vieillissante, tolérée par tradition plutôt que soutenue par conviction d'État — explique sa pauvreté et sa petite taille.
- **Les prisonniers du Chœur (recrutables)** : seuls à avoir une preuve directe et personnelle (ont vu quelqu'un s'effacer en captivité, ou ont failli l'être). Leur loyauté envers le héros peut être une dette existentielle littérale s'il les a sauvés de l'effacement au moment de leur libération.
- **Le Chef du Chœur** : sait depuis longtemps — a vécu la même érosion que le héros, potentiellement en tant que survivant d'un cycle précédent (voir section 6, point ouvert).

---

## 3. PERSONNAGES

### Le Héros — Grand Chroniqueur
Dernier de son ordre. Capacité spéciale : consigner une unité tombée pour préserver son souvenir. Ne se souvient pas de sa propre enfance — a failli être effacé lui-même, sauvé par le dernier Chroniqueur Attentif qui s'est consigné à sa place (origine du pouvoir, en dormance depuis l'enfance, activé par un premier acte de choix conscient).

### Le Fossoyeur — boss Acte I
Commandant du Chœur Silencieux. Sacrifie volontairement ses propres soldats au combat pour gagner des buffs — pas cruel, convaincu. Première démonstration au joueur que le rapport du Chœur à la mort n'est pas de la cruauté gratuite.

### Le Revenant — boss Acte II
Ancien compagnon du joueur, mort non consigné, revenu sous une forme monstrueuse et sans nom (identité effacée). Utilise les compétences dégradées de son ancienne classe. Premier exemple concret que "ne pas consigner" a des conséquences directes.

### Le Gardien du Sceau — boss Acte III
Sentinelle ancienne des Attentifs, pas malveillante — exécute une directive de protection du sceau depuis des siècles. Mécanique : "consigne" de force les unités du joueur qui meurent pendant ce combat (les pétrifie en statues), inversion ironique du pouvoir du héros. Peut aussi être, structurellement, une alarme laissée par les Attentifs pour arrêter les Chroniqueurs qui consignent trop.

### Le Chef du Chœur Silencieux — antagoniste principal, boss Acte IV
Ancien Grand Chroniqueur, prédécesseur du héros. Sait ce qui arrive à qui consigne trop — potentiellement parce qu'il a vu son propre prédécesseur basculer (point encore ouvert, voir section 8). Sa doctrine (effacement total = miséricorde) est présentée sans caricature, comme une conclusion tirée d'un vécu réel. Combat en deux phases : miroir des pouvoirs du héros, puis choix de s'effacer lui-même plutôt que d'être vaincu.

### Les Attentifs — civilisation antérieure
Ont inventé la consignation comme technologie/rituel de survie. Leur usage intensif et prolongé est ce qui a causé leur propre chute — accumulation d'identités effacées, à l'origine de l'Innommable. Ne sont peut-être pas le premier cycle à avoir vécu ce processus (voir section 6).

### L'Innommable — boss final, Acte V
Entité scellée, faite de l'accumulation des âmes consignées et jamais reposées sur des siècles — possiblement de plusieurs cycles antérieurs empilés, pas seulement des Attentifs. Emprunte visuellement traits et compétences des unités perdues par le joueur pendant sa propre partie.

---

## 4. MÉCANIQUE DE CONSIGNATION — détail complet

### Ce que ça fait (et ne fait pas)
Ne ressuscite jamais personne. L'unité reste morte. Ce qui change, c'est le statut de son souvenir :
- **Non consignée** : effacée de l'histoire — plus mentionnée en dialogue, disparaît des archives du jeu.
- **Consignée** : nom et histoire préservés, apparaît en fresque commémorative, peut être citée par d'autres unités, petit bonus de jeu.

### Le double coût caché (jamais affiché, jamais quantifié par un chiffre)
1. **Coût pour le héros** : chaque consignation lui coûte un fragment de sa propre mémoire (un souvenir précis, pas un point de stat) — explique son amnésie. Peut aussi lui faire "hériter" d'un fragment d'identité de la personne consignée (tic, réplique, compétence) — il devient progressivement une mosaïque d'autres gens.
2. **Coût pour la personne consignée** : son âme n'est peut-être pas en repos — elle reste "captive" plutôt que d'accéder à un repos que l'effacement simple aurait permis. Ceci s'applique aussi aux ennemis/PNJ consignés, pas seulement aux alliés.

### Asymétrie voulue entre consignation d'allié et d'ennemi/neutre
- **Allié consigné** : gain de pouvoir modeste pour le héros, coût narratif fort et ressenti (deuil, attachement).
- **Ennemi/PNJ neutre consigné** : gain de pouvoir plus généreux, coût narratif quasi nul en apparence — c'est le levier le plus dangereux, celui qui pousse vers le basculement final, précisément parce qu'il semble gratuit.

### Le seuil de basculement (fin de l'Acte V)
Caché, jamais visible sous forme de jauge ou de compteur — parce que les personnages eux-mêmes dans la fiction ignorent que la consignation a un coût. Garde-fou contre le sentiment d'injustice : la règle est montrée trois fois avant de s'appliquer au héros (le Revenant, le Gardien du Sceau, le Chef du Chœur), procédé de tragédie grecque où le joueur en sait plus que le héros avant que ça lui arrive.

### Foreshadowing (deux fils qui ne se recoupent qu'après coup)
- **Fil 1** : dicton/superstition populaire, jamais confirmé par un personnage crédible.
- **Fil 2** : motif visuel/sonore discret associé aux scènes de consignation, jamais expliqué, qui réapparaît sur l'Innommable à l'Acte V.
- À éviter absolument : tout compteur ou jauge visualisée numériquement, qui serait décodée et optimisée par les joueurs.

### Signes du malaise des âmes consignées (jamais confirmés frontalement)
Rêves/visions d'autres unités montrant la personne consignée fatiguée, en boucle ; ton différent des entrées "consignées" dans le journal (écriture qui tremble, note en marge) ; contraste avec le silence total des non-consignées.

### Mentor/second
Personnage proche du héros qui *soupçonne* la vérité sans jamais la confirmer, avec des remarques de plus en plus insistantes au fil des actes — lui aussi ne sait pas vraiment, il *sent*.

### Le miroir de difficulté (point de vigilance technique, pas encore résolu)
Plus le joueur consigne, plus le héros est fort, mais plus l'Innommable final se nourrit et devient puissant en miroir. Nécessite un vrai travail d'équilibrage pour qu'aucun style de jeu extrême (tout consigner / presque rien consigner) ne rende le combat final trivial ou infaisable. Références utiles : Nier Automata, Undertale, Vampyr (DONTNOD) pour la gestion d'un choix "gratuit en apparence" avec répercussions cachées.

---

## 5. STRUCTURE DE LA CAMPAGNE — 5 actes

| Acte | Titre | Enjeu narratif | Boss |
|---|---|---|---|
| I | La Marche du Bord | Découverte des règles du monde, premier contact avec le Chœur (présenté sans sa doctrine complète) | Le Fossoyeur — arène qui rétrécit en cours de combat |
| II | Les Cendres qui Parlent | Ruines des Attentifs, découverte que l'Effacement est un sceau qui cède | Le Revenant — ancien compagnon non consigné, revenu monstrueux |
| III | Le Nom Oublié | Le héros découvre son origine Attentif et la cause de son amnésie | Le Gardien du Sceau — consigne de force les unités du joueur |
| IV | Le Chœur a Raison | La doctrine du Chœur est présentée sans caricature, doute installé | Le Chef du Chœur — combat en 2 phases, s'efface lui-même en fin |
| V | Ce Que Nous Gardons | Confrontation avec la source de l'Effacement, choix final | L'Innommable — nourri des consignations du joueur pendant toute la partie |

Note de lecture conservée : l'Acte IV reste l'acte le plus fragile dramatiquement si l'attachement du joueur à ses propres pertes n'est pas assez construit avant d'y arriver.

Structure des tableaux à l'intérieur des actes : fixe, ne varie pas selon les choix (décision du concepteur pour limiter le coût de développement). Les variations dues aux morts/consignations passent uniquement par le texte/contexte (système de flags à deux niveaux : impact léger généralisé via flags + dialogues conditionnels courts, impact fort réservé à 2-3 unités pivots). Référence de gestion de ce type de réactivité : Wildermyth (templates procéduraux) ; pour le "bark" incident plutôt que la cinématique dédiée : XCOM, Battle Brothers.

---

## 6. LE TWIST FINAL — le héros devient l'antagoniste

### Mécanisme
Après une consignation de trop (seuil caché, jamais quantifié), le héros bascule et devient littéralement l'Innommable, ou une entité de même nature. Le joueur choisit alors un **héros secondaire** parmi les unités survivantes pour affronter ce que son propre héros est devenu.

### Le cycle
Ce n'est pas un événement isolé : c'est un schéma qui s'est déjà produit, potentiellement plusieurs fois, avant les Attentifs ou en leur sein. Décision de craft : **ne jamais donner de chiffre exact** de cycles précédents — le vertige vient du fait que même ce nombre s'est perdu dans l'oubli qu'il cause lui-même.

### Ce que ça implique pour les personnages déjà posés
- Le Chef du Chœur devient potentiellement plus fort dramatiquement s'il est lui-même un survivant d'un cycle précédent, ayant vu son propre prédécesseur basculer — sa doctrine d'effacement total devient une conclusion vécue, pas une opinion abstraite (**point encore non tranché**, voir section 8).
- Deux échecs sont ainsi dramatisés avant la fin : le Chœur (excès d'oubli — tout effacer, même ce qui mériterait d'être gardé) et l'Innommable/héros déchu (excès de mémoire — tout garder, devenir un contenant sans fin).
- La vraie solution suggérée pour la fin : ni resceller (statu quo), ni détruire bêtement l'Innommable, mais **libérer** les âmes consignées accumulées — synthèse entre la position du héros et celle du Chœur plutôt qu'une victoire de l'un sur l'autre. Le héros secondaire gagne en refusant les deux extrêmes montrés juste avant lui (Actes IV et V), pas en étant plus fort.

### La fin — ton assumé
Décision prise : le monde reste ignorant à la fin, comme tout au long de la campagne. Seuls les survivants restants savent que le cycle est réellement brisé cette fois — pas juste repoussé. Fin volontairement non consensuelle/non satisfaisante pour une partie du public, assumée comme choix artistique fort pour un jeu de niche plutôt que comme un problème à corriger. Références de posture similaire : Spec Ops: The Line, NieR (original).

---

## 7. THÉMATIQUES PHILOSOPHIQUES

Le postulat central (combattre un mal invisible dans l'indifférence totale du monde, agir "car ça doit être fait" sans espoir de reconnaissance) est proche du mythe de Sisyphe chez Camus, avec une nuance importante : contrairement à l'absurdisme strict (l'effort est objectivement vain), ce scénario permet au héros de **réellement réussir**, simplement sans que personne ne le sache jamais — plus proche d'une éthique du devoir que du nihilisme pur. Cette nuance a été jugée plus adaptée à un jeu vidéo qu'un absurdisme total, qui risquerait de désengager le joueur sur la durée.

Garde-fou identifié : la différence entre une fin dérangeante réussie et une fin qui frustre par mauvaise exécution ne tient pas à sa dureté, mais à si le joueur la ressent comme **inévitable** (découlant de tout ce qu'il a vécu) plutôt qu'**arbitraire**. Tout le système de foreshadowing (les trois miroirs, l'asymétrie de consignation, la solitude de l'Ordre) sert cet objectif.

---

## 8. CE QUI RESTE OUVERT — points à trancher

Dans l'ordre approximatif où ils sont apparus, non traités à ce stade :

1. **Le coût de consignation ralentit-il ou est-il inévitable selon le style de jeu ?** Question posée tôt, jamais explicitement close (la discussion sur l'asymétrie allié/ennemi y répond partiellement, mais le mécanisme précis de progression vers le seuil reste à chiffrer).
2. **Fréquence et régénération de la ressource de consignation** (l'"encre" ou équivalent) — combien de consignations par bataille/campagne, qu'est-ce qui la régénère, comment freiner le grind d'ennemis/neutres sans supprimer l'incitation.
3. **Le moment précis de bascule visible et irréversible** près de la fin — à quoi ressemble concrètement ce moment-charnière où le joueur sent qu'il participe consciemment à la chute, sans jamais avoir eu accès aux règles exactes.
4. **Équilibrage du miroir de difficulté** (Acte V) — comment s'assurer qu'aucun style de jeu extrême ne rend le combat final trivial ou infaisable.
5. **Timeline précise du foreshadowing** — à quels moments exacts de chaque acte les deux fils (dicton populaire / motif visuel-sonore) apparaissent.
6. **Le Chef du Chœur est-il un survivant d'un cycle précédent ?** Dernière question posée, sans réponse à ce stade — impacterait directement l'écriture de l'Acte IV.
7. **Nombre et nature des royaumes/factions voisins** — juste effleuré (le monde extérieur "va bien, plus ou moins") mais jamais détaillé : qui sont ces voisins, ont-ils un rapport quelconque avec Cendrelune (commerce, mépris, ignorance totale) ?
8. **Nom définitif du monde/nation, du héros, des lieux clés** — tout est en placeholder ("Cendrelune", "Marchpell", "les Attentifs", "le Chœur Silencieux", "l'Innommable") sans validation finale.
9. **Détail des Attentifs** — effleuré (civilisation antérieure, inventeurs de la consignation) mais leur société, leur chute concrète, leur héritage matériel (ruines, artefacts) restent à développer.
10. **Timeline exacte / calendrier** — le principe "dater depuis la Première Rupture" est proposé mais pas peuplé de dates concrètes pour les événements passés (chute des Attentifs, fondation de l'Ordre, naissance du Chœur, etc.).

---

*Fin du compte rendu. Document à mettre à jour au fil des prochaines sessions.*
