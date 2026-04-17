# Phase 7. Indicateurs nutritionnels et agrégation finale

**Projet** : Étude consommation alimentaire et anémie, adolescents Sénégal
**Auteur** : Awouto Koffi Samson
**Date** : avril 2026

## Pourquoi cette phase

Dernière étape du pipeline. Elle prend la base validée de Phase 6 (une ligne par individu × rappel × ingrédient) et produit la base d'analyse finale, avec une ligne par rappel, enrichie des totaux journaliers, des parts de consommation par source de recette, et des indicateurs de carence.

C'est cette base qui sert de support à toutes les analyses en aval.

## Ce que fait le script

Quatre étapes.

D'abord, labellisation des 14 régions du Sénégal pour que les tableaux soient lisibles sans dictionnaire de codes.

Ensuite, décomposition des apports par source de recette. Avant l'agrégation, on crée quatre variables intermédiaires (`kcal_menage`, `kcal_rst`, `kcal_rm`, `kcal_non_apparie`). Chacune ne prend la valeur de `CALORIES` que si la ligne provient de la source correspondante. L'agrégation qui suit additionne chaque source séparément, ce qui donne pour chaque individu la part des calories issues d'une recette ménage, standard, moyenne ou non appariée. Cette décomposition permet d'évaluer la fiabilité du rappel individu par individu.

Troisième étape, l'agrégation journalière proprement dite. Le `collapse` produit une ligne par `(Interview__key × Numero_Rappel)`. Les nutriments sont sommés, les caractéristiques individuelles (âge, sexe, région, quintile de niveau de vie, poids de sondage) sont récupérées puisqu'elles sont constantes à l'intérieur d'un groupe.

Enfin, construction des flags de carence.

## Indicateurs de carence

Quatre flags binaires construits à partir des seuils EAR (Estimated Average Requirement) de l'OMS et de la FAO.

| Indicateur | Seuil | Source |
|---|---|---|
| Carence fer | Total_Fer < 10,5 mg/j | EAR OMS adolescent, biodisponibilité 10 % régime mixte Afrique de l'Ouest |
| Carence zinc | Total_Zinc < 7 mg/j | EAR OMS adolescent, biodisponibilité moyenne |
| Insuffisance protéique | Total_Protein < 34 g/j | FAO, adolescent 10-14 ans |
| Insuffisance calorique | Total_KCAL < 1 800 kcal/j | Plancher plausible pour un adolescent faiblement actif |

Ces seuils sont uniformes. Ils ne différencient pas par âge ni par sexe, ce qui reste un choix simplificateur. Pour une analyse plus fine, l'idée est d'appliquer des seuils spécifiques par tranche, ce qui demande une table de référence complète.

## Parts de consommation par source

Pour chaque rappel : `Part_Kcal_X = Kcal_X / Total_KCAL × 100` pour les quatre sources. Ces variables servent à qualifier la qualité du rappel et à tester la sensibilité des indicateurs à l'origine des recettes.

## Contrôle final pondéré

Le script termine par un `svyset` sur `HH_Sample_Weight` et un `svy: mean Total_Fer, over(Milieu_Residence)`. C'est un contrôle minimal qui vérifie que la base finale permet bien les estimations pondérées attendues.

## Ce qui sort

`BASE_ANALYSE_FINALE_ANEMIE_P7.dta`, aussi livrée sous le nom `Base_Analyse_Anemie_Finale.dta`. 1 682 rappels, 32 variables.

Variables principales :

- Totaux journaliers : `Total_KCAL`, `Total_Fer`, `Total_Zinc`, `Total_Protein`, `Total_Lipides`, `Total_Glucides`, `Total_VitC`
- Parts par source : `Part_Kcal_Menage`, `Part_Kcal_RST`, `Part_Kcal_RM`, `Part_Kcal_NonApp`
- Flags de carence : `carence_Fer`, `carence_Zinc`, `carence_Protein`, `faim_Kcal`
- Caractéristiques individu : `Age_Ans`, `Sexe`, `Region`, `Milieu_Residence`, `Quintil_Niveau_Vie`, `HH_Sample_Weight`

## Écart par rapport à l'audit

L'audit recommande le calcul du Mean Adequacy Ratio et des Nutrient Adequacy Ratios contre les Besoins Nutritionnels Recommandés. Le pipeline se limite aux flags binaires de carence. Justification dans `Ecarts_Methodologiques_vs_Audits.md`.

## Limites connues

Les seuils EAR uniformes sur-estiment la carence pour les plus jeunes et la sous-estiment pour les adolescents en fin de croissance.

La base repose sur un rappel unique 24h par individu pour la majorité de l'échantillon. Un rappel unique capture la consommation d'un jour donné, pas la consommation habituelle. La prévalence de carence calculée ainsi sur-estime la vraie prévalence. Les méthodes d'estimation de distribution habituelle (Iowa State, SPADE) demandent des rappels répétés qui ne sont pas disponibles sur l'ensemble de l'échantillon.

Si un rappel a `Total_KCAL = 0`, les parts par source sont indéfinies. Ce cas est rare mais non filtré. À vérifier à l'analyse.
