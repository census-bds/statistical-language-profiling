*************************************
***Stata Languague Profiling	*****
***10/23/2020			*****
***Katie Genadek		*****
*************************************

capture log close
log using stat_prof_stata.log, replace


foreach st in de nv ks{
foreach tp in h g p{
timer on 2
import sas using "" 
save `st'_`tp'_data.dta, replace 
timer off 2
clear
}

timer on 3
use `st'_p_data.dta
rename HHIDP HHIDH
merge m:1 HHIDH using `st'_h_data.dta
drop if _merge==2
drop _merge
rename GIDH GIDG
merge m:1 GIDG using `st'_g_data.dta
drop if _merge==2
drop _merge
save `st'_merged.dta, replace
timer off 3


timer on 4
display "observation count for `st'"
count
display "variable count for `st'"
display c(k)
timer off 4

timer on 5
bysort HHIDH: gen house_count=_N
timer off 5


display "mean household size for `st'"
timer on 8
sum house_count
timer off 8


display "mean Age for counties in `st'"
timer on 7
bysort COU: sum AGE 
timer off 7


display "import time `st'"
timer list 2
display "timer import time `st'"
timer list 3
display "timer obs/var count `st'"
timer list 4
display "timer gen house count var `st'"
timer list 5
display "timer mean household count `st'"
timer list 8
display "timer for county mean age `st'"
timer list 7
timer clear

clear
}


