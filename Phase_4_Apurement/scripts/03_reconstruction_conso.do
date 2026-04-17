* Phase 4 - Script 03 : Reconstruction des quantites par ingredient
* Jointure sequentielle conso x recettes (priorite : BF > BI > RST > RM)
* Formule : Quantite_Ingredient_g = Quantite_Grams_Pl x Pourcentage_Ing (recettes menage)
*           Quantite_Ingredient_g = Quantite_Plat x Pourcentage_Ing      (recettes standard)
*           Quantite_Ingredient_g = Quantite_Ingredient                  (non-apparies)
version 16
set more off

if ("${PROJET_DIR}" == "") {
    disp as error "ERREUR : Lancez 00_MASTER.do"
    exit 1
}

global out_p3 "${PROJET_DIR}/Phase_3_Corrections_Critiques/sorties/data_cleaned"
global out_p4 "${PROJET_DIR}/Phase_4_Apurement/sorties"

* --- Preparation des references recettes avec cles unifiees ---

* BF (priorite 1 sur BI)
use "${out_p3}/recette_BF_clean.dta", clear
rename Idd_Aliment_Rec Code_Plat
rename Idd_Ingredient  Code_Ingredient
rename (Quantite_Grams_Pl Pourcentage_Ing) (QGrams_Pl Pct_Ing)
gen _prio = 1
save "${out_p4}/_tmp_BF.dta", replace

* BI + fusion avec BF : on ne garde qu'une ligne par interview x plat x ingredient
use "${out_p3}/recette_BI_clean.dta", clear
rename Idd_Aliment_Rec Code_Plat
rename Idd_Ingredient  Code_Ingredient
rename (Quantite_Grams_Pl Pourcentage_Ing) (QGrams_Pl Pct_Ing)
gen _prio = 2
append using "${out_p4}/_tmp_BF.dta"
bysort Interview__key Code_Plat Code_Ingredient (_prio): keep if _n == 1
drop _prio
save "${out_p4}/_tmp_menage.dta", replace

* RST
use "${out_p3}/recette_RST_clean.dta", clear
rename Idd_Aliment_Rec Code_Plat
rename Idd_Ingredient  Code_Ingredient
rename Pourcentage_Ing Pct_Ing
save "${out_p4}/_tmp_RST.dta", replace

* RM (cle ingredient = Ids_Ingredient)
use "${out_p3}/recette_RM_clean.dta", clear
rename Idd_Aliment_Rec Code_Plat
rename Ids_Ingredient  Code_Ingredient
rename Pourcentage_Ing Pct_Ing
save "${out_p4}/_tmp_RM.dta", replace

* --- Jointure sequentielle ---
use "${out_p4}/conso_corrigee_p4.dta", clear
gen QGrams_Pl      = .
gen Pct_Ing        = .
gen Source_Recette = ""

* 1. Recettes menage (BF ou BI) : jointure sur interview x plat x ingredient
merge m:1 Interview__key Code_Plat Code_Ingredient using "${out_p4}/_tmp_menage.dta", ///
    keepusing(QGrams_Pl Pct_Ing) keep(1 3 4 5) update nogen
replace Source_Recette = "MENAGE" if !missing(Pct_Ing)

* 2. RST pour les lignes encore sans recette
merge m:1 Code_Plat Code_Ingredient using "${out_p4}/_tmp_RST.dta", ///
    keepusing(Pct_Ing) keep(1 3 4 5) update nogen
replace Source_Recette = "RST" if Source_Recette == "" & !missing(Pct_Ing)

* 3. RM en dernier recours
merge m:1 Code_Plat Code_Ingredient using "${out_p4}/_tmp_RM.dta", ///
    keepusing(Pct_Ing) keep(1 3 4 5) update nogen
replace Source_Recette = "RM"          if Source_Recette == "" & !missing(Pct_Ing)
replace Source_Recette = "NON_APPARIE" if Source_Recette == ""

* --- Calcul de Quantite_Ingredient_g selon la source ---
gen Quantite_Ingredient_g = .

* Recettes menage : poids issu de la declaration de la recette
replace Quantite_Ingredient_g = QGrams_Pl * Pct_Ing if Source_Recette == "MENAGE"

* Recettes standard/moyennes : proportion appliquee au poids du plat declare
replace Quantite_Ingredient_g = Quantite_Plat * Pct_Ing ///
    if inlist(Source_Recette, "RST", "RM") & !missing(Quantite_Plat)

* Non-apparies : quantite directe de la base de consommation
replace Quantite_Ingredient_g = Quantite_Ingredient if missing(Quantite_Ingredient_g)

drop QGrams_Pl Pct_Ing

save "${out_p4}/Base_Conso_Apuree_P4.dta", replace

* Nettoyage des temporaires
foreach f in _tmp_BF _tmp_menage _tmp_RST _tmp_RM {
    capture erase "${out_p4}/`f'.dta"
}
