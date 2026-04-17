# Rapport de synthèse technique

**Projet** : RAPEL24H_ANEMIE, consommation alimentaire des adolescents (Sénégal)
**Auteur** : Awouto Koffi Samson
**Date** : avril 2026

## Contexte et périmètre

Le pipeline traite les données du rappel 24 heures de l'enquête nationale sur la consommation alimentaire et l'anémie chez les adolescents sénégalais. L'enquête a été conçue et collectée par l'équipe projet dans le cadre de la collaboration UCAD/IFPRI. Le présent traitement intervient après la consolidation des sections SE de Survey Solutions. Il reçoit en entrée la base `Anemie_Base_Consommation_R24H` déjà construite, les bases de recettes ménage (BF et BI), la base de recettes standard (RST), la base de recettes moyennes (RM), et les référentiels de facteurs de conversion.

L'objectif est de produire une base d'analyse propre, cohérente en interne, directement utilisable pour estimer les prévalences de carence en fer et en zinc, pour alimenter les modèles d'anémie, et pour nourrir toute régression nutritionnelle en aval. Le traitement est pensé comme un livrable autonome. Un analyste doit pouvoir l'exécuter sans intervention préalable et obtenir la base finale en une passe.

Le traitement s'organise en sept phases distinctes qui s'enchaînent dans un script maître. Chaque phase dispose de son propre dossier, de ses propres scripts et de ses propres sorties. Ce découpage a été choisi pour que chaque étape soit rejouable isolément pendant la phase de développement, et pour que la traçabilité reste claire au moment des revues.

## Phase 3, nettoyage des bases sources

La phase 3 prépare les cinq bases brutes à la consommation par les phases suivantes. Le travail se concentre sur trois problèmes récurrents dans ce type de données. Le premier est le typage hétérogène des clés de jointure. Certains fichiers stockent `Interview__key`, `Code_Plat` ou `Code_Ingredient` comme des numériques, d'autres comme des chaînes. Une jointure sans harmonisation préalable échoue en silence sur une partie des observations. La phase 3 force donc tous les champs de clé en chaîne avec un format homogène, et applique un `trim` systématique pour purger les espaces résiduels qui font autrement échouer les correspondances.

Le deuxième problème est le traitement des ressertis. Dans le rappel original, une portion resservie est enregistrée comme une ligne supplémentaire avec le même `Code_Ingredient` et le même `Code_Plat`. Ne pas agréger ces lignes conduit à des doublons de clé qui cassent les jointures ultérieures. Le `collapse` de la phase 3 additionne les quantités et les apports sur la clé `(Interview__key × Numero_Rappel × Code_Repas × Code_Plat × Code_Ingredient)`, ce qui produit une ligne unique par déclaration d'ingrédient.

Le troisième problème concerne quelques imputations ciblées. Deux cas dominent les valeurs manquantes sur `Ingere_Fer` : le sel, qui n'apporte pas de fer par définition, et le concentré de tomate, dont la teneur en fer (3,5 mg pour 100 g) est bien documentée dans les tables CIQUAL. Ces deux imputations suppriment environ un quart des manquants sans introduire d'arbitraire. Les autres manquants sont préservés, un flag interne garantissant qu'un `collapse` avec somme ne les transforme pas silencieusement en zéros.

La phase 3 produit `conso_clean.dta`, ainsi que les quatre bases de recettes nettoyées (`recette_BF_clean`, `recette_BI_clean`, `recette_RST_clean`, `recette_RM_clean`) et la clé individu par rappel (`cle_rappel.dta`). Ces sorties alimentent directement la phase 4.

## Phase 4, consolidation des référentiels et reconstruction des quantités

La phase 4 est le cœur du traitement. Elle poursuit deux objectifs indissociables. D'abord, consolider les référentiels de recettes et de facteurs de conversion dans une structure unifiée. Ensuite, reconstruire la quantité effectivement ingérée de chaque ingrédient à partir de ces référentiels.

Le problème de fond est le suivant. Dans la base de consommation, la quantité déclarée par ingrédient est souvent approximative, en particulier pour les ingrédients intégrés dans un plat cuisiné. L'enquêté déclare plus facilement avoir mangé 200 g de riz au poisson que d'énumérer 45 g de riz, 30 g de poisson, 15 g d'huile et 10 g d'oignon. La base de recettes ménage (BF et BI) contient, pour chaque ménage et chaque plat, la décomposition effective en ingrédients avec leurs pourcentages massiques. Appliquer cette recette à la quantité totale de plat déclarée reconstitue des quantités ingrédient cohérentes au niveau du ménage.

La jointure suit une hiérarchie explicite. Chaque ligne de consommation tente d'abord une correspondance avec la recette BF du ménage, sur la clé `(Interview__key × Code_Plat × Code_Ingredient)`. Si la recette BF n'existe pas, la jointure bascule sur BI. Si BI échoue, on passe à la recette standard nationale RST, puis à la recette moyenne RM. Les lignes qui échouent à toutes ces étapes sont marquées `NON_APPARIE` et conservent leur quantité déclarée. Ce mécanisme en cascade garantit qu'on utilise toujours l'information la plus locale possible, tout en offrant un filet de sécurité pour les plats atypiques. Au total, 99,85 % des 66 784 lignes trouvent une correspondance via une recette ménage, ce qui confirme la qualité de la collecte sur le volet recettes.

La consolidation des facteurs de conversion occupe le second script de la phase. Les facteurs sont initialement dispersés dans plusieurs classeurs Excel (aliments usuels, plats recettes, pains et sandwichs, aliments industriels emballés). Le script `02_consolidation_referentiel.do` charge chaque source, harmonise les colonnes, déduplique sur la clé `(CODE_ALIMENT × UNITE)` et produit un référentiel unique `Base_Facteurs_Definitifs.dta`. Ce référentiel est ensuite utilisé pour convertir les unités de mesure non métriques (cuillères, louches, morceaux) en grammes.

La sortie principale est `Base_Conso_Apuree_P4.dta`, qui contient une ligne par ingrédient par rappel, avec la quantité reconstruite `Quantite_Ingredient_g`, la source de la recette utilisée (`Source_Recette`), et toutes les variables d'origine préservées.

## Phase 5, table de composition reconstruite et recalcul des apports

La reconstruction massive des quantités en phase 4 crée une incohérence interne de la base. Les apports nutritionnels (`CALORIES`, `Ingere_Fer`, `Ingere_Zinc`, etc.) présents dans la base source ont été calculés en amont sur les quantités déclarées, pas sur les quantités reconstruites. Une ligne peut donc afficher 50 g de viande dans `Quantite_Ingredient_g` mais un apport calorique qui correspond encore aux 30 g initialement déclarés. Laisser la base dans cet état enverrait toutes les analyses en aval sur des chiffres faux.

La phase 5 rétablit la cohérence par une reconstruction de la table de composition nutritionnelle. Le raisonnement est le suivant. Pour chaque ligne de la base, on dispose de la quantité brute déclarée et de l'apport calculé. Le rapport entre les deux donne une teneur implicite pour 100 g de l'ingrédient concerné. En moyennant ces teneurs implicites sur toutes les occurrences d'un même `Code_Ingredient`, on obtient une table de composition cohérente avec les données observées. C'est une rétro-ingénierie de la table de référence à partir des apports déjà calculés.

Cette approche a un défaut assumé. Elle gomme la finesse des 38 codes de rétention intégrés en amont. Un plat cuisiné avec forte perte (type bouillon long) voit son apport reconstruit légèrement sur-estimé par rapport au calcul original. Sur 712 ingrédients, l'effet se lisse et l'erreur reste marginale. Le bénéfice obtenu en contrepartie, à savoir la cohérence stricte entre quantité et apport à chaque ligne, l'emporte largement sur ce léger biais. La section correspondante du document d'écarts détaille une alternative plus propre (un rescalage ligne par ligne) dont l'application est prévue en prochaine itération.

Le second script de la phase 5 applique la table reconstruite à chaque ligne de `Base_Conso_Apuree_P4.dta` pour produire les apports finaux. La sortie `Base_Consommation_FINALE_P5.dta` contient sept nutriments : calories, fer, zinc, protéines, lipides, glucides, vitamine C. Chaque valeur est maintenant cohérente avec la quantité reconstruite.

## Phase 6, validation nutritionnelle et exclusion des rappels implausibles

À la sortie de la phase 5, chaque ligne a un apport cohérent avec sa quantité. Reste à repérer les rappels journaliers dont le total agrégé n'est pas biologiquement plausible. Deux seuils s'appliquent au cumul sur 24 heures par couple `(individu × rappel)`. Les calories totales doivent être comprises entre 800 et 5 000 kcal. Le fer total ne doit pas dépasser 60 mg.

Le plancher à 800 kcal marque la limite en dessous de laquelle un rappel adolescent devient inexploitable pour l'analyse nutritionnelle. Un adolescent qui déclare moins de 800 kcal sur 24 heures est soit en sous-déclaration massive, soit en situation alimentaire exceptionnelle non représentative. Le plafond à 5 000 kcal couvre les cas de sur-déclaration systématique ou d'erreur d'unité de mesure non rattrapée en amont. La borne fer à 60 mg vient de l'Apport Maximal Tolérable fixé par l'OMS entre 40 et 45 mg selon l'âge. Un total supérieur à 60 mg est quasi systématiquement la signature d'une teneur aberrante sur un ingrédient donné dans la table de composition, plutôt qu'une réelle consommation.

Le choix a été fait d'exclure les rappels concernés plutôt que de les flagger. L'exclusion repose sur une logique d'intégrité de rappel. On retire tout le rappel, pas seulement les lignes extrêmes. Retirer quelques ingrédients extrêmes en conservant le reste biaiserait la structure du repas déclaré. La granularité pertinente pour un contrôle de plausibilité est bien le rappel complet.

Sur les 1 818 rappels entrants, 136 sont exclus, soit 7,5 %. Il en reste 1 682, portés par 61 853 lignes de consommation. Sur ce sous-ensemble validé, les totaux journaliers médians s'établissent à 2 500 kcal, 11 mg de fer, 8,2 mg de zinc et 60,5 g de protéines. Ces ordres de grandeur sont cohérents avec les études régionales disponibles sur la population adolescente ouest-africaine.

Les rappels exclus sont conservés à part dans `Liste_Individus_Exclus.dta` avec l'ensemble de leurs totaux. Cette traçabilité permet de chiffrer finement le taux d'exclusion, d'analyser d'éventuels profils sur-représentés dans les exclusions (région, âge, quintile), et de documenter le biais éventuel introduit par le filtre.

## Phase 7, agrégation et indicateurs

La phase 7 produit la base d'analyse finale à partir de `conso_phase6_validee.dta`. Le travail se fait en quatre étapes.

La première est la décomposition des apports par source de recette. Avant l'agrégation, quatre variables intermédiaires sont créées (`kcal_menage`, `kcal_rst`, `kcal_rm`, `kcal_non_apparie`). Chacune ne prend la valeur de `CALORIES` que pour les lignes issues de la source correspondante. Une fois le `collapse` effectué au niveau du rappel, ces quatre variables donnent la décomposition calorique par source et permettent de calculer des parts (`Part_Kcal_Menage`, `Part_Kcal_RST`, etc.). Cette information sert de contrôle qualité rappel par rappel. Un individu dont 80 % des calories viennent de la source `NON_APPARIE` est un signal d'alerte. Inversement, un individu dont 95 % des calories proviennent des recettes ménage bénéficie du traitement le plus fiable possible.

La deuxième étape est l'agrégation journalière proprement dite. Le `collapse` par `(Interview__key × Numero_Rappel)` additionne les sept nutriments et récupère en `first` les caractéristiques individuelles constantes à l'intérieur d'un rappel (âge, sexe, région, quintile, poids de sondage, milieu de résidence). La base passe de 61 853 lignes à 1 682 lignes rappel.

La troisième étape est la construction des flags binaires de carence. Quatre seuils sont appliqués, tirés des Estimated Average Requirements de l'OMS et de la FAO. Le fer est considéré en carence sous 10,5 mg par jour, valeur qui tient compte d'une biodisponibilité de 10 % caractéristique d'un régime mixte ouest-africain à dominante céréales et légumineuses. Le zinc est en carence sous 7 mg par jour. Les protéines sont en insuffisance sous 34 g par jour, seuil FAO pour la tranche 10-14 ans. L'insuffisance calorique est fixée à 1 800 kcal par jour, plancher plausible pour un adolescent faiblement actif.

Ces seuils sont uniformes. Ils ne différencient pas par âge ni par sexe, ce qui reste un choix simplificateur assumé. Une analyse plus fine demanderait des seuils spécifiques par tranche, ce qui suppose une table de référence complète encore à valider par l'équipe projet. L'extension est prévue en phase 7 bis, dès que la table sera disponible.

La quatrième étape est le contrôle final pondéré. Un `svyset` sur `HH_Sample_Weight` suivi d'un `svy: mean Total_Fer, over(Milieu_Residence)` vérifie que la base finale permet bien les estimations pondérées attendues. Ce contrôle minimal garantit au coordonnateur que le livrable est immédiatement utilisable pour les statistiques descriptives nationales.

La sortie est `BASE_ANALYSE_FINALE_ANEMIE_P7.dta`, aussi livrée sous le nom `Base_Analyse_Anemie_Finale.dta`. Elle contient 1 682 rappels et 32 variables : les totaux journaliers par nutriment, les parts par source de recette, les quatre flags de carence, les caractéristiques individuelles et le poids de sondage.

## Articulation avec les rapports d'audit

Six rapports d'audit v2 ont été produits en avril 2026 sur les différentes bases sources. Ils ont servi de base de travail et ont été intégrés de manière systématique dans la construction du pipeline. La majorité des corrections prescrites a été reprise telle quelle. Quelques choix diffèrent cependant, soit pour aller plus loin que ce que l'audit demandait, soit pour trancher un arbitrage méthodologique que l'audit laissait ouvert. Ces écarts sont documentés un à un dans `Ecarts_Methodologiques_vs_Audits.md`. Chaque écart est réversible sur décision du coordonnateur.

Le périmètre des audits SE14 et SE22 n'est pas couvert par ce pipeline. Ces sections relèvent du traitement amont qui produit la base `Anemie_Base_Consommation_R24H`, traitement confié à une autre équipe. Refaire ce travail ici créerait un doublon et risquerait une divergence avec la base officielle. Si une intégration totale est souhaitée à terme, un script amont peut être ajouté avant la phase 3.

## Fichiers livrés

À la racine du livrable final se trouvent ce rapport et le document d'écarts. Le dossier `Donnees/` contient la base d'analyse finale `Base_Analyse_Anemie_Finale.dta` (1 682 rappels, 32 variables). Le dossier `Methodologie/` regroupe les quatre fiches détaillées par phase (4, 5, 6, 7). Le dossier `Dictionnaires_Referentiels/` livre les deux référentiels unifiés produits en phase 4, ingrédients et recettes, utiles pour toute ré-analyse ou extension future.

Les livrables intermédiaires (bases de phase 4 à 6) sont stockés dans `traitement/LIVRABLES_INTERMEDIAIRES/`. Ils ne sont pas nécessaires à l'analyse finale mais permettent un audit indépendant de chaque étape ou une reprise partielle du pipeline sur une phase donnée.

## Reproductibilité

Le pipeline s'exécute en une commande depuis `00_MASTER.do` à la racine du dossier `traitement/`. Toutes les phases sont idempotentes. On peut rejouer l'ensemble sans effet de bord sur les entrées. Les scripts de chaque phase sont isolés dans `traitement/Phase_X/scripts/` et ne partagent aucun état global en dehors des chemins définis dans le maître.

La variable `PHASE_MAX` dans `00_MASTER.do` contrôle la phase maximale exécutée, ce qui permet de relancer partiellement le pipeline pendant le développement ou lors d'une revue ciblée. La détection du dossier projet est automatique via `global PROJET_DIR "`c(pwd)'"`. Aucun chemin absolu n'est codé en dur dans les scripts. Le dépôt est portable entre Windows, Linux et macOS sans ajustement.

## Extensions naturelles

Trois directions d'extension s'offrent naturellement à partir de la base finale.

La première est le calcul des Mean Adequacy Ratio et des Nutrient Adequacy Ratios par âge et par sexe. Cette extension demande une table de Besoins Nutritionnels Recommandés différenciée qui n'a pas été arrêtée dans le cadre du pipeline actuel. Dès que la table est validée, l'ajout représente une quinzaine de lignes de Stata en fin de phase 7.

La deuxième est l'imputation systématique des micronutriments manquants, en particulier le fer (5,9 % de manquants dans la base source) et la vitamine A (9 %). Trois stratégies sont disponibles, une moyenne par ingrédient, une interpolation par groupe alimentaire, ou une exclusion au cas par cas. Le choix dépend de l'usage analytique visé. Figer une règle unique dans le pipeline aurait bloqué cette décision pour toute la suite, ce qui justifie le report.

La troisième est l'estimation de la distribution habituelle de consommation. Un rappel unique capture la consommation d'un jour donné, pas la consommation habituelle d'un individu. La prévalence de carence calculée sur un rappel unique sur-estime la vraie prévalence, parfois fortement. Les méthodes d'estimation de distribution habituelle (Iowa State, SPADE, NCI) corrigent ce biais, mais elles demandent un second rappel sur au moins une partie de l'échantillon. Cette extension dépend donc de la disponibilité future d'un second tour de collecte.
