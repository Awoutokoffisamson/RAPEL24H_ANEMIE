# Note Méthodologique - Phase 6 : Validation nutritionnelle et exclusion des rappels implausibles

**Projet** : Étude sur la consommation alimentaire et l'anémie chez les adolescents (Sénégal)
**Script** : `traitement/Phase_6_Validation_Nutritionnelle/scripts/01_validation_extrems.do`
**Auteur** : AWOUTO Koffi Samson
**Date de mise à jour** : avril 2026

---

## Objectif

À ce stade, chaque ligne de consommation a un apport nutritionnel calculé. Reste à écarter les rappels journaliers dont le total agrégé n'est pas biologiquement plausible, avant tout calcul d'indicateur. La Phase 6 identifie ces cas et produit une base nettoyée.

---

## Critères de plausibilité

Les seuils retenus s'appliquent au total cumulé sur un rappel de 24h, par couple (individu × numéro de rappel).

| Variable | Seuil bas | Seuil haut | Justification |
|---|---|---|---|
| Calories totales | 800 kcal | 5 000 kcal | Intervalle standard pour adolescents en Afrique de l'Ouest, compatible avec les recommandations OMS et l'expérience des enquêtes EDS régionales |
| Fer total | aucun | 60 mg | Valeur très au-dessus de l'AMT (Apport Maximal Tolérable) OMS fixé à 40-45 mg pour les adolescents. Au-delà, l'apport relève d'une erreur de saisie ou d'un calcul parasité par une teneur aberrante |

Un rappel est exclu dès qu'il franchit l'un de ces seuils. Le filtre ne porte pas sur des lignes isolées mais bien sur l'ensemble du rappel : retirer quelques lignes extrêmes tout en gardant le rappel biaiserait la structure du repas.

---

## Logique du script

Trois étapes.

1. **Agrégation journalière** : somme des calories et du fer par `Interview__key × Numero_Rappel`. C'est le seul niveau pertinent pour juger de la plausibilité, les lignes individuelles n'ont pas de seuil de référence.

2. **Construction de la liste d'exclusion** : `Liste_Individus_Exclus.dta` contient tous les rappels qui dépassent au moins un seuil. Cette table est sauvegardée pour traçabilité : elle servira plus tard à chiffrer le taux d'exclusion et à caractériser les profils concernés (âge, sexe, région).

3. **Filtrage** : la base de consommation est jointe à la liste d'exclusion et toutes les lignes appartenant à un rappel flaggé sont retirées.

---

## Sorties produites

| Fichier | Contenu | Utilisation |
|---|---|---|
| `Liste_Individus_Exclus.dta` | Une ligne par rappel exclu, avec les totaux calculés | Audit, statistiques descriptives sur les exclusions |
| `conso_phase6_validee.dta` | Base de consommation finale utilisable pour les analyses | Entrée Phase 7 |

---

## Limites connues

**Seuils uniformes.** Les bornes 800/5000 kcal ne modulent pas par âge ou par sexe. Pour un adolescent de 10 ans, 5 000 kcal est très improbable, alors qu'un garçon de 17 ans sportif pourrait l'atteindre. Un raffinement possible consiste à utiliser des seuils ajustés sur le Basal Metabolic Rate prédit (Schofield), en rapport avec l'apport déclaré. Ce raffinement n'est pas appliqué ici.

**Exclusion totale du rappel.** Le choix est binaire : garder ou jeter. Si seul le fer est aberrant à cause d'un ingrédient mal codé, les calories restent valides mais le rappel est quand même exclu. C'est une approche conservatrice qui privilégie la cohérence sur la rétention de données.

**Pas de winsorisation.** Les valeurs extrêmes qui restent dans la base (en-dessous des seuils d'exclusion) ne sont pas tronquées. Les analyses d'indicateurs en Phase 7 devront utiliser des statistiques robustes (médiane, percentiles) plutôt que des moyennes brutes.
