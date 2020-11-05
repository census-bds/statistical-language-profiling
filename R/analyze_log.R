#==========================================================#       
# STATISTICAL LANGUAGE PROFILING: ANALYZE LOGS                                
#                                                                  
# 2020/10/28                                                       
#==========================================================#  

PATH <- ""


R_LOG_FILE <- ""
STATA_LOG_FILE <- ""
SAS_LOG_FILE <- ""
PYTHON_LOG_FILE <- "" 

R_PS_FILE <- ""
PYTHON_PS_FILE <- ""
STATA_PS_FILE <- ""
SAS_PS_FILE <- ""

COMBINED_LOG_TIMES <- "" 
COMBINED_PS <- "" 

#===========================#
# SET UP PACKAGES              
#===========================#

libs <- c(
  "tidyverse",
  "magrittr",    
  "glue",
  "janitor"
)             

# get list of packages that aren't installed
to_install <- libs[!libs %in% installed.packages()[, "Package"]]

# install missing packages and load all packages
lapply(to_install, install.packages, character.only=TRUE)
lapply(libs, suppressMessages(invisible(library)), character.only=TRUE)   

#===============================#
# BRING IN LOG AND PS SUMMARIES              
#===============================#

source(glue("{PATH}/R/extract_logs.R"))

r <- get_r_log(R_LOG_FILE)
python <- get_python_log(PYTHON_LOG_FILE)
sas <- get_sas_log(SAS_LOG_FILE)
stata <- get_stata_log(STATA_LOG_FILE)

log_times <- bind_rows(
  python %>% mutate(language = "Python"),
  r %>% mutate(language = "R"),
  stata %>% mutate(language = "Stata"),
  sas %>% mutate(language = "SAS"),
  ) %>%
  group_by(language) %>%
  mutate(
    total_runtime = sum(time) / 60,
    pct_runtime = time / sum(time)
  )
View(log_times)  

write_csv(log_times, COMBINED_LOG_TIMES)

ps <- bind_rows(
    get_ps_file(R_PS_FILE) %>% mutate(language = "R"),
    get_ps_file(PYTHON_PS_FILE) %>% mutate(language = "Python"),
    get_ps_file(SAS_PS_FILE) %>% mutate(language = "SAS"),
    get_ps_file(STATA_PS_FILE) %>% mutate(language = "Stata"),
  )
View(ps)

write_csv(ps, COMBINED_PS)

#===========================#
# PLOT TOTAL RUNTIME            
#===========================#

log_times %>%
  distinct(language, total_runtime) %>%
  ggplot(aes(x = reorder(language, total_runtime),
             y = total_runtime)) +
  geom_col(fill = "#205493") +
  labs(
    title = "Python is by far the slowest language",
    subtitle = "Total runtime by language",
    x = "Language",
    y = "Runtime (minutes)"
    )

# ggsave("plots/total_runtime.png", 
#        width = 9, 
#        height = 12,
#        units = "cm")

#===========================#
# PLOT RUNTIME BY TASK            
#===========================#

log_times %>%
  ggplot(aes(x = reorder(language, total_runtime),
             y = pct_runtime,
             group = algo_stage,
             fill = algo_stage)) +
  geom_col(position = "stack") +
  labs(
    title = "Reading data in Python is really slow",
    subtitle = "Runtime by task by language",
    x = "Language",
    y = "Share of runtime by task",
    fill = "Task"
  )

log_times %>%
  ggplot(aes(x = reorder(language, total_runtime),
             y = pct_runtime,
             group = algo_stage,
             fill = algo_stage)) +
  geom_col(position = "stack") +
  facet_wrap(~state) +
  labs(
    title = "Stata runtime is heavily skewed by the first count",
    subtitle = "Runtime by task by language",
    x = "Language",
    y = "Share of runtime by task",
    fill = "Task"
  )

#===========================#
# PLOT CPU %            
#===========================#

ps %>%
  mutate(seconds = hour(elapsed)*60 + minute(elapsed)) %>% # this is correct
  ggplot(aes(x = seconds, y = cpu, color = language)) +
  geom_point() +
  geom_line() +
  xlim(0, 350) +
  labs(
    title = "Stata and Python have the highest CPU usage",
    x = "Seconds elapsed",
    y = "% CPU",
    color = "Language"
    )


