#==========================================================#       
# STATISTICAL LANGUAGE PROFILING: EXTRACT LOGS                                
#                                                                  
# 2020/10/27                                                       
#==========================================================#  

LOG_PATH  <- ""

#===========================#
# SET UP PACKAGES              
#===========================#

libs <- c(
  "data.table",
  "tidyverse",
  "magrittr", 
  "glue",
  "lubridate",
  "janitor"
)             

# get list of packages that aren't installed
to_install <- libs[!libs %in% installed.packages()[, "Package"]]

# install missing packages and load all packages
lapply(to_install, install.packages, character.only=TRUE)
lapply(libs, suppressMessages(invisible(library)), character.only=TRUE)   

#===========================#
# READ IN R LOG FILE              
#===========================#

get_r_log <- function(r_log_file) {
  
  read_csv(
  glue("{LOG_PATH}{r_log_file}"), 
  col_names = c(
    "node",
    "pid",
    "level",
    "time",
    "msg"
  )
) %>%
  mutate(
    time_elapsed = time - lag(time),
    time_elapsed = if_else(is.na(time_elapsed), 0, as.numeric(time_elapsed)),
    cumulative_time = cumsum(time_elapsed),
    algo_stage = case_when(
        str_detect(msg, "finished reading") ~ "read",
        str_detect(msg, "merge") ~ "merge",
        str_detect(msg, "household person count") ~ "count",
        str_detect(msg, "compute_mean_age") ~ "count",
        str_detect(msg, "get_summary complete") ~ "count",
        TRUE ~ NA_character_
      ),
    state = case_when(
      str_detect(msg, " DE$") ~ "DE",
      str_detect(msg, " KS$") ~ "KS",
      str_detect(msg, " NV$") ~ "NV"
    )
  ) %>%
  group_by(algo_stage, state) %>%
  summarize(time = sum(time_elapsed)) %>%
  filter(!is.na(algo_stage)) 
}
# View(r)

#===========================#
# READ IN PYTHON LOGS              
#===========================#

get_python_log <- function(python_log_file) {
  
  read_csv(python_log_file) %>%
  clean_names() %>%
  mutate(
    algo_stage = case_when(
      str_detect(log_message, "read") ~ "read",
      str_detect(log_message, "merges") ~ "merge",
      str_detect(log_message, "cou_") ~ "count",
      str_detect(log_message, "hh_group") ~ "count"
    ),
    state = str_extract(log_message, "^[A-Z]{2}")
  ) %>%
  group_by(algo_stage, state) %>%
  summarize(time = sum(runtime))

} 
# View(python)

#===========================#
# READ IN STATA LOGS              
#===========================#

get_stata_log <- function(stata_log_file) {
  
  stata <- fread(STATA_LOG_FILE,
        header = FALSE,
        blank.lines.skip = TRUE,
        fill = TRUE)
  stata %<>%
    unite("V1", names(stata), sep=" ") %>%
    filter(
    str_detect(V1, "import time [a-z]") |
      str_detect(V1, "timer obs/var count") |
      str_detect(V1, "timer gen house count") |
      str_detect(V1, 'timer mean household count') |
      str_detect(V1, 'timer for county mean age') |
      str_detect(V1, "$*[0-9]: "),
    !str_detect(V1, "display")
  ) %>%
  mutate(
    id = floor(row_number() / 2 -0.05),
    numeric = if_else(str_detect(V1, "$*[0-9]"), "time", "label")
  ) %>%
  spread(numeric, V1) %>%
  tidyr::separate(time, c(NA, "time"), sep="=") %>%
  mutate(
    time = as.numeric(str_squish(time)),
    label = str_squish(label),
    algo_stage = case_when(
      str_detect(label, "^import time [a-z]") ~ "read",
      str_detect(label, "timer import time") ~ "merge",
      str_detect(label, "gen house count") ~ "count",
      str_detect(label, "mean household") ~ "count",
      str_detect(label, "county mean age") ~ "count"
    ),
    state = case_when(
      str_detect(label, "de$") ~ "DE",
      str_detect(label, "ks$") ~ "KS",
      str_detect(label, "nv$") ~ "NV"
    )
  ) %>%
  group_by(algo_stage, state) %>%
  summarize(time = sum(time)) %>%
  filter(!is.na(algo_stage))
  
}
# View(stata)


#===========================#
# READ IN SAS LOGS              
#===========================#

get_sas_log <- function(sas_log_file) {
  
  fread(sas_log_file,
             header = FALSE,
             blank.lines.skip = TRUE,
             fill = TRUE) %>%
  select(V1) %>%
  filter(
    str_detect(V1, "%readin") |
      str_detect(V1, "%merge_it") |
      str_detect(V1, "%count") |
      str_detect(V1, "real time") |
      str_detect(V1, "NOTE: The SAS System used")
  ) %>%
  tidyr::separate(V1, c("a", "b"), sep="       ") %>%
  mutate(
    c = if_else(str_detect(b, "%"), b, NA_character_),
    c = if_else(str_detect(a, "The SAS System"), "total", c),
    sec = as.numeric(str_remove(b, " seconds"))
  ) %>%
  fill(c, .direction=c("down")) %>%
  filter(!is.na(sec)) %>%
  group_by(c) %>%
  summarize(time = sum(sec)) %>%
  mutate(
    c = if_else(is.na(c), "startup", c),
    c = str_remove(c, "state="),
    algo_stage = case_when(
      str_detect(c, "read") ~ "read",
      str_detect(c, "merge") ~ "merge",
      str_detect(c, "count")~ "count"
    ), 
    state = case_when(
      str_detect(c, "ks") ~ "KS",  
      str_detect(c, "de") ~ "DE",  
      str_detect(c, "nv") ~ "NV"  
    )
  ) %>%
  group_by(algo_stage, state) %>%
  summarize(time = sum(time)) %>%
  filter(!is.na(algo_stage))

}
 
# View(sas)


#===========================#
# READ IN PS FILE              
#===========================#

get_ps_file <- function(ps_file) {
  
  read_csv(glue("{LOG_PATH}{ps_file}")) %>%
  clean_names() %>%
  mutate(
    datetime = ymd_hms(paste0(date, time)),
    sec_elapsed = as.numeric(elapsed)
  )

}

