# 00_raw_data

Dossier des bases sources brutes du rappel 24 heures. Les cinq fichiers attendus ne sont pas versionnés dans le dépôt pour des raisons de confidentialité des données individuelles.

Avant de lancer `00_MASTER.do`, place les fichiers suivants à la racine de ce dossier :

- `Anemie_Base_Consommation_R24H.dta`
- `Base_CONSOMMATION_RECETTES_BF.dta`
- `Base_CONSOMMATION_RECETTES_BI.dta`
- `Base_Recettes_RST.dta`
- `BASE_RECETTES_MOYENNES.dta`

Ces fichiers sont à demander au coordonnateur de l'enquête. Aucune transformation préalable n'est requise, les scripts du pipeline s'en chargent.

Vérification rapide après dépôt :

```
do Phase_3_Corrections_Critiques/scripts/00_diagnostic_variables.do
```

Ce script affiche la structure des cinq bases et sert de contrôle de bonne mise en place.
