# Note Méthodologique - Phase 3 : Nettoyage et Apurement des Bases Sources

**Projet** : Étude sur la consommation alimentaire et l'anémie chez les adolescents (Sénégal)
**Script** : `traitement/Phase_3_Corrections_Critiques/scripts/01_nettoyage.do`
**Auteur** : AWOUTO Koffi Samson
**Date de mise à jour** : avril 2026

---

## Pourquoi cette phase existe

Avant de calculer le moindre apport nutritionnel, il faut s'assurer que les cinq bases sources disent la même chose, au même format, sans lignes parasites. C'est exactement ce que fait cette phase.

Elle ne produit aucune valeur nutritionnelle. Elle ne modifie pas les données de fond. Elle nettoie, standardise, déduplique, et sauvegarde. Tout le reste vient après.

Les cinq bases traitées ici sont :
- `Anemie_Base_Consommation_R24H (3).dta` : les déclarations individuelles de consommation (68 667 lignes brutes)
- `Base_CONSOMMATION_RECETTES_BF.dta` : recettes ménage de type BF (68 933 lignes brutes)
- `Base_CONSOMMATION_RECETTES_BI.dta` : recettes ménage de type BI (83 979 lignes brutes)
- `Base_Recettes_RST.dta` : recettes standard
- `BASE_RECETTES_MOYENNES.dta` : recettes moyennes, utilisées en dernier recours

---

## Section A : Base de consommation R24H

### A1. Standardisation des types de variables

Les clés de jointure (`Interview__key`, `Code_Plat`, `Code_Ingredient`) posent un problème classique dans Stata : selon le fichier source, la même variable peut être numérique dans l'un et string dans l'autre. Si on tente un `merge` dans cet état, Stata rejette l'opération sans message clair.

La correction est simple : on convertit systématiquement ces trois variables en string en début de script, avec `tostring` et un `trim()` pour supprimer les espaces parasites. Le bloc `capture confirm string variable` évite de déclencher une erreur si la variable est déjà au bon format.

### A2. Imputations ciblées sur le Fer

L'audit initial a compté 4 062 valeurs manquantes sur `Ingere_Fer`. C'est beaucoup, mais toutes ne méritent pas le même traitement.

Deux catégories ont une réponse claire et documentée :

**Le sel** : par nature, le sel de cuisine n'apporte pas de Fer. La valeur manquante ne traduit pas une absence de données mais une absence réelle de l'apport. On impute donc 0, et seulement pour les lignes où `Label_Ingredient` contient "sel".

**Le concentré de tomate** : certaines marques locales ne figurent dans aucun référentiel. Pour ces lignes, on applique 3,5 mg / 100g, soit la valeur médiane des tables CIQUAL 2024 et USDA FoodData Central pour le double concentré de tomate. La formule retenue est `Ingere_Fer = (Quantite_Ingredient / 100) * 3.5`.

Pour tout le reste des manquants (riz mélangé, produits industriels non renseignés, etc.), les valeurs restent manquantes. C'est intentionnel. La Phase 5 les couvrira à partir de FOOD_COMPO. Une imputation aveugle par 0 sur tous les nutriments manquants est explicitement écartée : elle gonflerait artificiellement les apports totaux et masquerait les individus qui ont réellement des données incomplètes.

### A3. Traitement des resservies (doublons fonctionnels)

L'audit a identifié 1 865 observations avec une clé dupliquée. Ce ne sont pas des erreurs de saisie : ce sont des portions déclarées en plusieurs fois par le même individu pour le même ingrédient du même plat au même repas. On appelle ça des "resservies".

La clé naturelle retenue est : `Interview__key × Numero_Rappel × Code_Repas × Code_Plat × Code_Ingredient`.

Elle exclut délibérément `Label_Repas`, `Label_Plat` et `Label_Ingredient`. Si ces labels textuels avaient été inclus, une simple variation d'orthographe ("Thiébou dieune" vs "Thiéboudienne") aurait empêché la fusion de lignes qui représentent pourtant le même aliment.

Pour fusionner les resservies, on additionne les quantités et les nutriments pré-calculés (`collapse sum`). Mais le `collapse(sum)` de Stata a un comportement particulier : si toutes les lignes d'un groupe sont manquantes pour une variable, il renvoie 0 plutôt que manquant. Ce 0 serait une fabrication.

Pour éviter ça, on crée un flag binaire avant le collapse pour chaque nutriment :

```stata
gen byte _flag_Ingere_Fer = missing(Ingere_Fer)
```

Après le collapse, on prend le minimum de ce flag par groupe. Si ce minimum vaut 1, cela signifie que toutes les lignes originales étaient manquantes. On restaure alors la valeur manquante :

```stata
replace Ingere_Fer = . if _flag_Ingere_Fer == 1
drop _flag_Ingere_Fer
```

Les variables non-nutritionnelles (caractéristiques socio-démographiques, labels textuels) sont récupérées avec `(first)` : une seule occurrence suffit.

---

## Section B : Table clé individu-rappel

À partir de la base conso apurée, on extrait une table à une ligne par `(Interview__key × Numero_Rappel)` qui regroupe toutes les caractéristiques de l'individu : région, milieu de résidence, sexe, âge, poids de sondage, etc.

Cette table (`cle_rappel.dta`) servira de référence dans toutes les phases suivantes pour les jointures et les calculs agrégés par individu. La construire une seule fois en Phase 3 évite de la recalculer différemment dans chaque script.

---

## Section C et D : Recettes ménage BF et BI

Ces deux bases partagent la même structure et les mêmes problèmes.

### La variable Quantite_Grams_Pl

C'est le poids total du plat en grammes, variable centrale pour la reconstruction des quantités par ingrédient en Phase 4.

### L'échelle de Pourcentage_Ing

L'audit initial a mesuré une médiane à 0,0191. C'est une proportion entre 0 et 1, pas un pourcentage entre 0 et 100. La formule de reconstruction des quantités individuelles à appliquer en Phase 4 est donc :

```
Quantite_Ingredient_grammes = Quantite_Grams_Pl × Pourcentage_Ing
```

et non pas `Quantite_Grams_Pl × Pourcentage_Ing / 100`. Le script vérifie la médiane à l'exécution et émet une alerte si elle dépasse 1, ce qui signalerait un changement d'échelle inattendu dans les données sources.

### Déduplication

La clé naturelle pour les recettes est `Code_Plat × Code_Ingredient`. Les doublons sont des cas où la même recette a été saisie plusieurs fois, probablement lors de plusieurs passages d'enquête dans le même ménage. On prend la moyenne des valeurs numériques pour neutraliser les micro-variations, et le premier label non-manquant pour les variables textuelles.

---

## Sections E et F : Recettes standard (RST) et moyennes (RM)

Ces deux bases servent de recours lorsqu'aucune recette ménage n'est disponible pour un plat donné. Elles sont moins précises que BF/BI parce qu'elles ne sont pas collectées spécifiquement pour ce ménage, mais elles permettent de couvrir davantage d'individus plutôt que de les exclure faute de données.

Le traitement appliqué est identique aux recettes ménage : standardisation des clés de jointure, suppression des lignes sans quantité utilisable, déduplication sur `Code_Plat × Code_Ingredient`. Le collapse pour RST et RM est construit dynamiquement à partir des types de variables détectés, ce qui le rend robuste aux variations de structure entre les deux bases.

---

## Ce que cette phase ne fait pas

Quelques clarifications importantes sur le périmètre de la Phase 3 :

**Elle ne calcule pas de nutriments.** Les valeurs `CALORIES`, `Ingere_Fer`, etc. présentes dans la base conso sont conservées telles quelles pour référence. Elles ne sont pas utilisées dans les calculs finaux. La reconstruction nutritionnelle propre se fait en Phase 5 à partir de FOOD_COMPO et des quantités issues des recettes.

**Elle ne joint pas les bases entre elles.** La jointure entre la conso et les recettes ménage, puis avec les recettes standard, est le travail de la Phase 4.

**Elle ne touche pas aux facteurs de conversion.** Ces facteurs (qui permettent de passer d'une unité de mesure ménagère comme "une louche" à des grammes) sont traités en Phase 4.

---

## Sorties produites

| Fichier | Contenu | Utilisation |
|---|---|---|
| `conso_clean.dta` | Consommation individuelle apurée, clé unique | Point d'entrée Phase 4 |
| `cle_rappel.dta` | Une ligne par individu × rappel avec variables socio-démo | Jointures Phases 5-7 |
| `recette_BF_clean.dta` | Recettes ménage BF dédupliquées | Reconstruction Phase 4 |
| `recette_BI_clean.dta` | Recettes ménage BI dédupliquées | Reconstruction Phase 4 |
| `recette_RST_clean.dta` | Recettes standard dédupliquées | Recours Phase 4 |
| `recette_RM_clean.dta` | Recettes moyennes dédupliquées | Dernier recours Phase 4 |

---

## Problèmes connus et limites

**Manquants résiduels sur Ingere_Fer.** Après les imputations ciblées (sel et concentré de tomate), il reste des valeurs manquantes sur ce nutriment pour des produits industriels non référencés. Ces lignes ne sont pas supprimées. Elles restent dans la base et seront traitées en Phase 5.

**Collapse et valeurs manquantes.** La solution par flags préserve correctement le statut manquant après déduplication pour les groupes entièrement manquants. En revanche, si un groupe a une observation valide et une observation manquante, le sum Stata renvoie la valeur valide, ce qui est le comportement attendu.

**RST et RM : noms de variables non garantis.** La structure de ces deux bases peut varier légèrement selon la version du fichier source. Le script signale les cas ambigus dans la console Stata mais ne bloque pas l'exécution.
