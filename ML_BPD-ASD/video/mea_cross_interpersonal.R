# (C) Irene Sophia Plank
# 
# This script takes the output of Motion Energy analysis as well as OpenFace and 
# calculates cross-region INTERpersonal synchronisation. This script is run
# after the mea_intrapersonal.R script and uses the data produced there

# BPD participants always sit on the right, if there is one, COMP on the left. 
# In MEA, the order of the ROI is: R_head, R_body, L_head, L_body

# clean workspace
rm(list = ls())

# load libraries
library(tidyverse)
library(rMEA)
library(moments)       # kurtosis, skewness

# set path to MEA files
dt.path = c("/media/emba/emba-2/ML_BOKI/MEA_preprocessed_Empatica",
            "/media/emba/emba-2/ML_BOKI/ML_data")

# load workspaces
load(file.path(dt.path[1], "intra.RData"))
load(file.path(dt.path[1], "intra_sanitycheck.RData"))

# reset path to output
dt.path = c("/media/emba/emba-2/ML_BOKI/MEA_preprocessed_Empatica",
            "/media/emba/emba-2/ML_BOKI/ML_data")

# wrangle the dataframes so they can be combined
df.MLASS = merge(
  alldata %>% rename("OF.headmov" = "value") %>% select(dyad, task, ID, frame, OF.headmov),
  alldata_mea %>% rename("MEA.bodymov" = "value") %>%
    group_by(ID, dyad, task) %>%
    mutate(
      frame = row_number() + 300
    ) %>% select(dyad, task, ID, frame, MEA.bodymov)
) %>%
  mutate(
    task = if_else(task == "hobbies", "H", "M"),
    dyad = paste0("ML_", dyad), 
    speaker = substr(ID, nchar(ID), nchar(ID)),
    ID = paste0(dyad, "_", speaker)
  ) %>%
  merge(., 
        read_csv(file.path(dt.path, "ML_indi_context.csv")) %>%
          rename("ID" = "Id") %>% 
          mutate(
            label = if_else(`dyad type` == "heterogeneous", "ASD-COMP", "COMP-COMP")
          ) %>% select(ID, label))

df = df %>%
  merge(., read_csv(file.path("/media/emba/emba-2/ML_BOKI/demoCentraXX", 
                              "BOKI_centraXX.csv")) %>%
          filter(substr(dyad, 1, 4) == "BOKI") %>%
          select(dyad, ID, label))

# combine them
df = rbind(df, df.MLASS)

# only keep the merged dataframe
rm(list = setdiff(ls(), c("df", "dt.path")))

# Initialize function to create a fake MEA object out of two vectors
# Input: 
#     * s1, s2: numeric vectors containing the values to be correlated
#     * sampRate: sampling rate per second
#     * s1Name, s2Name: name for the values to be correlated, default is "s1Name" and "s2Name"
# Output:
#     * fake MEA object that pretends to be a MEA object
#
fakeMEA = function(s1, s2, sampRate, s1Name = "s1Name", s2Name = "s2Name") {
  mea = structure(list(all_01_01 = structure(list(MEA = structure(list(
    s1Name = s1, s2Name = s2), row.names = c(NA, -length(s1)), class = "data.frame"), 
    ccf = NULL, ccfRes = NULL), id = "01", session = "01", group = "all", sampRate = sampRate, 
    filter = "raw", ccf = "", s1Name = s1Name, s2Name = s2Name, uid = "all_01_01", 
    class = c("MEA","list"))), class = "MEAlist", nId = 1L, n = 1L, groups = "all", sampRate = sampRate, 
    filter = "raw", s1Name = s1Name, s2Name = s2Name, ccf = "")
  return(mea)
}

# Time series synchronisation ---------------------------------------------

if (!file.exists(file.path(dt.path[1], "BOKI_CROSSsync.RData"))) {
  
  # Steps: 
  # 1) create fake MEA object using the fakeMEA function
  # 2) calculate ccf according to rMEA
  
  # create list to be filled with fakeMEA objects of the cross synchronisation
  ls.fakeX = c()
  
  # loop through all dyads
  sampRate = 30
  df.X.sync = data.frame()
  for (i in unique(df$dyad)){ 
    
    # initialise heatmaps
    dir.create(file.path(dt.path[1], 'pics'), showWarnings = FALSE)
    pdf(file.path(dt.path[1], 'pics', paste0(i, "_x.pdf")))
    
    # loop through tasks
    for (t in c("H", "M")) {
      
      # grab only relevant portions of df
      df.sel = df %>%
        filter(dyad == i & task == t) %>%
        arrange(ID, dyad, task, speaker, frame)
      
      # check if data frame is present
      if (nrow(df.sel) > 0) { 
        
        # loop through the two combinations
        for (j in list(c("OF.headmov", "MEA.bodymov", "LOF"), c("MEA.bodymov", "OF.headmov", "ROF"))){ 
          
          # prepare fake MEA components
          s1 = df.sel[df.sel$speaker == "L", j[1]] # AU for left L participant
          s2 = df.sel[df.sel$speaker == "R", j[2]] # AU for right R participant
          
          # create fake MEA object
          mea = fakeMEA(s1, s2, sampRate) 
          
          # time lagged windowed cross-correlations
          mea = MEAccf(mea, lagSec = 2, winSec = 7, incSec = 4, r2Z = T, ABS = T) 
          names(mea) = paste(i, t, j[3], sep = "_")
          
          # add object to fakeMEA list
          ls.fakeX = c(ls.fakeX, mea)
          
          # extract matrix with all ccf values over all lags and windows 
          df.ccf = mea[[1]][["ccf"]] 
          
          # configure heatmap
          par(col.main='white')                  # set plot title to white
          heatmap = MEAheatmap(mea[[1]])
          par(col.main='black')                  # set plot title back to black
          title(main = paste(t, j, sep = "_"))   # alternative title
          
          # peak picking
          L = apply(df.ccf[,1:floor(ncol(df.ccf)/2)], 1, max, na.rm =T ) 
          R = apply(df.ccf[,(floor(ncol(df.ccf)/2)+2):ncol(df.ccf)], 1, max, na.rm =T )
          df.dyad = as.data.frame(cbind(L,R)) %>%
            rownames_to_column(var = "window") %>%
            mutate(
              dyad = i,
              task = t,
              input = j[3],
              label = df.sel$label[1]
            ) %>%
            pivot_longer(cols = c("L", "R"), names_to = "speaker", values_to = "sync") %>%
            mutate(
              sync = if_else(sync != -Inf & !is.na(sync), sync, NA)
            )
          
          df.X.sync = rbind(df.X.sync, df.dyad)
        }
      }
    
    
    }
    dev.off()
    # show progress
    print(paste(i, "done"))
  }
  
  save(df.X.sync, ls.fakeX, file = file.path(dt.path[1], "BOKI_CROSSsync.RData"))
  
} else {
  
  load(file.path(dt.path[1], "BOKI_CROSSsync.RData"))
  
}

# calculate summary statistics
df.X.sync_NM = df.X.sync %>% 
  group_by(dyad, speaker, input, task, label) %>%
  summarise(across(where(is.numeric), 
                   .fns = 
                     list(min  = ~min(.,na.rm = T), 
                          max  = ~max(.,na.rm = T), 
                          md   = ~median(.,na.rm = T), 
                          mean = ~mean(.,na.rm = T), 
                          sd   = ~sd(.,na.rm = T), 
                          kurtosis = ~kurtosis(.,na.rm = T), 
                          skew = ~skewness(.,na.rm = T)
                     ), .names = "{.fn}")
  ) %>%
  pivot_wider(names_from = c(task, input), values_from = where(is.numeric),
              names_glue = "{.value}_{task}_{input}") %>%
  mutate(
    ID = paste0(dyad, "_", speaker)
  ) %>%
  relocate(ID, dyad, speaker, label)

# save to csv file
write_csv(df.X.sync_NM, file.path(dt.path[2], "BOKI_crossentrain_NM.csv"))

# clean workspace
rm(list = setdiff(ls(), c("df", "df.X.sync", "fakeMEA", "ls.fakeX", "dt.path",
                          "df.X.sync_NM")))

# save workspace
save.image(file.path(dt.path[1], "CROSSsync.RData"))

