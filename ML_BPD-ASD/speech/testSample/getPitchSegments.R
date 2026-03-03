library(tidyverse)
df = read_csv("ZOOM0022_Tr1_cont.csv")

# categorise the start and end of the pitch segments
df$cat = NA
for (i in 2:nrow(df)) {
  if ((df$pitch[i] != "--undefined--") & (df$pitch[i-1] == "--undefined--")) {
    df$cat[i] = "pitch"
  } else if ((df$pitch[i] == "--undefined--") & (df$pitch[i-1] != "--undefined--")) {
    df$cat[i]  = "end"
  }
}

# get the number of segments
nos = sum(df$cat == "pitch", na.rm = T)

# only keep the start and end points of the segment
df.sel = df %>% filter(!is.na(cat) & cat != "before") %>%
  select(time, cat) %>%
  mutate(segment = rep(1:nos, each = 2)) %>%
  pivot_wider(names_from = cat, values_from = time)

write_csv(df.sel, "pitch-cont_segments.csv")
