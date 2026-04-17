* Diagnostic : affiche les variables de chaque base recette
version 16
set more off

if ("${PROJET_DIR}" == "") {
    disp as error "ERREUR : Lancez 00_MASTER.do"
    exit 1
}

foreach base in ///
    "Base_CONSOMMATION_RECETTES_BF.dta" ///
    "Base_CONSOMMATION_RECETTES_BI.dta" ///
    "Base_Recettes_RST.dta"             ///
    "BASE_RECETTES_MOYENNES.dta"        {

    use "${PROJET_DIR}/00_raw_data/`base'", clear
    disp _newline as text "=== `base' ==="
    describe
}
