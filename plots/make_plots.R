#==========================================================#
# VISUALIZE RESULTS 
#
# 2020-10-30
#==========================================================#

libs <- c(
          "tidyverse",
          "magrittr",
          "janitor",
          "here",
          "extrafont",
          "lubridate"
)

suppressMessages(invisible(lapply(libs, library, character.only=TRUE)))

# load fonts
# font_import() #this is slow
loadfonts(device = "win")

# define colors
CENSUS_BLUE <- "#205493"
CENSUS_RED <- "#9B2743"
CENSUS_TEAL <- "#0095AB"
CENSUS_GREEN <- "#009964"
PALETTE <- c(CENSUS_TEAL, CENSUS_GREEN, CENSUS_RED, CENSUS_BLUE)

#==========================================================#
# BRING IN DATA
#==========================================================#

log_times <- read_csv("plots/log_times.csv") %>% 
  mutate(st_size = case_when(
    state == "DE" ~ "Small (DE)",
    state == "NV" ~ "Medium (NV)",
    state == "KS" ~ "Large (KS)"
  ))
ps <- read_csv("plots/ps.csv")

#===========================#
# PLOT TOTAL RUNTIME            
#===========================#

log_times %>%
  distinct(language, total_runtime) %>%
  ggplot(aes(x = reorder(language, total_runtime),
             y = total_runtime)) +
  geom_col(fill = CENSUS_BLUE) +
  labs(
    title = "SAS runtime was the quickest by far",
    subtitle = "Total runtime by language",
    x = "Language",
    y = "Runtime (minutes)"
  ) +
  theme_minimal() +
  theme(text = element_text(size = 16, family = "Century Gothic"),
        title = element_text(size = 20, face = "bold"), 
        axis.title = element_text(size = 16, face = "plain")) 

# ggsave("plots/total_runtime.png",
#        width = 8,
#        height = 6,
#        units = "in")


log_times %>%
  ggplot(aes(x = reorder(language, total_runtime),
             y = time / 60,
             fill = str_to_title(algo_stage))) +
  geom_col(position = "stack") +
  scale_fill_manual(values = c(CENSUS_GREEN, CENSUS_TEAL, CENSUS_BLUE)) +
  labs(
    title = "Reading data in Python is very slow",
    subtitle = "Runtime by task",
    x = "Language",
    y = "Runtime (minutes)",
    fill = "Task"
  ) +
  theme_minimal() +
  theme(text = element_text(size = 16, family = "Century Gothic"),
        title = element_text(size = 20, face = "bold"), 
        axis.title = element_text(size = 16, face = "plain")) 

ggsave("plots/runtime_by_task_sec.png",
       width = 8,
       height = 6,
       units = "in")


#===========================#
# PLOT RUNTIME % BY TASK            
#===========================#

# percentage
log_times %>%
  ggplot(aes(x = reorder(language, total_runtime),
             y = pct_runtime,
             fill = str_to_title(algo_stage))) +
  geom_col(position = "stack") +
  scale_fill_manual(values = c(CENSUS_GREEN, CENSUS_TEAL, CENSUS_BLUE)) +
  labs(
    title = "Relative time per task varies by language",
    subtitle = "% of runtime by task",
    x = "Language",
    y = "Share of runtime by task",
    fill = "Task") +
  scale_y_continuous(labels = scales::percent) +
  coord_flip() +
  theme_minimal() +
  theme(text = element_text(size = 16, family = "Century Gothic"),
        title = element_text(size = 20, face = "bold"), 
        axis.title = element_text(size = 16, face = "plain"),
        plot.caption = element_text(size = 12, face = "plain", hjust=0.35)) 

ggsave("plots/runtime_by_task.png",
       width = 8,
       height = 6,
       units = "in")

# percentage and state
log_times %>%
  group_by(language, state) %>%
  mutate(pct_runtime_by_task_st = time / sum(time)) %>%
  ggplot(aes(x = reorder(st_size, -time),
             y = time,
             fill = str_to_title(algo_stage))) +
  geom_col(position = "stack") +
  scale_y_continuous() +
  scale_fill_manual(values = c(CENSUS_GREEN, CENSUS_TEAL, CENSUS_BLUE)) +
  facet_wrap(~language, nrow = 4, scales = "free_x") +
  labs(
    title = "Runtimes increase nonlinearly with dataset size",
    subtitle = "Runtime by state by task",
    x = "Language",
    y = "Runtime by task (seconds)",
    fill = ""
  ) +
  coord_flip() +
  theme_minimal() +
  theme(
    text = element_text(size = 16, family = "Century Gothic"),
    title = element_text(size = 20, face = "bold"), 
    axis.title = element_text(size = 16, face = "plain"),
    legend.position = "top"
    ) 


ggsave("plots/runtime_by_task_by_state.png",
       width = 9.75,
       height = 6,
       units = "in")

#===========================#
# PLOT CPU %            
#===========================#

ps %>%
  mutate(seconds = hour(elapsed)*60 + minute(elapsed)) %>% # this is correct
  ggplot(aes(x = seconds, y = cpu, color = language)) +
  # geom_point() +
  geom_line(size = 1.5) +
  scale_color_manual(values = PALETTE) +
  xlim(0, 350) +
  labs(
    title = "Stata and Python use the most CPU",
    subtitle = "% CPU by language",
    x = "Seconds elapsed",
    y = "% CPU",
    color = ""
  ) +
  theme_minimal() +
  theme(
    text = element_text(size = 16, family = "Century Gothic"),
    title = element_text(size = 20, face = "bold"), 
    axis.title = element_text(size = 16, face = "plain"),
    legend.position = "top"
  ) 

ggsave("plots/cpu_pct.png",
       width = 8,
       height = 6,
       units = "in")
