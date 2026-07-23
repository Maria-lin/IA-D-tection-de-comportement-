# Fiche Questions/Réponses — Notebook de détection d'anomalies GAB (v12)

Organisée du plus basique au plus technique. Chaque réponse correspond exactement au code du notebook `detection_anomalies_gab_v12.ipynb`. Les mots techniques sont expliqués en langage simple dès leur première apparition.

---

## Niveau 0 — Le tout premier socle (pour quelqu'un qui ne connaît rien à l'informatique/data)

**Q0.1. C'est quoi un GAB ?**
GAB = Guichet Automatique Bancaire, le nom officiel du "distributeur de billets" dans le jargon bancaire. On l'appelle aussi DAB (Distributeur Automatique de Billets) dans le langage courant — même objet.

**Q0.2. C'est quoi "les données", concrètement, dans ce projet ?**
Ce sont des tableaux de chiffres, comme un immense fichier Excel. Chaque ligne correspond à un événement (ici : "tel distributeur, tel jour, a fait tant de retraits, pour tel montant total, etc."). Le notebook manipule des tableaux de plusieurs dizaines de milliers de lignes — trop pour les lire à l'œil, donc on les fait analyser par un programme.

**Q0.3. C'est quoi un "notebook" ?**
Un carnet de travail numérique qui mélange du texte explicatif et des blocs de code informatique (ici en langage Python) que l'ordinateur exécute un par un. Chaque bloc peut afficher un résultat juste en dessous (un tableau, un graphique, un chiffre) — c'est l'outil standard pour faire de l'analyse de données pas à pas, en gardant une trace lisible de chaque étape.

**Q0.4. C'est quoi "un algorithme" ?**
Une recette de cuisine, mais pour l'ordinateur : une suite précise d'instructions à suivre pour arriver à un résultat. "Trier ces 500 GAB en groupes selon leur ressemblance" est un problème ; l'algorithme, c'est la méthode exacte, étape par étape, que l'ordinateur suit pour le faire.

**Q0.5. C'est quoi "l'intelligence artificielle" ou "le machine learning" ici ? Le programme "réfléchit" vraiment ?**
Non, il ne réfléchit pas comme un humain. Le **machine learning** ("apprentissage automatique") désigne des méthodes où, au lieu d'écrire à la main toutes les règles ("si le taux de capture dépasse X%, alors alerte"), on donne les données à un programme et il *calcule lui-même* les régularités et les écarts, à partir de statistiques. Ici, l'IA ne fait que des calculs de moyennes, d'écarts et de distances entre des chiffres — en beaucoup plus grand nombre et plus vite qu'un humain ne pourrait le faire à la main.

**Q0.6. Pourquoi ne pas juste faire un tableau Excel avec des seuils simples (ex: "alerte si plus de 100 retraits/jour") ?**
Parce qu'un seuil unique ne marche pas pour tout le réseau : 100 retraits/jour est normal pour un GAB de centre-ville très fréquenté, mais énorme pour un petit GAB de village. Le but de ce projet est justement de ne **pas** imposer un seuil universel à la main, mais de laisser le programme comparer chaque GAB à des GAB qui lui ressemblent, et à son propre comportement passé — une alerte plus juste et plus fine qu'un seuil unique valable pour tout le monde.

**Q0.7. Le programme prend-il des décisions tout seul (bloquer un GAB, etc.) ?**
Non. Ce notebook **détecte et signale** des cas à regarder de plus près — il ne déclenche aucune action automatique (pas de blocage, pas d'intervention). La décision finale (envoyer un technicien, enquêter, ne rien faire) reste humaine ; le modèle sert juste à prioriser où regarder en premier parmi des milliers de distributeurs.

---

## Niveau 1 — Questions de base (comprendre le sujet)

**Q1. C'est quoi le but de ce notebook, en une phrase ?**
Repérer automatiquement les distributeurs bancaires (GAB) qui se comportent bizarrement, sans avoir de liste préexistante de "GAB à problème". Un peu comme si on demandait à un système de trier tout seul 5000 distributeurs et de lever la main sur ceux qui sortent du lot, sans jamais lui avoir montré d'exemple de "mauvais" distributeur.

**Q2. Pourquoi "sans avoir de liste préexistante" ? Vous n'avez pas d'exemples de GAB en panne ou frauduleux ?**
Non, on n'a aucun label du type "ce GAB-là était en panne le 15 mars". C'est ce qu'on appelle de l'apprentissage **non supervisé** : au lieu d'apprendre à partir d'exemples corrigés (comme un élève qui corrige ses copies avec un corrigé), le modèle regarde juste la masse des comportements et repère ceux qui s'écartent du groupe.

**Q3. C'est quoi une "famille" de GAB ? Donne un exemple concret.**
Une famille = un groupe de distributeurs qui se ressemblent dans leur activité moyenne sur l'année : combien de retraits par jour, quel montant moyen par retrait, à quelle heure les gens retirent, combien de fois la carte est avalée (capturée), etc.

**Exemple concret** (chiffres inventés pour illustrer, pas les vrais résultats) :
- *Famille "forte activité"* : 300 GAB avec en moyenne 80 retraits/jour, souvent en centre-ville où il y a du monde toute la journée.
- *Famille "activité nocturne élevée"* : 40 GAB où plus de 25% des retraits ont lieu entre 22h et 6h — typiquement des zones de sortie, gares, quartiers festifs.
- *Famille "beaucoup de captures de carte"* : un petit groupe de GAB où le taux de carte avalée est nettement plus élevé que la moyenne — pas forcément "en panne", mais un point à surveiller.

Ce n'est **pas** une notion de "bon" ou "mauvais" GAB — c'est comme classer des clients en segments marketing ("jeunes actifs", "familles", "retraités") : ça décrit un profil, ça ne juge pas.

**Q4. Combien de familles avez-vous trouvées ?**
Le nombre n'est pas décidé à l'avance par moi — il est calculé automatiquement en fonction de ce que montrent les vraies données 2025 (voir Q11 pour la méthode). Le chiffre exact apparaît en exécutant le notebook.

**Q5. C'est quoi la différence entre "famille" et "GAB atypique/en dérive" ?**
Deux questions différentes, à ne pas confondre :
- **La famille** répond à : *"à quel type de GAB celui-ci ressemble-t-il ?"* (question de profil, comme un segment client).
- **Le statut "en dérive"** répond à : *"est-ce que ce GAB montre un signal anormal qui dure dans le temps ?"* (question d'alerte).

**Exemple** : un GAB de la famille "forte activité" (donc un profil tout à fait normal et attendu) peut très bien être marqué "en dérive" parce que, depuis 3 mois, son taux de capture de carte grimpe anormalement — le problème n'est pas d'appartenir à cette famille, c'est l'évolution récente qui inquiète.

---

## Niveau 2 — Comprendre les données et le périmètre

**Q6. D'où viennent les données ?**
D'une table Dataiku appelée `retrait`, elle-même produite par une requête SQL (`ficheidentité.sql`) qui résume, pour chaque distributeur et chaque jour, toutes les opérations de retrait et de capture de carte de la journée.

**Q7. Sur quelle période ?**
Trois années sont disponibles : 2024, 2025 et 2026. **2025 sert d'année de référence** — c'est elle qui définit "ce qu'est un comportement normal". 2024 et 2026 sont ensuite comparées à cette référence (voir Q15 pour le pourquoi).

**Q8. Le dataset couvre quel périmètre géographique ?**
La France métropolitaine uniquement. Les DOM-TOM (Guadeloupe, Martinique, Guyane, Réunion, Mayotte, Nouvelle-Calédonie, etc. — reconnaissables à leur code postal qui commence par 97 ou 98) sont retirés dès le chargement des données, avant même de commencer l'analyse.

**Q9. Chaque GAB a-t-il une ligne pour chaque jour de l'année dans les données ?**
Non, et c'est important : le SQL ne garde que les jours où le GAB a eu **au moins un retrait**. Un jour totalement inactif est absent de la table. Résultat : en moyenne, un GAB n'a qu'environ **12 jours de données actives par an** (pas 365) — un GAB peu fréquenté peut n'apparaître que quelques fois par mois. Ça change la façon de calculer certaines statistiques (voir Q19).

**Q10. Quelles informations utilisez-vous pour décrire le profil d'un GAB ?**
- Combien de retraits en moyenne par jour actif
- Le montant moyen retiré
- Le % de retraits la nuit
- Le % de retraits le weekend
- Le taux de carte capturée (avalée par la machine), sur deux catégories d'opérations un peu différentes ("hors-COS" et "COS" — voir Q27)
- La part des retraits faits avec des cartes de réseaux étrangers (Visa/Mastercard internationaux, JCB, Amex, etc.)
- Un indicateur qui dit si le GAB dépend surtout d'un seul réseau de carte ou si son activité est bien répartie entre plusieurs réseaux différents

---

## Niveau 3 — La méthode de clustering (comment les familles sont trouvées)

**Q11. Comment avez-vous choisi le nombre de familles ? Pourquoi pas juste 3, 5, ou 8 d'un coup ?**
Je n'ai jamais fixé ce nombre moi-même. À la place, j'ai fait tester à l'ordinateur **tous les nombres de familles possibles, de 2 à 10**, avec **3 méthodes de calcul différentes** à chaque fois (voir Q12). Pour chaque combinaison (nombre de familles × méthode), l'ordinateur calcule 3 indicateurs de qualité qui disent "est-ce que ce découpage a du sens statistiquement, ou est-ce n'importe quoi ?". Le nombre final retenu est celui qui obtient les meilleurs indicateurs, tout en restant utilisable en pratique (voir Q13).

**Q12. C'est quoi ces 3 méthodes de calcul, en langage simple ?**
Imagine que tu dois répartir 500 personnes en groupes selon leurs habitudes de dépense :
- **K-Means** : tu places des "centres" au hasard, chaque personne rejoint le centre le plus proche d'elle, puis les centres se recalculent au milieu de leur groupe, et on recommence jusqu'à stabilisation. Fait des groupes plutôt "ronds" et de tailles comparables.
- **Agglomerative Clustering** (classification ascendante hiérarchique) : tu commences avec 500 groupes d'une seule personne, et tu fusionnes à chaque étape les deux groupes qui se ressemblent le plus, jusqu'à obtenir le nombre de groupes voulu. Peut capturer des formes de groupes plus irrégulières que K-Means.
- **Gaussian Mixture** (mélange de lois normales) : suppose que chaque groupe suit une distribution statistique en forme de cloche autour d'une valeur centrale, et calcule la probabilité qu'une personne appartienne à chaque groupe plutôt que de l'assigner strictement à un seul. Plus souple, adapté si les groupes se chevauchent un peu.

**Q13. Le meilleur score statistique donnait-il directement le bon résultat ?**
Non, et c'est un point important à connaître. Le meilleur score pointait souvent vers seulement **2 familles**, mais de façon trompeuse : une famille contenant presque tous les GAB (par exemple 490 sur 500), et une autre n'en contenant qu'une poignée de cas extrêmes isolés — ce n'est pas une vraie "famille", c'est juste "la masse" et "les exceptions".

J'ai donc ajouté une règle de bon sens en plus du score pur : parmi les résultats dont le score reste proche du meilleur possible (à 0.02 près, une petite marge de tolérance), je garde le plus petit nombre de familles à partir de 3, à condition qu'aucune famille ne représente moins de 3% du total des GAB. Objectif : un résultat qui tient statistiquement debout **et** qu'on peut vraiment présenter et exploiter.

**Q14. Comment avez-vous nommé les familles ?**
Aucun nom n'est décidé à l'avance (je n'ai pas écrit "famille touristique" ou "famille rurale" dans le code en espérant que ça tombe juste). Pour chaque famille trouvée, l'ordinateur calcule sa moyenne sur chaque variable (volume, montant, % nuit, etc.) et la compare à la moyenne de tout le réseau. La famille est nommée d'après la caractéristique où elle s'écarte le plus fortement de cette moyenne.

**Exemple** : si une famille a un taux de capture de carte 3 fois plus élevé que la moyenne du réseau, et que c'est son écart le plus marqué par rapport aux autres variables, elle sera nommée quelque chose comme "Famille (plus capture)".

**Q15. Pourquoi comparer 2024 et 2026 à "2025" plutôt que refaire un classement chaque année ?**
Parce que si on recalculait des familles indépendantes chaque année, elles n'auraient aucun lien entre elles d'une année sur l'autre. Concrètement : impossible de dire "ce GAB est resté dans la même famille" ou "il en a changé", puisqu'il n'y aurait pas de familles communes pour comparer.

**Image simple** : c'est comme mesurer si quelqu'un a grossi ou maigri — il faut le peser sur **la même balance**, pas sur deux balances différentes qui n'ont pas le même réglage. 2025 est notre "balance de référence" : on la calibre une fois, puis on l'utilise pour peser 2024 et 2026, sans jamais la recalibrer entre-temps.

**Q16. Comment un GAB de 2024 ou 2026 est-il rattaché à une famille définie sur 2025 ?**
On calcule son profil de la même façon qu'en 2025 (mêmes variables), on le met à la même échelle que les données 2025 (pour que les comparaisons soient justes), puis on regarde à quelle famille de 2025 son profil ressemble le plus, et on le range dedans.

**Q17. Avez-vous vérifié que les variables utilisées n'étaient pas redondantes (deux fois la même info sous un nom différent) ?**
Oui. Avant de faire les familles, je calcule à quel point chaque paire de variables évolue ensemble (leur corrélation). Si deux variables sont corrélées à plus de 0.85 (sur une échelle de 0 à 1, donc quasiment liées), c'est le signe qu'elles racontent presque la même chose — je n'en garde qu'une des deux. Sinon, le classement donnerait deux fois plus d'importance à ce phénomène qu'aux autres, sans qu'on l'ait décidé volontairement.

---

## Niveau 4 — La détection d'anomalie (jour par jour, puis sur l'année)

**Q18. Comment détectez-vous qu'un jour précis est anormal pour un GAB ?**
Avec un algorithme appelé **Isolation Forest** ("forêt d'isolement"), entraîné uniquement sur les données 2025. Pour chaque jour d'un GAB, il regarde 9 indicateurs statistiques ("écarts à la normale") : 8 qui comparent ce GAB, ce jour-là, aux autres GAB du même mois (déjà calculés dans le SQL), et 1 que j'ai ajouté qui compare le GAB à son propre passé récent (voir Q19). L'algorithme repère automatiquement le 1% des jours qui ressort le plus du lot sur l'ensemble de ces 9 indicateurs combinés.

**Q19. Pourquoi ajouter une comparaison "au passé du GAB" en plus de celle "aux autres GAB" ?**
Parce que ce sont deux questions différentes. Un GAB situé dans une zone très touristique peut avoir un profil très différent de la moyenne du réseau **toute l'année**, sans que ce soit anormal pour lui — c'est juste son environnement. En comparant en plus chaque GAB à son **propre** historique récent, on peut détecter une vraie dérive individuelle ("ce GAB, d'habitude si stable, se comporte différemment depuis peu"), même s'il ne ressort pas particulièrement quand on le compare aux autres.

**Q20. Un jour atypique isolé veut-il dire que le GAB est en panne ?**
Non, pas forcément — ça peut être un hasard statistique ponctuel (une journée un peu bizarre, sans que ce soit le signe d'un vrai problème). C'est pour ça qu'il existe un second niveau de vérification, à l'échelle de l'année (voir Q21).

**Q21. Comment décidez-vous qu'un GAB est "en dérive" sur l'année, et pas juste un jour bizarre isolé ?**
Pour chaque mois, on regarde si le GAB a eu au moins un jour atypique dans ce mois. On repère ensuite la plus longue **série de mois d'affilée** marqués atypiques. Si cette série atteint 3 mois consécutifs ou plus, le GAB est classé "dérive récurrente détectée". En dessous de ça, il est classé "pas de dérive durable".

**Exemple** : un GAB qui a un jour bizarre en janvier, puis rien pendant 6 mois, puis un jour bizarre en septembre → pas classé en dérive (c'est ponctuel, dispersé). Un GAB qui a au moins un jour bizarre chaque mois de mars à juin (4 mois d'affilée) → classé "dérive récurrente" (le problème s'installe dans la durée).

**Q22. Pourquoi 3 mois d'affilée, et pas 1 ou 2 ?**
C'est un seuil que j'ai choisi par jugement raisonnable — ce n'est pas un chiffre calculé automatiquement comme le nombre de familles (Q11). L'idée : un ou deux mois avec un jour bizarre peuvent arriver par pur hasard, même sur un GAB parfaitement sain. Trois mois d'affilée, c'est beaucoup plus difficile à expliquer par la chance seule — ça commence vraiment à ressembler à un changement de comportement qui dure. **Ce seuil peut être discuté et ajusté** selon ce que l'équipe métier juge pertinent.

**Q23. Pourquoi repérer seulement 1% des jours comme "atypiques" (le réglage appelé "contamination") ? Pourquoi pas un autre chiffre ?**
C'est aussi un réglage que j'ai choisi, pas un calcul automatique. 1% est une valeur de prudence courante pour ce type d'algorithme : assez bas pour ne pas noyer l'analyse sous des milliers de "faux positifs", assez haut pour capter un vrai signal. **Ce chiffre peut être recalibré** si, en pratique, on trouve qu'il détecte trop ou pas assez de cas.

---

## Niveau 5 — Limites et points à assumer (les questions difficiles)

**Q24. Comment savez-vous que vos détections sont "vraies" ? Vous avez vérifié avec des cas connus (GAB dont on sait déjà qu'ils ont eu un problème) ?**
C'est la vraie limite honnête de ce projet : on n'a **aucune liste de référence** de GAB confirmés en panne ou en fraude pour vérifier si le modèle a raison. Ce qu'on peut faire en attendant :
- Vérifier si nos détections recoupent le `flag_atypique` déjà calculé par le SQL (un premier signal de cohérence).
- Faire relire, à terme, un échantillon de GAB détectés par les équipes terrain qui connaissent l'historique réel de ces distributeurs — c'est la vraie validation qui manque encore.

**Q25. Le modèle basé sur 2025 va-t-il rester valable dans plusieurs années ?**
Pas garanti indéfiniment. Si le réseau de GAB change en profondeur (nouveaux types de distributeurs, nouvelles règles, nouveaux usages de paiement), le modèle 2025 peut devenir moins représentatif de la réalité actuelle. Le notebook inclut une vérification automatique : on mesure si les GAB de 2024 et 2026 sont statistiquement "plus loin" de leurs familles de référence que ne l'étaient les GAB de 2025 eux-mêmes — un signal d'alerte visible si le modèle commence à devenir obsolète.

**Q26. Pourquoi regarder par mois et pas par semaine, puisque les données sont journalières ?**
Techniquement, la table `retrait` n'a pas de vraie colonne "date" (juste année/mois/jour séparés), donc calculer proprement des semaines calendaires n'était pas possible sans reconstituer une date. On est resté au niveau mois, ce qui a l'avantage d'être cohérent avec le `flag_atypique` déjà calculé dans le SQL, lui aussi à l'échelle du mois.

**Q27. Est-ce qu'une opération "hors-COS" et une opération "COS" sont traitées différemment ? C'est quoi "COS" ?**
Le SQL source distingue bien deux catégories d'opérations (retraits et captures de carte "hors-COS" d'un côté, "COS" de l'autre), avec des colonnes séparées pour chacune. **Point à clarifier avec l'équipe** : la définition métier exacte de "COS" doit être confirmée pour savoir si ces deux mesures doivent rester séparées dans l'analyse (comme actuellement) ou être combinées différemment.
