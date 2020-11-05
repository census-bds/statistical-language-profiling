
/** Statistical Language Profiling**/
/** Virginia Gwengi **/
/** get number of rows in each state data file**/
/**get number of columns in each state data file**/
/** mean number of people in households by state**/
/** mean age by county by state**/
options fullstimer;
libname cen ""
libname testout ""

/**KS,DE,NV**/
/**g,h,p for geo,home, person**/

%macro readin(state,dataset);

data &state.h&dataset.;
set cen.&state.h&dataset.;
run;
/*proc printto;run;*/
ods tagsets.excelxp file="";
proc contents data =  &state.h&dataset.; run;
ods tagsets.excelxp close;

%if &dataset.= h %then %do;
data &state.h&dataset.;
set &state.h&dataset. ; if missing (GIDH) then delete;
run;
proc sort data=&state.h&dataset.;
by GIDH;
run;
%end;

%if&dataset.=g %then %do;
data &state.h&dataset.;
set &state.h&dataset.  ; if missing (GIDG) then delete;
run;
proc sort data=&state.h&dataset.;
by GIDG;
run;
%end;


%if&dataset.=p %then %do;
proc sort data=&state.h&dataset.;
by HHIDP;
run;
%end;
%mend readin;

%readin(state=de,dataset=h);
%readin(de,g);
%readin(de,p);

%readin(state=ks,dataset=h);
%readin(ks,g);
%readin(ks,p);

%readin(state=nv,dataset=h);
%readin(nv,g);
%readin(nv,p);

%macro merge_it(state);

data &state.merge_hp;
  merge &state.hp(in=person rename=(HHIDP=HHIDH))  &state.hh(in=house);
  by HHIDH;
  if person;
run;

proc sort data=&state.merge_hp;
by GIDH;
run;


data &state.merge_phg;
  merge &state.merge_hp(in=person rename=(GIDH=GIDG))  &state.hg (in=geo);
  by GIDG;
  if person;
run;

%mend merge_it;

%merge_it(de);
%merge_it(ks);
%merge_it(nv);

/***---------------------------------***/
%macro count(state);
data &state.merge_hgp_out;
set &state.merge_phg;
by HHIDH;
if last.HHIDH;
count=_n_-sum(lag(_n_),0);
do _n_=1 to count;
set &state.merge_phg;
output;
end;
run;

proc contents data =  &state.merge_hgp_out; run;

proc means data=&state.merge_hgp_out noprint nway;
class COU;
var AGE;
output out=mean_&state. mean=county_mean;
run; 


/*proc export 
data=mean_&state.
DBMS= csv 
outfile= ""
REPLACE;
RUN;*/


/*proc export 
data=&state.merge_hgp_out
DBMS= csv 
outfile= ""
REPLACE;
RUN;*/
%mend count;

%count(de);
%count(ks);
%count(nv);



