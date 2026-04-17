# Phase 6. Validation nutritionnelle et exclusion des rappels implausibles

**Projet** : Étude consommation alimentaire et anémie, adolescents Sénégal
**Auteur** : Awouto Koffi Samson
**Date** : avril 2026

## Pourquoi cette phase

À la sortie de la Phase 5, chaque ligne a un apport nutritionnel cohérent avec la quantité reconstruite. Reste à repérer les rappels journaliers dont le total agrégé n'est pas biologiquement plausible, et à les écarter avant de calculer le moindre indicateur.

## Critères retenus

Les seuils s'appliquent au total cumulé sur 24 heures, par couple `(individu × numéro de rappel)`.

| Variable | Seuil bas | Seuil haut | Logique |
|---|---|---|---|
| Calories totales | 800 kcal | 5 000 kcal | Un rappel sous 800 kcal ou au-delà de 5 000 kcal chez un adolescent sans contexte athlétique est inexploitable |
| Fer total | aucun | 60 mg | L'Apport Maximal Tolérable OMS est à 40-45 mg. Au-delà de 60 mg, c'est presque toujours une teneur aberrante |

Un rappel est exclu dès qu'il franchit l'un de ces seuils. On ne filtre pas ligne par ligne parce que retirer quelques ingrédients extrêmes tout en conservant le rappel biaiserait la structure du repas. Soit on garde le rappel complet, soit on le jette.

## Ce qui sort

`Liste_Individus_Exclus.dta` : une ligne par rappel exclu, avec les totaux calculés. Utile pour chiffrer le taux d'exclusion et caractériser les profils concernés.

`conso_phase6_validee.dta` : base de consommation finale utilisable pour les analyses, prête pour l'agrégation de la Phase 7.

## Chiffres de l'exclusion

136 rappels exclus sur 1 818, soit 7,5 %. 61 853 lignes retenues contre 66 784 en entrée.

Sur la base validée, les totaux journaliers médians sont de 2 500 kcal, 11 mg de fer, 8,2 mg de zinc, et 60,5 g de protéines. Ces ordres de grandeur sont cohérents avec les apports observés dans les études régionales.

## Écart par rapport à l'audit

L'audit Consommation propose de flagger les rappels hors intervalle [500 ; 5 000] kcal plutôt que de les exclure, et ne fixe aucune borne sur le fer. Le pipeline applique une politique plus stricte : exclusion effective, seuil bas relevé à 800 kcal, ajout d'une borne fer à 60 mg. Justification détaillée dans `Ecarts_Methodologiques_vs_Audits.md`.

## Limites connues

Les seuils 800 et 5 000 kcal ne modulent pas par âge ou par sexe. Pour un adolescent de 10 ans, 5 000 kcal est déjà très improbable, alors qu'un garçon de 17 ans sportif pourrait l'atteindre. Un raffinement possible consiste à utiliser des seuils ajustés au Basal Metabolic Rate prédit. Cette extension n'est pas appliquée ici.

Les valeurs extrêmes qui restent dans la base (en dessous des seuils d'exclusion) ne sont pas tronquées. Les analyses d'indicateurs doivent utiliser des statistiques robustes plutôt que des moyennes brutes.
