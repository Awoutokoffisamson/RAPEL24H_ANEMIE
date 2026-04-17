* Phase 3 - Nettoyage et apurement des bases sources
version 16
set more off

if ("${PROJET_DIR}" == "") {
    disp as error "ERREUR : Lancez 00_MASTER.do"
    exit 1
}

global raw_conso "${PROJET_DIR}/00_raw_data/Anemie_Base_Consommation_R24H.dta"
global raw_BF    "${PROJET_DIR}/00_raw_data/Base_CONSOMMATION_RECETTES_BF.dta"
global raw_BI    "${PROJET_DIR}/00_raw_data/Base_CONSOMMATION_RECETTES_BI.dta"
global raw_RST   "${PROJET_DIR}/00_raw_data/Base_Recettes_RST.dta"
global raw_RM    "${PROJET_DIR}/00_raw_data/BASE_RECETTES_MOYENNES.dta"
global out_p3    "${PROJET_DIR}/Phase_3_Corrections_Critiques/sorties/data_cleaned"

* Programme local : convertit une liste de variables en string si necessaire
cap program drop tostr_keys
program tostr_keys
    foreach v of local 0 {
        capture confirm string variable `v'
        if _rc != 0 tostring `v', format(%12.0f) replace force
        replace `v' = trim(`v')
    }
end







* --- A. Consommation R24H ---
use "$raw_conso", clear

* Cles de jointure en string
tostr_keys Interview__key Code_Plat Code_Ingredient

* Imputations ciblees sur Ingere_Fer (sel=0, concentre tomate=CIQUAL 3.5mg/100g)
replace Ingere_Fer = 0 if missing(Ingere_Fer) & strpos(lower(Label_Ingredient), "sel") > 0
replace Ingere_Fer = (Quantite_Ingredient / 100) * 3.5 ///
    if missing(Ingere_Fer) ///
    & strpos(lower(Label_Ingredient), "tomate") > 0 ///
    & strpos(lower(Label_Ingredient), "concentre") > 0

* Flag avant collapse pour preserver les vrais manquants
local nutrivars "CALORIES Ingere_Fer Ingere_Zinc Ingere_Protein Ingere_Lipides Ingere_Glucides Ingere_VitaminC"
foreach v of local nutrivars {
    capture confirm variable `v'
    if _rc == 0 gen byte _flag_`v' = missing(`v')
}






* Aggregation des resservies - cle sans labels texte
collapse ///
    (sum)   Quantite_Plat Quantite_Ingredient ///
            CALORIES Ingere_Fer Ingere_Zinc Ingere_Protein ///
            Ingere_Lipides Ingere_Glucides Ingere_VitaminC ///
    (min)   _flag_CALORIES _flag_Ingere_Fer _flag_Ingere_Zinc ///
            _flag_Ingere_Protein _flag_Ingere_Lipides ///
            _flag_Ingere_Glucides _flag_Ingere_VitaminC ///
    (first) Household_key HH_Sample_Weight Numero_DR ///
            Milieu_Residence Region ZoneEthno ///
            Score_Niveau_Vie Quintil_Niveau_Vie ///
            Age_Tr Age_Ans Sexe Code_Retention Fac_Comestible ///
            Label_Repas Label_Plat Label_Ingredient, ///
    by(Interview__key Numero_Rappel Code_Repas Code_Plat Code_Ingredient)

foreach v of local nutrivars {
    capture confirm variable _flag_`v'
    if _rc == 0 {
        replace `v' = . if _flag_`v' == 1
        drop _flag_`v'
    }
}

save "${out_p3}/conso_clean.dta", replace






* --- B. Cle individu x rappel ---
use "${out_p3}/conso_clean.dta", clear

collapse ///
    (first) Household_key HH_Sample_Weight Numero_DR ///
            Milieu_Residence Region ZoneEthno ///
            Score_Niveau_Vie Quintil_Niveau_Vie ///
            Age_Tr Age_Ans Sexe, ///
    by(Interview__key Numero_Rappel)

save "${out_p3}/cle_rappel.dta", replace

* --- C-D. Recettes menage BF et BI (structure identique) ---
foreach type in BF BI {
    use "${raw_`type'}", clear
    rename interview__key Interview__key
    tostr_keys Idd_Aliment_Rec Idd_Ingredient

    * Suppression des lignes inexploitables
    drop if missing(Quantite_Grams_Pl) | Quantite_Grams_Pl <= 0
    drop if missing(Pourcentage_Ing) | Pourcentage_Ing <= 0 | Pourcentage_Ing > 1

    collapse ///
        (mean)   Quantite_Grams_Pl Pourcentage_Ing ///
        (firstnm) Lbd_Aliment_Rec Lbd_Ingredient CODE_FRT, ///
        by(Interview__key Idd_Aliment_Rec Idd_Ingredient)

    save "${out_p3}/recette_`type'_clean.dta", replace
}








* --- E. Recettes standard RST (proportions uniquement, pas de Quantite_Grams_Pl) ---
use "$raw_RST", clear
tostr_keys Idd_Aliment_Rec Idd_Ingredient

drop if missing(Pourcentage_Ing)

collapse ///
    (mean)   Pourcentage_Ing ///
    (firstnm) Lbd_Aliment_Rec Lbd_Ingredient CODE_FRT, ///
    by(Idd_Aliment_Rec Idd_Ingredient)

save "${out_p3}/recette_RST_clean.dta", replace





* --- F. Recettes moyennes RM (cle ingredient = Ids_Ingredient) ---
use "$raw_RM", clear
tostr_keys Idd_Aliment_Rec Ids_Ingredient

drop if missing(Pourcentage_Ing)

collapse ///
    (mean)   Pourcentage_Ing Pourcent_Ing ///
    (firstnm) Lbd_Aliment_Rec LabS_Ingredient Label_Ingredient CODE_FRT, ///
    by(Idd_Aliment_Rec Ids_Ingredient)

save "${out_p3}/recette_RM_clean.dta", replace
