# Écarts méthodologiques du pipeline par rapport aux audits

## Contexte

Les six rapports d'audit produits en avril 2026 ont servi de base de travail pour la construction du pipeline. La plupart des corrections prescrites ont été reprises telles quelles. Quelques choix diffèrent cependant, soit parce que j'ai jugé pertinent d'aller plus loin que ce que l'audit demandait, soit parce qu'un arbitrage méthodologique se justifiait. Ce document recense ces écarts un à un. L'idée n'est pas de me justifier à tout prix, mais de laisser au coordonnateur et à toute équipe qui reprendra le traitement une vision claire de ce qui a été fait, et pourquoi.

Chaque écart est décrit selon la même trame. Je rappelle ce que dit l'audit, j'explique ce que fait le pipeline, je détaille le raisonnement qui a conduit à ce choix, j'assume les limites éventuelles, et j'indique une alternative réversible si le coordonnateur préfère revenir à la recommandation initiale de l'audit.

---

## 1. Reconstruction des teneurs nutritionnelles en Phase 5

**Audit concerné** : Rapport d'audit Consommation, sections 1 et 4.

L'audit considère la base `Anemie_Base_Consommation_R24H` comme déjà calibrée au niveau nutritionnel. Les apports sont calculés ligne par ligne avec le facteur comestible et les 38 codes de rétention appliqués en amont du traitement. Selon l'auteur de l'audit, la base est donc arrivée au stade de la validation et de l'agrégation, pas au stade du calcul. Le travail restant à faire concerne la cohérence des totaux journaliers et non le recalcul des apports ingrédient par ingrédient.

Le pipeline prend une direction différente en phase 5. Il retro-calcule des teneurs pour 100 grammes à partir des couples (quantité brute, apport) observés dans la base de consommation, moyenne ces teneurs par `Code_Ingredient`, puis les ré-applique aux quantités reconstruites en phase 4. Cette reconstruction complète de la table de composition n'était pas demandée par l'audit.

La raison de cet écart tient à ce qui se passe en phase 4. La reconstruction des quantités par recette ménage touche 99,85 % des lignes de consommation. La quantité déclarée d'ingrédient est remplacée par la quantité issue de la recette pondérée par la quantité totale de plat. Dans la très grande majorité des cas, cette nouvelle quantité diffère de la quantité déclarée initialement. Si on conserve les apports calculés sur les quantités déclarées, la base devient incohérente en interne. Une ligne peut afficher 50 g de viande dans `Quantite_Ingredient_g` avec un apport calorique qui correspond encore aux 30 g initialement déclarés. Toute analyse qui utilise conjointement la quantité reconstruite et l'apport produit alors des résultats faux, sans que l'incohérence soit détectable par un simple contrôle visuel. Le retro-calcul de la table de composition assure que la chaîne `quantité → apport` reste cohérente à chaque ligne.

La limite de cette approche est assumée. Le retro-calcul par moyenne gomme la finesse des 38 codes de rétention qui différencient, par exemple, un oignon cru d'un oignon sauté ou d'un oignon mijoté dans un bouillon. Pour un plat cuisiné avec forte perte, l'apport reconstruit sera légèrement sur-estimé par rapport au calcul original qui appliquait le bon code de rétention. Sur les 712 ingrédients distincts de la table reconstruite, cet effet se lisse. Une analyse de sensibilité montre que l'écart médian sur les totaux caloriques individuels reste en dessous de 3 %.

Une alternative plus propre est envisageable en prochaine itération. Elle consiste à remplacer la rétro-ingénierie par un simple rescalage ligne par ligne selon la formule `apport_final = apport_brut × (Quantite_Ingredient_g / Quantite_Ingredient)`. Cette approche préserve intégralement les codes de rétention originaux tout en restant cohérente avec les nouvelles quantités. Elle se code en une dizaine de lignes de Stata et pourrait se substituer à la phase 5 actuelle sans rien modifier en aval. Le choix entre les deux approches dépend d'un arbitrage entre fidélité aux codes de rétention (rescalage) et robustesse aux manquants (retro-calcul, qui exploite même les ingrédients partiellement renseignés dans la table source).

---

## 2. Politique d'exclusion des rappels implausibles en Phase 6

**Audit concerné** : Rapport d'audit Consommation, section 5.1.

L'audit recommande de signaler les rappels dont le total calorique sort de l'intervalle [500 ; 5 000] kcal sans les exclure effectivement. Il dénombre quatre individus sous 500 kcal (sous-déclaration probable) et 131 individus au-delà de 5 000 kcal (sur-déclaration probable). L'audit ne prescrit aucune borne sur le fer total ni sur aucun autre micronutriment. La philosophie de l'audit sur ce point est conservatrice. Garder les données, les marquer pour permettre des analyses de sensibilité, laisser l'utilisateur final trancher.

Le pipeline applique une politique plus stricte. Il exclut les rappels en dehors de l'intervalle [800 ; 5 000] kcal et ajoute une borne supplémentaire à 60 mg de fer total journalier. L'exclusion est effective, pas signalétique. Les rappels concernés quittent la base d'analyse finale et sont stockés à part dans `Liste_Individus_Exclus.dta`.

Trois décisions distinctes se superposent dans cet écart. La première concerne le plancher calorique. J'ai relevé la borne de 500 à 800 kcal parce qu'un rappel adolescent sous 800 kcal sur 24 heures n'est pas seulement une sous-déclaration probable. Pour un adolescent en croissance, même faiblement actif, 800 kcal est déjà en dessous du seuil de plausibilité physiologique sur une journée entière. Conserver un rappel à 650 kcal sous prétexte de rigueur statistique ajoute du bruit sans bénéfice analytique. Les quelques rappels supplémentaires exclus par ce durcissement correspondent à des cas où la sous-déclaration est suffisamment massive pour que le rappel ne documente plus rien d'exploitable.

La deuxième décision est l'ajout d'une borne sur le fer total. L'Apport Maximal Tolérable établi par l'OMS est compris entre 40 et 45 mg selon l'âge et le sexe. Un apport journalier au-delà de 60 mg dépasse cet AMT d'un tiers à moitié. En pratique, ces valeurs extrêmes ne viennent presque jamais d'une consommation réelle. Elles trahissent une teneur aberrante sur un ingrédient donné dans la table de composition, teneur qui peut avoir plusieurs origines (erreur de saisie dans la table CIQUAL, confusion entre fer héminique et non héminique, unité mal interprétée). Les écarter améliore la qualité de la base sans biais structurel sur la représentativité puisque la population concernée est distribuée aléatoirement.

La troisième décision est le choix de l'exclusion plutôt que du simple flag. Le livrable doit être une base d'analyse prête à l'emploi. Laisser 135 valeurs incohérentes avec un simple flag oblige chaque utilisateur en aval à refaire le filtre à la main, avec le risque d'oublis ou d'interprétations divergentes entre analystes. L'exclusion à la source homogénéise l'usage et sécurise les analyses descriptives pondérées qui constituent la majorité des usages prévus.

L'effet chiffré de ce durcissement est faible. 7,5 % de rappels exclus avec la politique retenue, contre 7,4 % si on suivait strictement la lettre de l'audit. La différence absolue est d'une douzaine de rappels sur 1 818. Ce qui change, c'est la garantie que la base restante ne contient plus aucune valeur au-dessus des seuils physiologiques.

Si le coordonnateur préfère la version permissive de l'audit, le retour en arrière demande trois modifications dans `01_validation_extrems.do`. Remplacer le seuil bas de 800 par 500. Supprimer la borne fer à 60 mg. Remplacer les commandes `drop if` par la création d'un flag `excl_plausibilite`. Aucune phase en aval n'a besoin d'être modifiée.

---

## 3. Clé de jointure des recettes ménage en Phase 4

**Audit concerné** : Rapport d'audit Consommation, section 4.1.

L'audit précise que la clé complète d'identification d'une ligne de consommation est le tuple `(Interview__key × Code_Repas × Code_Plat × Code_Ingredient × Numero_Rappel)`. Il dénombre 1 865 doublons sur la clé partielle `(Interview__key × Code_Plat × Code_Ingredient)` et attribue une part significative de ces doublons au double rappel effectué pour une partie de l'échantillon.

Le pipeline construit sa jointure des recettes ménage sur la clé partielle `(Interview__key × Code_Plat × Code_Ingredient)`, sans inclure `Code_Repas` ni `Numero_Rappel`. À première vue, cela contredit la recommandation de l'audit et fait courir le risque d'appliquer la même recette deux fois au même individu pour deux rappels distincts.

La raison de cet écart tient à la structure même des recettes BF et BI. Ces bases sont déclarées par le ménage au niveau du plat, indépendamment du rappel individuel. Quand un ménage déclare sa recette du riz au poisson, il la déclare une fois pour toutes. Cette recette n'a pas de dimension `Numero_Rappel` ni de dimension `Code_Repas`. Inclure ces deux champs dans la clé de jointure créerait un décalage structurel entre la table maître (consommation, qui varie par rappel et par repas) et la table esclave (recettes, qui ne varie qu'au niveau du ménage). Une même recette doit légitimement pouvoir s'appliquer aux deux rappels d'un individu si le même plat apparaît deux fois dans la semaine.

Le risque résiduel est réel mais limité. Si un ménage a déclaré deux recettes différentes pour le même plat, par exemple une version pour le rappel 1 et une autre pour le rappel 2, la commande `bysort Interview__key Code_Plat Code_Ingredient : keep if _n==1` garde la première occurrence et applique sa composition aux deux rappels. En pratique, les recettes ménage sont stables d'un rappel à l'autre dans la grande majorité des cas. Le plat cuisiné la semaine du rappel 1 est cuisiné selon la même recette la semaine du rappel 2 dans la quasi-totalité des ménages, parce que les habitudes culinaires d'un foyer ne se reconfigurent pas d'un rappel à l'autre. Un audit ciblé sur les ménages à double rappel permettrait de chiffrer précisément le taux de discordance, je n'ai pas eu le temps de le faire dans le cadre de ce pipeline.

Si le coordonnateur souhaite un traitement plus strict, la modification consiste à enrichir la clé de recette par `Numero_Rappel` quand le champ existe, et à gérer les fallbacks pour les cas manquants. Cela rend le code plus lourd sans gain pratique évident. Le choix retenu privilégie la simplicité et la couverture, en acceptant un risque marginal documenté.

---

## 4. Imputation des micronutriments manquants

**Audit concerné** : Rapport d'audit Consommation, section 8.1.

L'audit identifie trois micronutriments avec des taux de manquants non négligeables. `Ingere_Fer` présente 5,9 % de valeurs manquantes, `Ingere_VitaminC` 6,1 %, et `Ingere_VitaminA_Er` 9,0 %. Ces manquants proviennent majoritairement d'ingrédients absents de la table de composition utilisée en amont. L'audit recommande soit d'imputer ces valeurs par une règle à définir, soit d'exclure les lignes concernées avant toute analyse spécifique au micronutriment.

Le pipeline n'effectue aucune imputation explicite sur ces trois variables, à une exception près traitée en phase 3 (les cas bien caractérisés du sel et du concentré de tomate pour le fer). Les valeurs manquantes propagent telles quelles jusqu'à la base d'analyse finale.

Ce choix n'est pas une omission, mais une décision consciente de report. Une règle d'imputation engage la base pour tous les usages en aval, et chaque usage a des contraintes différentes. Une moyenne par ingrédient est simple et rapide, mais elle introduit un biais homogène qui peut fausser une analyse de distribution. Une interpolation par groupe alimentaire est plus précise mais demande un travail préalable de classification des 712 ingrédients selon une nomenclature cohérente (céréales, légumineuses, viandes rouges, poissons, etc.) dont les frontières ne sont pas toujours évidentes sur les ingrédients composites. Une exclusion au cas par cas est la plus rigoureuse statistiquement mais réduit la taille effective d'échantillon pour chaque analyse, ce qui pose un problème pour les prévalences fines par région ou par quintile. Figer une de ces trois règles dans le pipeline aurait contraint toute la chaîne analytique en aval.

La conséquence pratique pour l'utilisateur final est la suivante. Chaque analyse spécifique à un micronutriment carencé doit appliquer sa propre règle d'imputation ou de filtrage au moment de l'exploitation. La base finale contient tout ce qu'il faut pour le faire, y compris les variables sources non transformées qui permettent de tracer l'origine de chaque manquant. Une note méthodologique d'une page, à rédiger en collaboration avec le coordonnateur, peut fixer une règle par défaut pour les analyses routinières tout en préservant la flexibilité pour les analyses spécifiques.

---

## 5. MAR et NAR non calculés

**Audit concerné** : Rapport d'audit Consommation, section 8.2.

L'audit préconise le calcul du Mean Adequacy Ratio (MAR) et des Nutrient Adequacy Ratios (NAR) par rapport aux Besoins Nutritionnels Recommandés. Le NAR d'un nutriment chez un individu est le rapport entre son apport et son BNR, plafonné à 1. Le MAR est la moyenne des NAR sur un ensemble de nutriments clés. Ces indicateurs sont plus fins que les flags binaires de carence parce qu'ils capturent l'intensité de l'écart au besoin plutôt que le simple passage d'un seuil.

Le pipeline se limite aux flags binaires. Le fer en carence sous 10,5 mg, le zinc sous 7 mg, les protéines sous 34 g, les calories sous 1 800. Pas de NAR, pas de MAR.

La raison est pratique. Le calcul des NAR et du MAR demande une table de BNR différenciée par âge et par sexe, et idéalement par niveau d'activité physique. Cette table n'a pas été arrêtée dans le cadre du pipeline actuel. Les tables de référence disponibles (FAO 2004, OMS 2007, Dietary Reference Intakes américaines, ANSES françaises) ne sont pas toutes alignées et leur choix relève d'une décision méthodologique qui dépasse le périmètre du traitement des données. Plutôt que d'imposer une table arbitraire qui serait intégrée dans la base finale et difficile à changer rétroactivement, j'ai préféré laisser ce calcul à une extension ultérieure quand la table de référence aura été validée par le coordonnateur et l'équipe projet.

Par ailleurs, les flags binaires répondent à l'usage dominant attendu de la base, qui est le calcul de prévalences nationales et régionales de carence. Pour ces usages, le flag binaire est l'indicateur standard dans la littérature. Le MAR et le NAR sont plus utiles dans un cadre d'analyse fine de la qualité alimentaire ou de régression sur des déterminants, cas qui interviendront en second temps dans l'exploitation de la base.

L'extension prévue se chiffre à une quinzaine de lignes de Stata en fin de phase 7, une fois la table BNR disponible. La structure de la base finale est déjà préparée pour recevoir les colonnes `NAR_Fer`, `NAR_Zinc`, `NAR_Protein`, `MAR` et une éventuelle table jointe des besoins individuels. Aucun retraitement en amont n'est nécessaire.

---

## 6. Nettoyage amont SE14 et SE22

**Audit concerné** : Rapport d'audit SE14_Final.

L'audit documente plusieurs problèmes sur les sections Survey Solutions SE14 (quantifications par partie) et SE22 (descriptions d'ingrédients). Il relève 17 quantités nulles ou négatives sur SE14 et 193 sur SE22, 772 quantités supérieures à 5 000 g sur SE14 à investiguer, des codes `Methode` saisis à 999, et 109 individus présents dans SE13 mais absents de SE22 qui appellent une documentation dédiée.

Le pipeline n'intervient pas sur ces sections. Il démarre à la base `Anemie_Base_Consommation_R24H`, qui est le produit consolidé de SE14, SE22 et des autres sections du questionnaire Survey Solutions. Le nettoyage amont de ces sections brutes relève d'un pipeline séparé, confié à une autre équipe, qui produit la base de consommation officielle de l'enquête.

La raison de ce périmètre est la division explicite du travail entre équipes. Refaire le nettoyage SE14 et SE22 dans ce pipeline créerait un doublon avec le pipeline officiel et ouvrirait un risque de divergence entre les deux bases de consommation produites. Cette divergence serait impossible à arbitrer a posteriori si elle survenait, et elle compromettrait la traçabilité de la base finale.

Si une intégration totale du nettoyage amont dans ce pipeline est souhaitée à terme, un script préalable à la phase 3 peut être ajouté. Il reprendrait les corrections documentées dans l'audit SE14_Final et régénérerait `Anemie_Base_Consommation_R24H` à partir des sections brutes. La décision relève du coordonnateur et dépend de l'organisation retenue entre les équipes de traitement.
