# Note Méthodologique - Phase 5 : Reconstruction de la composition et calcul des apports

**Projet** : Étude sur la consommation alimentaire et l'anémie chez les adolescents (Sénégal)
**Scripts** : `traitement/Phase_5_Reconstruction/scripts/`
**Auteur** : AWOUTO Koffi Samson
**Date de mise à jour** : avril 2026

---

## Objectif

La Phase 5 prend les quantités reconstruites en Phase 4 (`Quantite_Ingredient_g`) et produit les apports nutritionnels individuels finaux. Deux scripts s'enchaînent : le premier reconstitue une table de composition pour 100g de chaque ingrédient à partir des données observées, le second l'applique aux quantités pour obtenir les apports par ligne de consommation.

---

## Script 01 : Reconstruction de la table de composition

La base R24H source contient, pour chaque ligne individu × plat × ingrédient, à la fois une quantité consommée (`Quantite_Ingredient`, en grammes avant correction) et les apports correspondants (`CALORIES`, `Ingere_Fer`, etc.). Ces apports ont été générés lors de la collecte par application d'une table de composition officielle. On peut donc inverser l'opération pour récupérer la table utilisée.

### Formule

Pour chaque nutriment et chaque ligne exploitable :

```
Teneur_100g = (Apport / Quantite_Ingredient) × 100
```

Les lignes avec `Quantite_Ingredient` manquant ou nul sont exclues pour éviter les divisions par zéro. Les nutriments manquants sont ignorés au cas par cas.

### Agrégation par ingrédient

Un même `Code_Ingredient` apparaît dans plusieurs milliers de lignes. On prend la moyenne des teneurs retro-calculées, ce qui neutralise les micro-arrondis introduits lors de la collecte et les éventuelles variations de label textuel pour le même code.

### Nutriments couverts

Sept variables : `CALORIES`, `Ingere_Fer`, `Ingere_Zinc`, `Ingere_Protein`, `Ingere_Lipides`, `Ingere_Glucides`, `Ingere_VitaminC`. Elles couvrent l'ensemble des analyses prévues en aval (diversité alimentaire, prévalence de carence en fer et zinc, adéquation protéique).

### Sortie

`Table_Composition_Reconstruite.dta` : une ligne par `Code_Ingredient`, sept variables `Teneur_100g_*`, plus le label de l'ingrédient pour lecture humaine.

---

## Script 02 : Application de la table aux quantités reconstruites

C'est ici qu'on passe des quantités recettes (Phase 4) aux apports nutritionnels individuels finaux.

### Logique

On joint la base apurée de Phase 4 à la table de composition par `Code_Ingredient`, puis on recalcule chaque apport :

```
Apport = (Quantite_Ingredient_g / 100) × Teneur_100g
```

La différence par rapport aux valeurs brutes de la base source vient du passage de `Quantite_Ingredient` (saisie individuelle) à `Quantite_Ingredient_g` (reconstruite à partir des recettes ménage en priorité). C'est le bénéfice direct du travail de Phase 4 : les apports sont cohérents avec le plat réellement consommé, pas avec une déclaration ingrédient par ingrédient qui pouvait être incomplète.

### Conservation des originaux

Les variables `CALORIES`, `Ingere_Fer`, etc. sont écrasées sur place avec les nouvelles valeurs. `Quantite_Ingredient` (brut) et `Quantite_Ingredient_g` (reconstruit) restent tous deux dans la base, ce qui permet un audit ligne à ligne.

### Sortie

`Base_Consommation_FINALE_P5.dta` : structure identique à la sortie Phase 4, avec apports nutritionnels recalculés.

---

## Limites connues

**Ingrédients présents dans la table mais absents de la consommation.** Les lignes dont le `Code_Ingredient` n'apparaît dans aucune consommation brute n'ont pas de teneur reconstruite et restent manquantes après le merge. En pratique, ça concerne les ingrédients des recettes ménage qui n'ont jamais été déclarés isolément dans la base R24H.

**Qualité des teneurs moyennes.** Pour un ingrédient peu fréquent, la moyenne s'appuie sur peu d'observations, donc la teneur reconstruite est moins stable. Aucun seuil de filtrage n'est appliqué ici, l'analyse de sensibilité en Phase 6 traitera les valeurs extrêmes individuelles.

**Cohérence avec la base officielle.** Les teneurs reconstruites proviennent des données de collecte. Si un contrôle qualité de la base R24H ultérieur révèle des écarts avec les tables CIQUAL ou FAO, cette Phase 5 devra être rejouée.
