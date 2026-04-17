* Phase 5 - Script 01 : Reconstruction de la table de composition nutritionnelle
* Retro-calcul des teneurs pour 100g par Code_Ingredient a partir des couples
* (quantite brute, apport nutritionnel) observes dans la base de consommation.
version 16
set more off

if ("${PROJET_DIR}" == "") {
    disp as error "ERREUR : Lancez 00_MASTER.do"
    exit 1
}

global in_p4    "${PROJET_DIR}/Phase_4_Apurement/sorties"
global out_p5   "${PROJET_DIR}/Phase_5_Reconstruction/sorties"

use "${in_p4}/Base_Conso_Apuree_P4.dta", clear

* Filtre des lignes exploitables pour le retro-calcul
drop if missing(Quantite_Ingredient) | Quantite_Ingredient <= 0

* Teneur pour 100g par nutriment : (apport / quantite) * 100
local nutri "CALORIES Ingere_Fer Ingere_Zinc Ingere_Protein Ingere_Lipides Ingere_Glucides Ingere_VitaminC"
foreach v of local nutri {
    gen double Teneur_100g_`v' = (`v' / Quantite_Ingredient) * 100 if !missing(`v')
}

* Moyenne par ingredient pour neutraliser bruit de saisie et labels variants
collapse (mean) Teneur_100g_* (firstnm) Label_Ingredient, by(Code_Ingredient)

save "${out_p5}/Table_Composition_Reconstruite.dta", replace
