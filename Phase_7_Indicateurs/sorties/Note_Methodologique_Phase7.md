# Note Méthodologique - Phase 7 : Indicateurs nutritionnels et agrégation finale

**Projet** : Étude sur la consommation alimentaire et l'anémie chez les adolescents (Sénégal)
**Script** : `traitement/Phase_7_Indicateurs/scripts/01_indicateurs_aggreges.do`
**Auteur** : AWOUTO Koffi Samson
**Date de mise à jour** : avril 2026

---

## Objectif

Phase terminale du pipeline. Elle prend la base validée de Phase 6 (une ligne par individu × rappel × ingrédient) et produit la base d'analyse finale avec une ligne par rappel, enrichie des totaux journaliers, des parts de consommation par source de recette, et des indicateurs de carence.

C'est cette base qui sert pour toutes les analyses statistiques du projet : prévalence de carence, différenciations régionales ou par sexe, régressions, modélisations d'anémie.

---

## Étapes du script

### 1. Labellisation des régions

Les 14 régions du Sénégal sont étiquetées pour que les tableaux et graphiques produits en aval soient lisibles sans dictionnaire de codes.

### 2. Décomposition des apports par source de recette

Avant l'agrégation, on créé quatre variables intermédiaires (`kcal_menage`, `kcal_rst`, `kcal_rm`, `kcal_non_apparie`). Chacune reprend la valeur de `CALORIES` uniquement quand la ligne provient de la source correspondante, manquant sinon. Le `collapse (sum)` qui suit additionne chaque source séparément, ce qui donne au final pour chaque individu la part des calories qui proviennent d'une recette ménage, standard, moyenne ou non appariée.

Cette décomposition permet de qualifier la fiabilité du rappel individu par individu : un rappel avec 100 % des calories en `MENAGE` est plus précis qu'un rappel qui repose à 80 % sur une recette moyenne.

### 3. Agrégation journalière

Le `collapse` produit une ligne par `(Interview__key × Numero_Rappel)`. Les variables nutritionnelles sont sommées (apports totaux sur la journée), les caractéristiques individuelles (âge, sexe, région, quintile de niveau de vie, poids de sondage) sont récupérées via `(first)` puisqu'elles sont constantes dans le groupe.

### 4. Indicateurs de carence

Quatre flags binaires construits à partir des seuils EAR (Estimated Average Requirement) de l'OMS et de la FAO.

| Indicateur | Seuil | Source |
|---|---|---|
| Carence en fer | < 10,5 mg/j | EAR OMS adolescent, avec biodisponibilité 10 % (régime mixte Afrique de l'Ouest) |
| Carence en zinc | < 7 mg/j | EAR OMS adolescent, biodisponibilité moyenne |
| Insuffisance protéique | < 34 g/j | FAO, adolescent 10-14 ans |
| Insuffisance calorique | < 1 800 kcal/j | Borne basse plausible pour un adolescent faiblement actif |

Ces seuils sont volontairement uniformes (pas de différenciation âge/sexe) pour une première lecture. Une sophistication possible consiste à appliquer les seuils spécifiques par tranche d'âge et par sexe, ce qui nécessite une table de référence complète.

### 5. Parts de consommation par source

Pour chaque rappel, on calcule `Part_Kcal_X = Kcal_X / Total_KCAL × 100` pour les quatre sources. Ces variables servent à qualifier la qualité du rappel et à tester la sensibilité des indicateurs à la source des recettes.

### 6. Contrôle final pondéré

Le script se termine par un `svyset` sur le poids de sondage `HH_Sample_Weight` et un `svy: mean Total_Fer, over(Milieu_Residence)`. C'est un contrôle minimal pour vérifier que la base finale permet bien les estimations pondérées attendues.

---

## Sortie produite

`BASE_ANALYSE_FINALE_ANEMIE_P7.dta` : une ligne par `(Interview__key × Numero_Rappel)`.

Variables principales :
- Totaux journaliers : `Total_KCAL`, `Total_Fer`, `Total_Zinc`, `Total_Protein`, `Total_Lipides`, `Total_Glucides`, `Total_VitC`
- Parts par source : `Part_Kcal_Menage`, `Part_Kcal_RST`, `Part_Kcal_RM`, `Part_Kcal_NonApp`
- Flags de carence : `carence_Fer`, `carence_Zinc`, `carence_Protein`, `faim_Kcal`
- Caractéristiques : `Age_Ans`, `Sexe`, `Region`, `Milieu_Residence`, `Quintil_Niveau_Vie`, `HH_Sample_Weight`

---

## Limites connues

**Seuils EAR uniformes.** Les seuils utilisés ignorent les variations âge-sexe. Ils fournissent un ordre de grandeur correct pour les adolescents ouest-africains mais sur-estiment la carence pour les plus jeunes et la sous-estiment pour les grands adolescents en fin de croissance.

**Rappel unique vs habitudes.** Un seul rappel 24h par individu dans cette base capture la consommation d'un jour donné, pas la consommation habituelle. La prévalence de carence calculée à partir de cette base sur-estime donc la vraie prévalence. Les méthodes de Iowa State ou SPADE (estimation de distribution de consommation habituelle à partir de rappels répétés) ne sont pas appliquées ici faute de second rappel pour une partie des individus.

**Part_Kcal_* et division par zéro.** Si un rappel a `Total_KCAL = 0` (rare mais possible si toutes les lignes ont des nutriments manquants), les parts sont indéfinies. Ce cas n'est pas filtré ici, à vérifier à l'analyse.
