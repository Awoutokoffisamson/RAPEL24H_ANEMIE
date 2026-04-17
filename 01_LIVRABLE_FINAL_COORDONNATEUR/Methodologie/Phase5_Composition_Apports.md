# Phase 5. Composition nutritionnelle et recalcul des apports

**Projet** : Étude consommation alimentaire et anémie, adolescents Sénégal
**Auteur** : Awouto Koffi Samson
**Date** : avril 2026

## Pourquoi cette phase

À la sortie de la Phase 4, chaque ligne de consommation porte une quantité reconstruite (`Quantite_Ingredient_g`) qui peut différer significativement de la quantité brute déclarée. Les apports nutritionnels déjà présents dans la base source ont été calculés à partir des quantités brutes. Pour rester cohérent, il faut les recalculer en fonction des nouvelles quantités.

Deux scripts s'enchaînent. Le premier reconstruit une table de composition pour 100 grammes par ingrédient à partir des couples (quantité brute, apport) déjà observés dans la base. Le second applique cette table aux quantités reconstruites.

## Script 01. Reconstruction de la table de composition

La logique est une simple règle de trois inverse. Si une ligne donnée porte 50 g de riz et 180 kcal, alors la teneur énergétique de ce riz est de 360 kcal pour 100 g. On fait ce calcul pour chaque nutriment et chaque ligne exploitable (quantité brute strictement positive), puis on prend la moyenne par `Code_Ingredient` pour obtenir une teneur consolidée par aliment.

Les sept nutriments traités sont calories, fer, zinc, protéines, lipides, glucides, vitamine C.

La table sort à 712 ingrédients.

## Script 02. Application aux quantités reconstruites

Jointure de la base de consommation sur la table de composition par `Code_Ingredient`. Pour chaque nutriment :

`apport_final = (Quantite_Ingredient_g / 100) × Teneur_100g`

Les variables d'apport de la base source sont écrasées sur place avec ces nouvelles valeurs. La quantité brute d'origine reste dans la base sous `Quantite_Ingredient`, ce qui permet un audit ligne par ligne.

## Ce qui sort

`Table_Composition_Reconstruite.dta` : 712 ingrédients × 7 teneurs pour 100 g. Chaque ligne porte aussi le label textuel de l'ingrédient pour lecture humaine.

`Base_Consommation_FINALE_P5.dta` : structure identique à la sortie Phase 4, avec les apports nutritionnels mis à jour.

## Écart par rapport à l'audit

L'audit Consommation note que les apports sont déjà calculés dans la base source avec facteur comestible et codes de rétention intégrés, et suggère donc que le recalcul n'est pas nécessaire. Le choix du recalcul vient de la logique de Phase 4 : corriger massivement les quantités sans ajuster les apports laisserait la base incohérente. Détail et alternatives dans `Ecarts_Methodologiques_vs_Audits.md`.

## Limites connues

La moyenne par ingrédient gomme la finesse des codes de rétention. Pour un aliment dont la préparation varie fortement (cuisson longue versus cuisson courte), l'apport reconstruit perd un peu de précision. Sur 712 ingrédients, cet effet est partiellement compensé par le nombre d'observations qui entrent dans chaque moyenne.

Pour les ingrédients peu fréquents, la teneur reconstruite s'appuie sur peu d'observations et peut être instable. Aucun seuil de filtrage n'est appliqué à ce stade. Les analyses d'indicateurs en aval devront utiliser des statistiques robustes plutôt que des moyennes brutes.
