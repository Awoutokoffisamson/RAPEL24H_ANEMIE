* Phase 7 - Script 01 : Agregation par rappel et construction des indicateurs
* Totaux journaliers par (individu x rappel), part des sources de recettes,
* et flags de carence base sur les EAR.
version 16
set more off

if ("${PROJET_DIR}" == "") {
    disp as error "ERREUR : Lancez 00_MASTER.do"
    exit 1
}

global in_p6  "${PROJET_DIR}/Phase_6_Validation_Nutritionnelle/sorties"
global out_p7 "${PROJET_DIR}/Phase_7_Indicateurs/sorties"

use "${in_p6}/conso_phase6_validee.dta", clear

* Labels des regions
label define region_lbl 1 "DAKAR" 2 "DIOURBEL" 3 "FATICK" 4 "KAFFRINE" ///
    5 "KAOLACK" 6 "KEDOUGOU" 7 "KOLDA" 8 "LOUGA" 9 "MATAM" ///
    10 "SAINT-LOUIS" 11 "SEDHIOU" 12 "TAMBACOUNDA" 13 "THIES" 14 "ZIGUINCHOR", replace
label values Region region_lbl

* Decomposition des calories par source de recette
gen kcal_menage      = CALORIES if Source_Recette == "MENAGE"
gen kcal_rst         = CALORIES if Source_Recette == "RST"
gen kcal_rm          = CALORIES if Source_Recette == "RM"
gen kcal_non_apparie = CALORIES if Source_Recette == "NON_APPARIE"

* Totaux journaliers par (individu x rappel)
collapse ///
    (sum)   Total_KCAL=CALORIES Total_Fer=Ingere_Fer Total_Zinc=Ingere_Zinc ///
            Total_Protein=Ingere_Protein Total_Lipides=Ingere_Lipides ///
            Total_Glucides=Ingere_Glucides Total_VitC=Ingere_VitaminC ///
            Kcal_Menage=kcal_menage Kcal_RST=kcal_rst Kcal_RM=kcal_rm ///
            Kcal_NonApp=kcal_non_apparie ///
    (first) Household_key HH_Sample_Weight Numero_DR ///
            Milieu_Residence Region ZoneEthno ///
            Score_Niveau_Vie Quintil_Niveau_Vie ///
            Age_Tr Age_Ans Sexe, ///
    by(Interview__key Numero_Rappel)

* Indicateurs de carence (seuils EAR OMS/FAO)
gen byte carence_Fer     = (Total_Fer     < 10.5) if !missing(Total_Fer)
gen byte carence_Zinc    = (Total_Zinc    <  7.0) if !missing(Total_Zinc)
gen byte carence_Protein = (Total_Protein < 34  ) if !missing(Total_Protein)
gen byte faim_Kcal       = (Total_KCAL    < 1800)

label var carence_Fer     "Risque de carence en fer (<10.5 mg/j)"
label var carence_Zinc    "Risque de carence en zinc (<7 mg/j)"
label var carence_Protein "Risque d'apport proteique insuffisant (<34 g/j)"
label var faim_Kcal       "Apport calorique insuffisant (<1800 kcal/j)"

* Parts de consommation selon la source de recette (en %)
foreach src in Menage RST RM NonApp {
    gen Part_Kcal_`src' = (Kcal_`src' / Total_KCAL) * 100
}

save "${out_p7}/BASE_ANALYSE_FINALE_ANEMIE_P7.dta", replace

* Verification rapide : apport moyen en fer, pondere, par milieu
svyset [pweight=HH_Sample_Weight]
svy: mean Total_Fer, over(Milieu_Residence)
