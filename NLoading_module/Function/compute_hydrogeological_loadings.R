source('./Main_functions.R')
source('./Gaseous_functions.R')
source('./ExploratoryAnalysis_module/Command function/MAIN_plot_functions.R')
source('./GIS_module/Function/GW_computation_functions.R')

get_hydro_data <- function()
{
  folder_path <-  select_maindata_pattern('Hydrogeological')
  files <- store_folder_files(folder_path)
  
  files <- files[which(grepl('main', files)==T)]
  read_file <- read.csv(files)
  return(read_file)
}

vlook_hydrogeological_data <- function(year,tier_leaching)
{
  df <- get_hydro_data()
  gw_db <- load_gw_data(year, tier_leaching)
  
  merged_df <- merge(df, gw_db, 'aquifer_ID')
  
  merged_df$leaching_mg<-  merged_df$leaching_mg/1000000000 #to tonnes N
  merged_df$drainage <- merged_df$drainage/1000000000000 #km3
  
  return(merged_df)
}

gather_hydro_data <- function(year, irrig_mode)
{
  gw_df <-get_modellingDf_file(paste0('nc_df_gw', year_prefix(year)), 'Nc', irrig_mode)[, -1] #in kg N
  colnames(gw_df)[1] <- 'aquifer_ID'
  df <- get_hydro_data()
  
  df <- merge(gw_df, df, 'aquifer_ID')
  return(df)
}


## Load main dataset of both years
#df99 <- vlook_hydrogeological_data(1999, 'source_leaching')
#df09 <- vlook_hydrogeological_data(2009,  'source_leaching')
df99 <- gather_hydro_data(1999, 'Default')
df09 <- gather_hydro_data(2009, 'Default')
s09 <- subset(df09, main_hydro != 'massif')

## MEAN CHANGES IN GW WITHIN EACH HU
db99 = df99 %>% group_by(main_hydro) %>% summarise_all(mean)
db09 = df09 %>% group_by(main_hydro) %>% summarise_all(mean)

View(s09)
colnames(db09)
#RELATIVE MEAN CHANGE
drainage_ratio <- (db09$drainage-db99$drainage)/db99$drainage*100
leaching_ratio <- (db09$N.loads.mg.N.-db99$N.loads.mg.N.)/db99$N.loads.mg.N.*100
nol_ratio <- (db09$nc-db99$Nc.mg.NO3.L.)/db99$Nc.mg.NO3.L.*100
ratio_df <- cbind(db09[, 1], leaching_ratio, drainage_ratio, nol_ratio)

#ABSOLUTE MEAN CHANGE
drainage_diff <- db09$drainage-db99$drainage
leaching_diff <- db09$N.loads.mg.N.-db99$N.loads.mg.N.
nol_diff <- db09$Nc.mg.NO3.L.-db99$Nc.mg.NO3.L.
diff_df <- cbind(db09[,1], drainage_diff, leaching_diff, nol_diff)


sum99 = df99 %>% group_by(main_hydro) %>% summarise(sum=sum(N.loads.mg.N.))
sum09 = df09 %>% group_by(main_hydro) %>% summarise(sum=sum(N.loads.mg.N.))
sum_diff <- sum09$sum-sum99$sum
sum_prop_diff <- sum_diff/sum99$sum

uaa_df <- c(-23000, -66000, -11000, -94000)
leaching_rate <- sum_diff*1000*1000/(uaa_df*10) #kg N/ha/yr
sum_df <- cbind(sum09[, 1], sum_diff, sum_prop_diff, uaa_df, leaching_rate)


absolute_change99<- df99 %>% group_by(main_hydro) %>% summarise(leaching_sum=sum(N.loads.mg.N.), drainage_sum=sum(drainage))
absolute_change09 <- df09 %>% group_by(main_hydro) %>% summarise(leaching_sum=sum(N.loads.mg.N.), drainage_sum=sum(drainage))

absolute_change09$nc <- absolute_change09$leaching_sum/absolute_change09$drainage_sum
absolute_change99$nc <- absolute_change99$leaching_sum/absolute_change99$drainage_sum

#Changes in relative importance
nl_prop <- (absolute_change09$leaching_sum-absolute_change99$leaching_sum)/absolute_change99$leaching_sum*100
drain_prop <- (absolute_change09$drainage_sum-absolute_change99$drainage_sum)/absolute_change99$drainage_sum*100
nc_prop <- (absolute_change09$nc-absolute_change99$nc)/absolute_change99$nc*100
df_prop <- cbind(absolute_change09[, 1], nl_prop, drain_prop, nc_prop)

#changes in absolute values
diff_abso <- absolute_change09[, seq(2, 4)]-absolute_change99[, seq(2,4)]
diff_abso_df <- cbind(absolute_change09[, 1], diff_abso)
View(diff_abso)


