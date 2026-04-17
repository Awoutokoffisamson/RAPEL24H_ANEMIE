* Phase 6 - Script 01 : Validation nutritionnelle et exclusion des rappels implausibles
* Seuils de plausibilite appliques au total quotidien par individu x rappel :
*   - Calories totales hors intervalle [800 ; 5000] kcal
*   - Fer total superieur a 60 mg
version 16
set more off

if ("${PROJET_DIR}" == "") {
    disp as error "ERREUR : Lancez 00_MASTER.do"
    exit 1
}

global in_p5   "${PROJET_DIR}/Phase_5_Reconstruction/sorties"
global out_p6  "${PROJET_DIR}/Phase_6_Validation_Nutritionnelle/sorties"

use "${in_p5}/Base_Consommation_FINALE_P5.dta", clear

* Construction des totaux journaliers par (individu x rappel)
preserve
    collapse (sum) kcal_total=CALORIES fer_total=Ingere_Fer, ///
        by(Interview__key Numero_Rappel)

    gen byte a_exclure = (kcal_total < 800 | kcal_total > 5000 | fer_total > 60)
    keep if a_exclure == 1
    save "${out_p6}/Liste_Individus_Exclus.dta", replace
restore

* Filtrage : on enleve les lignes des individus x rappels flaggs
merge m:1 Interview__key Numero_Rappel using "${out_p6}/Liste_Individus_Exclus.dta", ///
    keep(1) nogen

save "${out_p6}/conso_phase6_validee.dta", replace
