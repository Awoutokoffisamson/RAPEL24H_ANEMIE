# Note Méthodologique - Phase 4 : Reconstruction des quantités par ingrédient

**Projet** : Étude sur la consommation alimentaire et l'anémie chez les adolescents (Sénégal)
**Scripts** : `traitement/Phase_4_Apurement/scripts/`
**Auteur** : AWOUTO Koffi Samson
**Date de mise à jour** : avril 2026

---

## Objectif

La Phase 4 prend les bases nettoyées de la Phase 3 et produit une seule base finale (`Base_Conso_Apuree_P4.dta`) qui associe à chaque ligne de consommation individuelle la quantité en grammes de l'ingrédient concerné. C'est cette base que la Phase 5 exploitera pour calculer les apports nutritionnels via FOOD_COMPO.

Trois scripts s'exécutent dans l'ordre : corrections des codes, construction du référentiel de facteurs de conversion, puis reconstruction des quantités.

---

## Script 01 : Corrections des codes ingrédients

La base de consommation brute contient des codes ingrédients absents des référentiels nutritionnels. Ces orphelins viennent soit de saisies typographiques, soit de spécifications trop fines sans valeur nutritionnelle propre dans les tables.

La stratégie est le réalignement par proximité : on remplace le code orphelin par le code valide le plus proche biologiquement.

| Code orphelin | Label | Code substitut | Label substitut | Justification |
|---|---|---|---|---|
| 107139 | Poulet cuisse | 107027 | Poulet | Même matrice, composition quasi identique |
| 109201 | Poisson Thilé | 109114 | Poisson (sans précision) | Espèce locale non répertoriée |
| 3064 | Nokoss moulu | 3001 | Ail | Mélange à base d'ail, densité nutritionnelle similaire |
| 107138 | Corned beef | 107038 | Boeuf conservé | Même catégorie industrielle |
| 201147 | Madeleine | 101004 | Biscuit sec | Produit de boulangerie, profil glucidique comparable |

Deux codes sont exclus car les quantités associées (inférieur à 1g) traduisent une erreur de saisie d'unité de mesure.

---

## Script 02 : Référentiel des facteurs de conversion

Les facteurs de conversion permettent de passer d'une unité ménagère (louche, bol, unité) à des grammes. Le fichier source `Base_Fac_Aliment_VF.xlsx` contient deux feuilles fusionnées : `Aliment_UT` et `Ingredient_UT`.

En cas de doublons sur `(Code_Ingredient, UMesure, UTaille)`, on conserve la ligne avec l'effectif le plus élevé, soit le facteur mesuré sur le plus grand nombre de pesées.

Ce référentiel est produit ici pour usage futur. En Phase 4, il n'est pas encore appliqué directement car les recettes ménage (BF/BI) fournissent déjà des quantités en grammes via `Quantite_Grams_Pl`.

---

## Script 03 : Reconstruction des quantités

C'est le script central de la phase. Il joint la base de consommation corrigée aux bases de recettes dans un ordre de priorité strict, puis calcule `Quantite_Ingredient_g` pour chaque ligne.

### Ordre de priorité des sources

La hiérarchie suit la spécificité de l'information : une recette déclarée par le ménage enquêté est toujours préférable à une recette standard nationale.

1. **MENAGE (BF puis BI)** : recettes déclarées par le ménage au moment de l'enquête. BF est prioritaire sur BI quand les deux existent pour le même ménage × plat × ingrédient.
2. **RST** : recettes standard nationales.
3. **RM** : recettes moyennes, calculées par agrégation sur l'ensemble des ménages.
4. **NON_APPARIE** : aucune recette disponible, la quantité originale de la base de consommation est conservée.

### Logique de jointure

Les recettes (BF, BI, RST, RM) utilisent `Idd_Aliment_Rec` et `Idd_Ingredient` comme clés. La consommation utilise `Code_Plat` et `Code_Ingredient`. Ces codes sont identiques en valeur, les noms de variables seuls diffèrent. Le script renomme les clés des recettes avant la jointure.

BF et BI sont fusionnées en une seule référence ménage avant le premier merge, avec BF prioritaire. La jointure ménage se fait sur trois clés : `Interview__key × Code_Plat × Code_Ingredient`, ce qui garantit que chaque individu obtient sa propre recette et non une recette générique.

Les jointures RST et RM utilisent le merge `update` de Stata : seules les lignes encore sans proportion sont renseignées. Les lignes déjà appariées avec une recette ménage ne sont jamais écrasées.

### Formule de calcul selon la source

| Source | Formule | Explication |
|---|---|---|
| MENAGE | `QGrams_Pl × Pct_Ing` | `QGrams_Pl` est le poids déclaré du plat en grammes, issu de la recette ménage |
| RST / RM | `Quantite_Plat × Pct_Ing` | `Quantite_Plat` est la portion déclarée du plat, supposée en grammes |
| NON_APPARIE | `Quantite_Ingredient` | Valeur directe de la base de consommation, sans recalcul |

### Sortie produite

`Base_Conso_Apuree_P4.dta` : une ligne par `Interview__key × Numero_Rappel × Code_Repas × Code_Plat × Code_Ingredient`, avec :

- `Quantite_Ingredient_g` : quantité de l'ingrédient en grammes
- `Source_Recette` : origine de la donnée (MENAGE / RST / RM / NON_APPARIE)

---

## Limites connues

**Recettes RM et clé ingrédient.** La base RM utilise `Ids_Ingredient`, qui peut différer de `Code_Ingredient` dans la consommation. Les appariements via RM doivent être vérifiés à l'exécution.

**Lignes NON_APPARIE.** Elles conservent `Quantite_Ingredient` de la base brute. Si cette valeur n'est pas en grammes, le calcul nutritionnel en Phase 5 sera incorrect. Ces cas méritent un audit.

**Facteurs de conversion.** Pour les lignes RST/RM, la formule suppose que `Quantite_Plat` est déjà en grammes. Si ce n'est pas le cas, `Base_Facteurs_Master.dta` devra être intégré en Phase 5.
