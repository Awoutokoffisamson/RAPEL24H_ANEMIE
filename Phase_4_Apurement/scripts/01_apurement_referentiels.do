* Phase 4 - Script 01 : Corrections des codes ingredients
version 16
set more off

if ("${PROJET_DIR}" == "") {
    disp as error "ERREUR : Lancez 00_MASTER.do"
    exit 1
}

global out_p3 "${PROJET_DIR}/Phase_3_Corrections_Critiques/sorties/data_cleaned"
global out_p4 "${PROJET_DIR}/Phase_4_Apurement/sorties"

use "${out_p3}/conso_clean.dta", clear

* Realignement des codes orphelins (codes absents du referentiel FOOD_COMPO)
* Source : audit des non-apparies sur la base de consommation
replace Code_Ingredient = "107027" if Code_Ingredient == "107139"  // Poulet cuisse -> Poulet
replace Code_Ingredient = "109114" if Code_Ingredient == "109201"  // Poisson Thile -> Poisson
replace Code_Ingredient = "3001"   if Code_Ingredient == "3064"    // Nokoss moulu -> Ail
replace Code_Ingredient = "107038" if Code_Ingredient == "107138"  // Corned beef -> Boeuf conserve
replace Code_Ingredient = "101004" if Code_Ingredient == "201147"  // Madeleine -> Biscuit sec

* Exclusions : erreurs de saisie confirmees (quantite < 1g, biologiquement impossible)
drop if Code_Ingredient == "113198"  // Quatre epices : 0.6g total
drop if Code_Ingredient == "101178"  // Pain hamburger : 0.6g total

save "${out_p4}/conso_corrigee_p4.dta", replace
