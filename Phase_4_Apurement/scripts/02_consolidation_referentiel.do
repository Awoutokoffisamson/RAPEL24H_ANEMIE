* Phase 4 - Script 02 : Construction du referentiel des facteurs de conversion
version 16
set more off

if ("${PROJET_DIR}" == "") {
    disp as error "ERREUR : Lancez 00_MASTER.do"
    exit 1
}

global fac_dir "${PROJET_DIR}/Phase_3_Corrections_Critiques/base_de_donnees/Bases_Facteurs conversion"
global out_p4  "${PROJET_DIR}/Phase_4_Apurement/sorties"

* Chargement et fusion des deux feuilles du referentiel
import excel "${fac_dir}/Base_Fac_Aliment_VF.xlsx", sheet("Aliment_UT") firstrow clear
gen source_sheet = "Aliment_UT"
save "${out_p4}/_tmp_fac.dta", replace

import excel "${fac_dir}/Base_Fac_Aliment_VF.xlsx", sheet("Ingredient_UT") firstrow clear
gen source_sheet = "Ingredient_UT"
append using "${out_p4}/_tmp_fac.dta"

* Harmonisation des noms de variables selon la feuille source
capture rename Idd_Aliment_Rec   Code_Ingredient
capture rename Idd_Ingredient_Rec Code_Ingredient
capture rename RS_UNITE  UMesure
capture rename RS_TAILLE UTaille
capture rename RS_FACTEUR Facteur_g

* Conversion Code_Ingredient en string pour coherence avec la base conso
capture confirm string variable Code_Ingredient
if _rc != 0 {
    tostring Code_Ingredient, format(%12.0f) replace force
    replace Code_Ingredient = trim(Code_Ingredient)
}

* Conservation du facteur avec l'effectif majoritaire en cas de doublon
bysort Code_Ingredient UMesure UTaille (EFFECTIF): keep if _n == _N

* Correction ponctuelle documentee (source : collecte terrain)
replace Facteur_g = 2 if Code_Ingredient == "112142" & UMesure == "Sachet, format industriel"

sort Code_Ingredient UMesure UTaille
save "${out_p4}/Base_Facteurs_Master.dta", replace
capture erase "${out_p4}/_tmp_fac.dta"
