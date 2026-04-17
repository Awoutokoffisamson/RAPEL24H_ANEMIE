# Phase 4. Harmonisation des poids et reconstruction des quantités via recettes

**Projet** : Étude consommation alimentaire et anémie, adolescents Sénégal
**Auteur** : Awouto Koffi Samson
**Date** : avril 2026

## Pourquoi cette phase

La base de consommation brute porte les quantités déclarées par l'adolescent lors du rappel 24h. Ces quantités sont souvent grossières pour les ingrédients pris dans un plat composé. Typiquement, quelqu'un ne déclare pas spontanément 35 g d'oignon dans son tiep, il déclare une portion de tiep. La Phase 4 reconstruit les quantités ingrédient par ingrédient en s'appuyant sur les recettes ménage (BF et BI) collectées en parallèle, et sur les recettes standards régionales (RST) ou moyennes (RM) quand la recette ménage n'est pas disponible.

## Hiérarchie de reconstruction

Pour chaque ligne de consommation, on cherche la meilleure source dans cet ordre.

1. Recette ménage (BF ou BI) si le ménage a renseigné le plat concerné. Priorité BF sur BI si les deux existent.
2. Recette standard régionale (RST) sinon.
3. Recette moyenne nationale (RM) en dernier recours.
4. Quantité brute déclarée si aucune recette ne colle, le plat étant alors considéré comme un ingrédient isolé.

La colonne `Source_Recette` de la base finale conserve cette information, ce qui permet d'analyser après coup la fiabilité des apports selon la source utilisée.

## Formule retenue

Pour les recettes ménage, la quantité reconstruite est `Quantite_Ingredient_g = Quantite_Grams_Pl × Pourcentage_Ing`, où `Pourcentage_Ing` est la proportion pondérale de l'ingrédient dans le plat (valeur entre 0 et 1).

Pour les recettes standards et moyennes, on n'a pas de `Quantite_Grams_Pl` par ménage. On remplace par la quantité de plat déclarée par l'adolescent : `Quantite_Ingredient_g = Quantite_Plat × Pourcentage_Ing`.

## Ce qui sort

`Base_Conso_Apuree_P4.dta` : 66 784 lignes, soit une ligne par combinaison (individu × plat × ingrédient). Chaque ligne porte la quantité reconstruite `Quantite_Ingredient_g`, la source de recette utilisée, et toutes les variables originales conservées pour traçabilité.

`Base_Facteurs_Master.dta` : table consolidée des facteurs de conversion utilisés, issus de l'apurement en Phase 3.

## Chiffres clés de la reconstruction

- 99,85 % des lignes couvertes par une recette ménage (66 682 lignes)
- 0,04 % via recette standard régionale (25 lignes)
- 0 % via recette moyenne nationale
- 0,12 % non appariées, quantité brute conservée (77 lignes)

La couverture ménage est exceptionnellement élevée, ce qui signifie que l'effort de collecte des recettes en parallèle du rappel 24h a payé. C'est la situation la plus favorable possible pour ce type d'enquête.

## Écart par rapport à l'audit

La clé de jointure côté consommation est `Interview__key × Code_Plat × Code_Ingredient`, alors que l'audit suggère d'inclure `Numero_Rappel` et `Code_Repas` dans la clé d'analyse. Le choix vient du fait que les recettes ménage sont indexées par `Household × Code_Plat × Code_Ingredient`, sans dimension rappel ni repas. Appliquer la même recette aux deux rappels d'un individu est donc la bonne sémantique. Un contrôle ciblé des rares cas où deux recettes différentes coexistent pour un même plat dans un ménage reste à mener. Détail dans `Ecarts_Methodologiques_vs_Audits.md`.

## Limites connues

La reconstruction ménage suppose que la recette du plat est stable dans le temps pour un ménage donné. Si le plat a été préparé différemment entre deux rappels, la recette unique qu'on applique lisse cette variation. Impact probablement faible mais non chiffré ici.

Les 77 lignes non appariées gardent la quantité brute. Ces lignes ne sont pas représentatives d'un repas composé et leur apport peut être moins précis. Elles ne pèsent pas lourd dans les statistiques finales.
