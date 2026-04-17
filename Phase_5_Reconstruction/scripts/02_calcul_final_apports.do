* Phase 5 - Script 02 : Calcul des apports nutritionnels individuels
* Application de la table de composition reconstruite aux quantites ingerees
* reconstruites en Phase 4 (Quantite_Ingredient_g).
version 16
set more off

if ("${PROJET_DIR}" == "") {
    disp as error "ERREUR : Lancez 00_MASTER.do"
    exit 1
}

global in_p4  "${PROJET_DIR}/Phase_4_Apurement/sorties"
global out_p5 "${PROJET_DIR}/Phase_5_Reconstruction/sorties"

use "${in_p4}/Base_Conso_Apuree_P4.dta", clear

* Jointure sur la table de composition par ingredient
merge m:1 Code_Ingredient using "${out_p5}/Table_Composition_Reconstruite.dta", ///
    keep(1 3) nogen

* Apports = quantite ingeree (g) x teneur pour 100g / 100
foreach v in CALORIES Ingere_Fer Ingere_Zinc Ingere_Protein ///
             Ingere_Lipides Ingere_Glucides Ingere_VitaminC {
    replace `v' = (Quantite_Ingredient_g / 100) * Teneur_100g_`v' ///
        if !missing(Quantite_Ingredient_g, Teneur_100g_`v')
}

save "${out_p5}/Base_Consommation_FINALE_P5.dta", replace
