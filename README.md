# Statistical language profiling

Scripts to profile various statistical programming languages

NOTE: This repo has been scrubbed in order to ensure compliance with the Census Bureau's disclosure protection rules. As a result, some code won't run "out of the box". 

## Experiment steps

 - Merge the 1990 decennial H file (H is the short form, 100% file) geo, household, person files to create one flat file with a row for each person with household and geo information on it (persons nest in households, households nest in geos) for the following states: KS, DE, NV.
 - The Person records link to households using HHIDP/HHIDH and the household records link to the geo records using GIDG/GIDH. Please keep all of the variables in your files. For each household, count the number of people in the household and include this person count on each row of the household. By county (COU), generate the mean age (AGE) in that county code.  
 - Data files are state level sas files for the g, h, p records. Documentation is available from the RDC documentation internal site. 
 - Create results: 
    1. Number of rows in each state data file
    2. Number of columns in each state data file
    3. Mean number of people in households by state
    4. Mean age by county (as calculated earlier)

## How we ran these scripts

To run these scripts on the Census Bureau's Integrated Research Environment (IRE), we submitted them to the IRE resource scheduler, which queues jobs until the requested resources become available. Because IRE is a shared resource, other users' behavior could affect script runtime. To minimize the effect of this interference, we submitted all jobs to the queue one at the same time on a weekday evening after normal business hours. We took the fact that jobs moved almost immediately from "queued" to "running" as an indication that our chosen window was not a high-usage time. 

## Languages

 - SAS
 - Stata
 - Python/pandas
 - R

## Ideas for future work

 - PBS resource allocation
   + busy vs. unused nodes
   + extra CPUs
   + extra memory
 - Reducing disk use
   + saspy to df using memory: https://github.com/sassoftware/saspy
   + piping
     * from sas, use STDOUT as file name: https://web.archive.org/web/20060211234626/http://support.sas.com/sassamples/quicktips/pipes_0702.html
     * into python: https://stackoverflow.com/a/43194984
 - Initial SAS conversion
   + SAS proc export to csv
   + SAS proc export to Stata
   + SAS proc export to ?
   + pandas SAS importer (if it doesn't fail)
   + R SAS importer (if it doesn't fail)
   + SQLite: https://gist.github.com/jtdv01/bdd19e6503a02d0a9b643a6d3e52b4df
 - Python-specific variables
   + Manual-control over chunking when reading in files
   + Multithreading over chunks
