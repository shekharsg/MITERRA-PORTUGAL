source('./Irrigation_module/Functions/Global_irrigation_functions.R')




## ----------------------- AVG NO3 DATA@MUNICIPALITY GETTERS -----------------------##
## ---------------------------------------------------------------------------------##

no3_path_year <- function(year) {
  #gives the fullpath of the year folder related to the avg NO3 data@municipality
  
  no3_path <- get_irrig_activity_data('NO3 sampling data')
  full_path <- disaggregate_year(no3_path, year)

  return(full_path)
}


no3_template <- function() {
  # creates template df for the different water sources
  
  df <- create_main_csv()
  df$spring <- 0
  df$superficial <- 0
  df$wells <- 0
  
  return(df)
}



## ----------------------- IRRIG WATER SOURCES -----------------------##
## -------------------------------------------------------------------##

get_no3_source_water <- function(aggregated, default_templat) {
  #gets water source of NO3 at the municipality scale
  
  no3_water_source <- get_irrig_activity_data('water_source')

  ifelse(aggregated==TRUE, 
         pattern <- '_aggregated', 
         pattern <- 'disaggregated')
  
  id_condition <- grepl(pattern, no3_water_source)
  
  file <- no3_water_source[id_condition]
  read_file <- read.csv(file)
  
  ifelse(default_templat==T,
            read_file <- read_file[, c(1,2,3,6,7,8)],
            read_file <- read_file)
  return(read_file)
  rm(list=c('no3_water_source', 'pattern', 'id_condition', 'file'))
}


get_no3_source_name <- function(year) {
  #gets the names of each source 
  #to be used in a loop to read each source
  
  no3_path <- no3_path_year(year)
  list_files <- list.files(no3_path)
  source_name <- gsub(pattern = '.csv', replacement = '', x = list_files)
  
  return(source_name)
  rm(list=c('no3_path', 'list_files'))
}


get_no3_source <- function(year, source) {
  #reads source file according to specified source
  #to be used in loop
  
  no3_path <- no3_path_year(year)
  source_path <- disag_folders_year(no3_path, year, source)
 # source_path <- substr(source_path, 1, nchar(source_path)-1) #correct the last "/"
  
  read_source <- read.csv(source_path)
  return(read_source)
  rm(list=c('no3_path'))
}

aggregate_no3_source <- function(year) {
  #aggregates all no3 into a unique dataset
  
  source_name <- get_no3_source_name(year)
  df <- create_main_csv()
  
  for (a in source_name) {
    read_source <- get_no3_source(year, a)
    colnames(read_source)[ncol(read_source)] <- a
    
    df <- cbind(df, read_source[, ncol(read_source)])
    colnames(df)[ncol(df)] <- a
    
  }
  return(df)
  rm(list=c('source_name', 'read_source'))
}


compute_number_existing_sources <- function(year) {
  #calculates the number of existing no3 sources for each municipality
  #d <- compute_number_existing_sources(2009)
  
  df <- aggregate_no3_source(year)
  df$ctr <- 0
  
  for (i in 4:(ncol(df)-1))
  {
    
    for (j in 1:nrow(df))
    {
      if (df[j,i]!='ND')
      {
        df[j, 'ctr'] <-  df[j, 'ctr']+1
      }
    }
  }
  
  return(df)
}


no3_source_condition_1 <- function(df) {
  #filter and fill a new dataset with the condition where there is only one irrigation source
  
  ctr <- df[, ncol(df)]
  select_condition_1 <- which(ctr==1) #number of source is 1
  
  main_df <- no3_template()
  
  for (i in 4:(ncol(df)-1))
  {
    for (j in select_condition_1)
    {
      if (df[j, i]!='ND')
      {
        main_df[j,i] <- 1
      }
    }
  }
  return(main_df)
}

condition_2_algorithm <- function(df) {
  #algorith to correct water source weights if there are only 2 sources
  
  existing_weights <- rowSums(df[, 4:ncol(df)])
  
  for (i in 4:ncol(df))
  {
    df[, i] <- round(df[, i]/existing_weights, 3)
  } 
  df <- data_cleaning(df)
  
  return(df)
  rm(list='existing_weights')
}

no3_source_condition_2 <- function(df) {
  #identify and correct water source weights to condition 2, N==2
  
  ctr <- df[, ncol(df)]
  select_condition_2 <- which(ctr==2) #number of source is 2
  
  source_df <- get_no3_source_water(T, T) 
  main_df <- no3_template()
  
  for (i in 4:(ncol(df)-1))
  {
    for (j in select_condition_2)
    {
      if (df[j, i]!='ND')
      {
        main_df[j,i] <- 1
        main_df[j,i] <- main_df[j,i]*source_df[j, i]
        
      }
    }
  }
  main_df <- condition_2_algorithm(main_df)
  return(main_df)
  rm(list=c('ctr, select_condition_2', 'source_df'))
}

no3_source_condition_3 <- function(df) {
  
  ctr <- df[, ncol(df)]
  select_condition_3 <- which(ctr==3)
  
  source_df <- get_no3_source_water(T, T) 
  main_df <- no3_template()
  
  for (i in 4:(ncol(df)-1))
  {
    for (j in select_condition_3)
    {
      main_df[j, i] <- source_df[j,i]
    }
  }
  return(main_df)
}


compute_corrected_water_sources <- function(year, write) {
  # computes the corrected water sources based on the (in)existence of NO3 data
  
  df <- compute_number_existing_sources(year)
  
  df1 <- no3_source_condition_1(df)
  df2 <- no3_source_condition_2(df)
  df3 <- no3_source_condition_3(df)
  
  df1[, 4:6] <- df1[, 4:6]+df2[, 4:6]+df3[, 4:6]
  
  if (write==TRUE) {
    print('Writing ...')
    write_annual_data(module_name = 'Irrigation_module', 
                      subfolder_name = 'Water_source', 
                      file = df1, 
                      filename = 'corrected_water_source', 
                      year = year)
    print('Finished!')
  }
  return(df1)
}

