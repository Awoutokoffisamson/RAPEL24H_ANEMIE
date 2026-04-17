# RAPEL24H_ANEMIE, pipeline de traitement

Chaîne Stata qui transforme les bases brutes du rappel 24 heures en une base d'analyse prête pour les modèles d'anémie chez les adolescents sénégalais.

## Prérequis

Stata 16 ou plus récent. Aucune dépendance externe.

## Lancement

Depuis un terminal Stata ou le menu `File -> Do`, placez-vous dans ce dossier puis exécutez le maître :

```
cd "chemin/vers/traitement"
do 00_MASTER.do
```

Le script détecte automatiquement le dossier projet via `c(pwd)`. Tous les chemins sont relatifs, rien à configurer.

La variable `PHASE_MAX` dans `00_MASTER.do` permet de limiter l'exécution à une phase donnée, utile pendant le développement.

## Architecture

Sept phases, enchaînées par le maître.

| Phase | Dossier | Rôle |
|---|---|---|
| 3 | `Phase_3_Corrections_Critiques/` | Nettoyage des bases sources, imputations ciblées, harmonisation des clés |
| 4 | `Phase_4_Apurement/` | Consolidation des référentiels recettes et facteurs, reconstruction des quantités par ingrédient |
| 5 | `Phase_5_Reconstruction/` | Table de composition reconstruite par rétro-calcul, recalcul des apports |
| 6 | `Phase_6_Validation_Nutritionnelle/` | Exclusion des rappels implausibles (seuils kcal et fer) |
| 7 | `Phase_7_Indicateurs/` | Agrégation journalière, parts par source, indicateurs de carence |

Chaque phase contient un sous-dossier `scripts/` et un sous-dossier `sorties/`.

## Données d'entrée

Pour des raisons de confidentialité des données individuelles, les cinq bases sources ne sont pas versionnées dans ce dépôt. Le dossier `00_raw_data/` est présent mais vide à la récupération. Avant tout lancement, il faut s'y procurer les cinq fichiers suivants auprès du coordonnateur de l'enquête et les déposer à cet emplacement, sans modifier les noms.

| Fichier attendu dans `00_raw_data/` | Contenu |
|---|---|
| `Anemie_Base_Consommation_R24H.dta` | Base de consommation brute du rappel 24 heures, toutes sections consolidées |
| `Base_CONSOMMATION_RECETTES_BF.dta` | Recettes ménage, base finale (priorité 1 dans la jointure Phase 4) |
| `Base_CONSOMMATION_RECETTES_BI.dta` | Recettes ménage, base intermédiaire (priorité 2) |
| `Base_Recettes_RST.dta` | Recettes standard nationales (priorité 3) |
| `BASE_RECETTES_MOYENNES.dta` | Recettes moyennes par groupe (priorité 4, filet de sécurité) |

Les référentiels Excel des facteurs de conversion sont en revanche versionnés dans `Phase_3_Corrections_Critiques/base_de_donnees/Bases_Facteurs conversion/`. Rien à faire de ce côté.

Le script `Phase_3_Corrections_Critiques/scripts/00_diagnostic_variables.do` permet de vérifier rapidement que les cinq bases sont bien en place et lisibles par Stata avant de lancer le pipeline complet.

## Livrables

`01_LIVRABLE_FINAL_COORDONNATEUR/` regroupe la base d'analyse finale, la documentation méthodologique et le rapport de synthèse. Point d'entrée : `Rapport_Synthese_Technique.md`.

`LIVRABLES_INTERMEDIAIRES/` contient les bases de phase 4 à 6 pour audit ou réutilisation.

## Auteur

Awouto Koffi Samson, avril 2026.
