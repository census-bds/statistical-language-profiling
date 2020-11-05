#==========================================================#       
# STATISTICAL LANGUAGE PROFILING: R                                
#                                                                  
# 2020/10/13                                                       
#==========================================================#       

# DEFINE STATES TO RUN
# states <- c("DE") # for dev
states <- c("DE", "NV", "KS")

#===========================#
# SET UP PACKAGES              
#===========================#

libs <- c(
  "tidyverse",
  "magrittr", 
  "haven",    
  "logger",
  "glue"
)             


# get list of packages that aren't installed
to_install <- libs[!libs %in% installed.packages()[, "Package"]]

# install missing packages and load all packages
suppressMessages(invisible(lapply(to_install, install.packages, character.only=TRUE)))
suppressMessages(invisible(lapply(libs, library, character.only=TRUE)))   


#===========================#
# SET UP LOGGING              
#===========================#

# format the message
logger <- layout_glue_generator(
  format = '{node},{pid},{level},{time},{msg}'
  )
log_layout(logger)

#==========================================================#
# DEFINE FUNCTIONS
#==========================================================#

# construct path to data for given state-form
get_paths <- function(state, form) {

}                                                 


# read and merge household, person, geo files;
# add household size count and county/state averages
read_merge_count <- function(state, form) {
  
  paths  <- get_paths(state, form)        
  
  log_info(glue("begin reading: {state}"))
  
  h <- read_sas(paths[[1]])                 
  
  p <- read_sas(paths[[2]])               
  
  g <- read_sas(paths[[3]])               
  log_info(glue("finished reading files:  {state}"))        
  
  df <- left_join(                       
    h,                                    
    p,                                    
    by = c("HHIDH"= "HHIDP"),               
    suffix = c("_h", "_p")                
  ) %>%                                   
    left_join(                            
      g,                                  
      by = c("GIDH" = "GIDG")           
    )                                     
  
  log_info(glue("merges complete: {state}"))             

  nrow <- nrow(df)
  ncol <- ncol(df)
  log_info(glue("{state} df has {nrow} rows and {ncol} cols"))
  
  df %<>% add_count(HHIDH, name = "hh_size")                
  log_info(glue("added household person count: {state}"))
  
  df %>% group_by("COU") %>%
    mutate(mean_age = mean(AGE)) 
  log_info(glue("compute_mean_age: {state}"))  
  
  df %>% ungroup() %>%
    group_by("STF") %>%
    mutate(
      n_row = n(),
      mean_hh_size = mean(hh_size)
    )  
  log_info(glue("get_summary complete: {state}"))
  
  return(df)
}

#==========================================================#
# RUN ANALYSIS
#==========================================================#

log_info("defined methods")

log_info(glue::glue("States to run: {paste(states, collapse=' ')}"))

df <- map_dfr(states, ~ read_merge_count(., "H"))

log_info("analysis done")
