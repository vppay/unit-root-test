* ============================================
* VERSI SIMPEL: UJI STASIONERITAS + TABEL
* ============================================

clear all
set more off

* 1. IMPORT DATA
import excel "C:\Users\User\Downloads\data_Sims_25-26.xlsx", firstrow clear

* 2. KONVERSI VARIABEL
destring mb gnp i unemp, replace ignore(",.")

* Konversi date
gen date_q = qofd(date)
format date_q %tq

* Set time series
tsset date_q

* ============================================
* 3. UJI STASIONERITAS
* ============================================

* Install KPSS jika belum (jalankan sekali saja)
* ssc install kpss

* Buat matrix untuk menyimpan hasil
matrix results = J(4, 9, .)
matrix colnames results = "ADF_stat" "ADF_pval" "PP_stat" "PP_pval" "KPSS_stat" "KPSS_cv5" "ADF_decision" "PP_decision" "KPSS_decision"
matrix rownames results = "mb" "gnp" "interest" "unemploy"

local i = 1
foreach var of varlist mb gnp i unemp {
    
    display _newline(2)
    display 
    
    * ADF Test
    quietly dfuller `var', lags(4)
    local adf_stat = r(Zt)
    local adf_pval = r(p)
    local adf_decision = cond(`adf_pval' < 0.05, 1, 0) //1=stasioner, 0=tidak
    
    display "ADF Test:"
    display "  Test Statistic = " %6.3f `adf_stat'
    display "  P-value = " %6.4f `adf_pval'
    display "  Decision: " cond(`adf_decision'==1, "Stasioner", "Tidak Stasioner")
    
    * PP Test
    quietly pperron `var', lags(4)
    local pp_stat = r(Zt)
    local pp_pval = r(p)
    local pp_decision = cond(`pp_pval' < 0.05, 1, 0)
    
    display _newline
    display "Phillips-Perron Test:"
    display "  Test Statistic = " %6.3f `pp_stat'
    display "  P-value = " %6.4f `pp_pval'
    display "  Decision: " cond(`pp_decision'==1, "Stasioner", "Tidak Stasioner")
    
    * KPSS Test
    quietly kpss `var', maxlag(4)
    local kpss_stat = r(kpss4)
    local kpss_cv5 = r(p05)
    local kpss_decision = cond(`kpss_stat' < `kpss_cv5', 1, 0)  // KPSS kebalikan!
    
    display _newline
    display "KPSS Test:"
    display "  Test Statistic = " %6.3f `kpss_stat'
    display "  5% Critical Value = " %6.3f `kpss_cv5'
    display "  Decision: " cond(`kpss_decision'==1, "Stasioner", "Tidak Stasioner")
    
    * Simpan ke matrix
    matrix results[`i', 1] = `adf_stat'
    matrix results[`i', 2] = `adf_pval'
    matrix results[`i', 3] = `pp_stat'
    matrix results[`i', 4] = `pp_pval'
    matrix results[`i', 5] = `kpss_stat'
    matrix results[`i', 6] = `kpss_cv5'
    matrix results[`i', 7] = `adf_decision'
    matrix results[`i', 8] = `pp_decision'
    matrix results[`i', 9] = `kpss_decision'
    
    local i = `i' + 1
}

* ============================================
* 4. TAMPILKAN TABEL RINGKASAN
* ============================================

display _newline(3)
display 

matrix list results, format(%9.4f)

* ============================================
* 5. TABEL LEBIH RAPI (MANUAL)
* ============================================

display _newline(2)
display "TABEL HASIL UJI STASIONERITAS"
display "{hline 120}"
display _col(1) "Variable" _col(15) "ADF Stat" _col(27) "ADF P-val" _col(40) "PP Stat" _col(52) "PP P-val" _col(65) "KPSS Stat" _col(78) "KPSS CV(5%)" _col(93) "Kesimpulan"
display "{hline 120}"

local row = 1
foreach var in mb gnp i unemp {
    local adf_s = results[`row', 1]
    local adf_p = results[`row', 2]
    local pp_s = results[`row', 3]
    local pp_p = results[`row', 4]
    local kpss_s = results[`row', 5]
    local kpss_cv = results[`row', 6]
    
    * Tentukan kesimpulan akhir (mayoritas)
    local sum_decision = results[`row', 7] + results[`row', 8] + results[`row', 9]
    local conclusion = cond(`sum_decision' >= 2, "Stasioner", "Tidak Stasioner")
    
    display _col(1) "`var'" _col(15) %7.3f `adf_s' _col(27) %7.4f `adf_p' ///
            _col(40) %7.3f `pp_s' _col(52) %7.4f `pp_p' ///
            _col(65) %7.3f `kpss_s' _col(78) %7.3f `kpss_cv' ///
            _col(93) "`conclusion'"
    
    local row = `row' + 1
}

display "{hline 120}"

* ============================================
* 6. EXPORT KE EXCEL (OPSIONAL)
* ============================================

putexcel set "hasil_stasioneritas constant.xlsx", replace
putexcel A1 = "Variable"
putexcel B1 = "ADF Statistic"
putexcel C1 = "ADF P-value"
putexcel D1 = "PP Statistic"
putexcel E1 = "PP P-value"
putexcel F1 = "KPSS Statistic"
putexcel G1 = "KPSS CV(5%)"
putexcel H1 = "Kesimpulan"

local row = 2
foreach var in mb gnp i unemp {
    local r = `row' - 1
    putexcel A`row' = "`var'"
    putexcel B`row' = matrix(results[`r', 1])
    putexcel C`row' = matrix(results[`r', 2])
    putexcel D`row' = matrix(results[`r', 3])
    putexcel E`row' = matrix(results[`r', 4])
    putexcel F`row' = matrix(results[`r', 5])
    putexcel G`row' = matrix(results[`r', 6])
    
    local sum_dec = results[`r', 7] + results[`r', 8] + results[`r', 9]
    local concl = cond(`sum_dec' >= 2, "Stasioner", "Tidak Stasioner")
    putexcel H`row' = "`concl'"
    
    local row = `row' + 1
}

display _newline(2)
display "Hasil telah diekspor ke: hasil_stasioneritas constant.xlsx"


* ============================================
* CATATAN INTERPRETASI:
* ============================================
* ADF & PP Test: p-value < 0.05 → Stasioner
* KPSS Test: stat < critical value → Stasioner
* Kesimpulan akhir: berdasarkan mayoritas (2 dari 3 test)
* ============================================
