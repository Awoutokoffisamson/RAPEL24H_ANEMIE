* RAPEL24H_ANEMIE - Script maitre
* Usage : cd dans le dossier qui contient ce fichier, puis `do 00_MASTER.do`.
version 16
set more off
clear all

* Detection automatique du dossier projet (portable Windows / Linux / macOS)
global PROJET_DIR "`c(pwd)'"

if ("${PROJET_DIR}" == "") {
    disp as error "ERREUR : PROJET_DIR non defini. cd dans le dossier du master avant de relancer."
    exit 1
}

* PHASE_MAX : limiter l'execution a une phase donnee (ex: 3 pour tester Phase 3 seule)
global PHASE_MAX 7
if ("${PHASE_MAX}" == "") global PHASE_MAX 7

cd "${PROJET_DIR}"

do "${PROJET_DIR}/Phase_3_Corrections_Critiques/scripts/01_nettoyage.do"
if ${PHASE_MAX} <= 3 exit 0

do "${PROJET_DIR}/Phase_4_Apurement/scripts/01_apurement_referentiels.do"
do "${PROJET_DIR}/Phase_4_Apurement/scripts/02_consolidation_referentiel.do"
do "${PROJET_DIR}/Phase_4_Apurement/scripts/03_reconstruction_conso.do"
if ${PHASE_MAX} <= 4 exit 0

do "${PROJET_DIR}/Phase_5_Reconstruction/scripts/01_reconstruction_composition.do"
do "${PROJET_DIR}/Phase_5_Reconstruction/scripts/02_calcul_final_apports.do"
if ${PHASE_MAX} <= 5 exit 0

do "${PROJET_DIR}/Phase_6_Validation_Nutritionnelle/scripts/01_validation_extrems.do"
if ${PHASE_MAX} <= 6 exit 0

do "${PROJET_DIR}/Phase_7_Indicateurs/scripts/01_indicateurs_aggreges.do"
