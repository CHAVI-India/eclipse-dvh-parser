extract_dvh_data <- function(files) {
  # Report Progress
  #p <- progressor(steps = length(files))
  
  # Ensure that a object is created to log the names of all the DVH extraction objects
  #txtfile <- "extraction_log.txt"
  
  # Create or reset the file to ensure it's empty
  #file.create(txtfile, showWarnings = FALSE)
  
  #start_time <- Sys.time()
  
  for (x in files) {
    #p() # Add a progress indicator
    a <- readLines(x)
    
    #randn <- sample(200:10000,1)
    #Read Patient ID and Store It
    
    id <- str_extract(a, "\\bPatient ID(.*?)$")
    id <- id[!is.na(id)]
    id <- str_remove_all(id, "\\bPatient ID|\\:")
    id <- trimws(id)
    
    
    #Read the Total Dose and the units in the DVH file
    
    total_dose <- str_extract(a, "Total dose(.*?)$")
    total_dose <- total_dose[!is.na(total_dose)]
    units <- str_extract(total_dose, "cGy|Gy")
    total_dose <- str_remove(total_dose, "Total(.*?)\\:")
    total_dose <- as.numeric(as.character(trimws(total_dose)))
    
    #Extract the Plan Name.
    
    plan_name <- str_extract(a, "Plan:(.*?)$")
    plan_name <- plan_name[!is.na(plan_name)]
    plan_name <- plan_name[1]
    plan_name <- str_remove(plan_name, "Plan:")
    plan_name <- trimws(plan_name)
    
    # Extract the Approval Status
    
    approval <- str_extract(a, "Approval Status(.*?)$")
    approval <- approval[!is.na(approval)]
    approval <- approval[1]
    approval <- str_remove(approval, "Approval Status:")
    approval <- trimws(approval)
    
    #Now we split the text files into parts.
    
    #This finds out how many fields will be generated per line of the text file after parsing sepearted by a whitespace.
    #From this we extract the maximum number. This is the maximum number of columns our dataframe should have.
    
    n_fields <-
      max(count_fields(a, tokenizer = tokenizer_delim(delim = " ")))
    
    # We create a single line with the word Remove repeated the number of times of n_field. This is called additonal_row
    additional_row <- paste(rep("Remove", n_fields), collapse = " ")
    
    
    # Add a blank row at the top of the file called "a" so that when read with the readr function below the max number of cols is created. This prevents the columns from being dropped by the read_table function.
    # This adds a line with 16 columns to the character vector read by Readlines command above and ensures that there are no parsing problems of missing data.
    t <- append(a, values = additional_row, after = 0)
    
    #We read the data from the text file into a tibble using the read_table function from readr,
    #We ensure that coloumn names are not created. We do not need them.
    b <-
      read_table(t,
                 col_names = F,
                 col_types = cols(.default = "c"))
    # Remove the additional row created above
    b <- b[-1,]
    
    #We obtain the row numbers at which the word Structure: appears. These are the rows from which the DVH description of the structure starts.
    #First we obtain the index numbers of the row -1
    rowscheck <- which(grepl("\\bStructure\\b", b$X1)) - 1
    
    #Then we obtain index numbers
    rowscheck2 <- which(grepl("\\bStructure\\b", b$X1))
    ##Append the two vectors created above
    rowscheck <- append(rowscheck, rowscheck2)
    ##Append 1 to the vector
    rowscheck <- append(1, rowscheck)
    ##Append the maximum number of rows to the vector
    rowscheck <- append(rowscheck, nrow(b))
    ##Sort the vector in ascending order
    rowscheck <- sort(rowscheck, decreasing = F)
    
    #Create a 2 column matrix with the row numbers at which we will split the dataframe
    rowm <- matrix(rowscheck, ncol = 2, byrow = T)
    
    #Now split the dataframe into a list of dataframes based on the row numbers. Note the value 1 in apply means the function is applied to the row and not the column.
    bl <- apply(rowm, 1, function(x)
      b[c(x[1]:x[2]), ])
    
    #The first dataframe in the list should have general information on the Patient. The rest of the dataframes will have DVH information on the structure.
    #Hence we remove the first dataframe. This reduces the size of object in memory.
    bl <- bl[-1]
    
    #Create a list of structure set names.
    str_list <- str_extract(a, "^Structure:(.*?)$")
    str_list <- str_list[!is.na(str_list)]
    str_list <- str_remove_all(str_list, "\\bStructure\\:")
    str_list <- trimws(str_list)
    str_list <- as.vector(str_list)
    
    #Append the structure names to the list of dataframes created above.
    #Make a new coloumn named structure.
    bl <- mapply(cbind, bl, "structure" = str_list, SIMPLIFY = F)
    
    ## Collect mean, median, minimum and maximum dose of the structures with the same methodology.
    ## We start with Mean dose (dmean)
    
    dmean <- str_extract(a, "^Mean(.*?)$")
    dmean <- dmean[!is.na(dmean)]
    dmean <- str_remove_all(dmean, "Mean(.*?)\\:")
    dmean <- as.numeric(as.character(trimws(dmean)))
    
    ##Then we extract the Median Dose (D50)
    d50 <- str_extract(a, "^Median(.*?)$")
    d50 <- d50[!is.na(d50)]
    d50 <- str_remove_all(d50, "Median(.*?)\\:")
    d50 <- as.numeric(as.character(trimws(d50)))
    
    ##Then we extract the Minimum Dose (dmin)
    
    dmin <- str_extract(a, "^Min(.*?)$")
    dmin <- dmin[!is.na(dmin)]
    dmin <- str_remove_all(dmin, "Min(.*?)\\:")
    dmin <- as.numeric(as.character(trimws(dmin)))
    
    ##Then we extract the Maximum Dose (dmax)
    
    dmax <- str_extract(a, "^Max(.*?)$")
    dmax <- dmax[!is.na(dmax)]
    dmax <- str_remove_all(dmax, "Max(.*?)\\:")
    dmax <- as.numeric(as.character(trimws(dmax)))
    
    ##We also extract the Volume (vol)
    
    vol <- str_extract(a, "^Volume(.*?)cm(.*?)$")
    vol <- vol[!is.na(vol)]
    vol <- str_remove_all(vol, "Volume(.*?)\\:")
    vol <- as.numeric(as.character(trimws(vol)))
    
    ##Join them in a data frame
    
    pointdoses <- data.frame(str_list, vol, dmean, d50, dmin, dmax)
    
    ##Add information on MR Number, prescribed dose and dose units in the same dataframe.
    pointdoses$id <- id[1]
    pointdoses$prescribed_dose <- total_dose[1]
    pointdoses$dose_unit <- units[1]
    #pointdoses$date <- date[1]
    pointdoses$plan_name <- plan_name[1]
    
    
    ##Check if the dose is relative dose or absolute dose
    
    dose_type <- str_extract(a, "\\bMin(.*?)$")
    dose_type <- dose_type[!is.na(dose_type)]
    dose_type <- str_extract(dose_type, "\\%|cGy|Gy")
    pointdoses <- cbind(pointdoses, dose_type)
    
    #Then we convert the doses to absolute dose to ensure consistency as well as to ensure that dose volume data is reported in units of dose.
    
    pointdoses$dmean <-
      as.numeric(ifelse(
        pointdoses$dose_type == "%",
        (pointdoses$prescribed_dose * pointdoses$dmean / 100),
        pointdoses$dmean
      ))
    pointdoses$d50 <-
      as.numeric(ifelse(
        pointdoses$dose_type == "%",
        (pointdoses$prescribed_dose * pointdoses$d50 / 100),
        pointdoses$d50
      ))
    pointdoses$dmin <-
      as.numeric(ifelse(
        pointdoses$dose_type == "%",
        (pointdoses$prescribed_dose * pointdoses$dmin / 100),
        pointdoses$dmin
      ))
    pointdoses$dmax <-
      as.numeric(ifelse(
        pointdoses$dose_type == "%",
        (pointdoses$prescribed_dose * pointdoses$dmax / 100),
        pointdoses$dmax
      ))
    
    #Then we remove the dose indicator coloumn
    
    pointdoses <- subset(pointdoses, select = -c(dose_type, dose_unit))
    
    
    #Now we strip unnecessary rows from the dataframe which do not have the dose volume data.
    #We have already stored the information about patient id etc previously.
    #We will however add the patient ID into the dataframe.
    
    bl <- mapply(cbind, bl, "id" = id, SIMPLIFY = F)
    
    #We will also add information of the date and plan names into the dataframe
    
    #bl <- mapply(cbind,bl,"date"=date,SIMPLIFY=F)
    bl <- mapply(cbind, bl, "plan" = plan_name, SIMPLIFY = F)
    ##Some dose volume histograms have  absolute dose while others have relative dose. We need to add information to the effect.
    ##First we add information on dose type
    
    bl <- mapply(cbind, bl, "dose_type" = dose_type, SIMPLIFY = F)
    
    ##Check if the volumes are relative or absolute that is in cc
    
    vol_type <- str_extract(a, "^Volume(.*?)$")
    vol_type <- vol_type[!is.na(vol_type)]
    vol_type <- str_extract(vol_type, "\\%|cm")
    
    # In plan sums, relative volume can be exported. In this case the above logic for defining the type of volume for DVH data will fail.
    
    vol_type2 <-
      str_extract(a, "Ratio of Total Structure Volume \\[\\%\\]")
    vol_type2 <- vol_type2[!is.na(vol_type2)]
    
    # This function will change vol_type object
    vol_type <- ifelse(length(vol_type2) > 0,
                       str_replace(vol_type, "cm", "%"),
                       vol_type)
    
    
    
    ##Then we add information on Volume type
    
    bl <- mapply(cbind, bl, "vol_type" = vol_type, SIMPLIFY = F)
    
    #Select all rows in the dataframe that start with a number in the first position in th first row. Note that we had to change this important bit otherwise rows starting with a special character can get selected also.
    #All eclipse DVHs files have the feature that the rows in which dose information is available is starting with a number.
    bl <- lapply(bl, function(x)
      x[grepl("^\\d", x$X1), ])
    
    dvhdata <- bind_rows(bl)
    
    
    ##In eclipse the order of dose coloumns changes based on what was selected. If relative dose was exported first row is percentage dose, while if the absolute dose was exported, then the first row is absolute dose.
    ##Similiarly, for volume depending on the type of export selected, the notation changes.
    ##Below we change coloumn names based on rules depending on the type of export option selected.
    ##Furthermore in case the DVH is of plan sum then only two coloumns will be exported. First row with the dose and 2nd with the volume.
    
    plansum <- str_extract(a, "Comment(.*?)$")
    plansum <- plansum[!is.na(plansum)]
    plansum <- ifelse(grepl("one plan", plansum), "single", "sumplan")
    
    names(dvhdata)[names(dvhdata) == "X1"] <-
      ifelse(
        plansum == "sumplan",
        "absolute_dose",
        ifelse(dose_type[1] == "%", "relative_dose", "absolute_dose")
      )
    names(dvhdata)[names(dvhdata) == "X2"] <-
      ifelse(
        plansum == "sumplan",
        "volume",
        ifelse(dose_type[1] == "%", "absolute_dose", "relative_dose")
      )
    names(dvhdata)[names(dvhdata) == "X3"] <-
      ifelse(plansum == "sumplan", "X3", "volume")
    
    ##Rename the volume coloumn created above to relative or absolute based on the previously extracted data.
    names(dvhdata)[names(dvhdata) == "volume"] <-
      ifelse(vol_type[1] == "%", "relative_volume", "absolute_volume")
    
    #Make columns of relative dose, relative volume, absolute volume and absolute dose if they do not exist in the dataframe. Fill them with NA in that case
    
    check_names <-
      c("relative_volume",
        "absolute_volume",
        "relative_dose",
        "relative_volume")
    
    #Keep the selected coloumns only. Remove rest.
    
    for (name in check_names) {
      if (!name %in% colnames(dvhdata)) {
        dvhdata[, name] <- NA
      }
    }
    
    #Select the proper coloumns
    dvhdata <-
      dvhdata %>% select(
        id,
        structure,
        absolute_dose,
        absolute_volume,
        relative_dose,
        relative_volume,
        plan,
        dose_type,
        vol_type
      )
    
    ##Remove all coloumns where every value is a NA
    
    #dvhdata <- dvhdata[,which(unlist(lapply(dvhdata,function(x) !all(is.na(x)))))]
    
    ## Join with the original data
    pointdoses <-
      pointdoses %>% rename(structure = str_list) %>% select(-plan_name)
    
    data <- merge(pointdoses, dvhdata, by = c("id", "structure"))
    
    # Make sure that the absolute volume, relative volume, relative dose and absolute dose coloumns are numeric.
    data %>%
      mutate(across(
        c(
          absolute_dose,
          absolute_volume,
          relative_dose,
          relative_volume
        ),
        ~ as.numeric(.)
      )) -> data
    
    id <-
      str_replace_all(id, "\\/", "_") # We cannot use / in the name as it will create a subdirectory. hence we use a _
    # In the following steps we will create a plan name object.
    plan_name <- str_replace_all(plan_name, "[^a-zA-Z0-9 ]", " ")
    plan_name <- str_replace_all(plan_name, "\\s+", " ")
    plan_name <-
      str_to_lower(str_trim(str_replace_all(plan_name, " ", "_")))
    # Create a file name concatenating the plan name with ID
    fname <-
      paste(trimws(id), plan_name, ".csv", sep = "") # Name for CSV file
    
    # Write a csv file with the data
    write_csv(x = data, path = fname) #Save as parquet which can be queried as a dataset later on.
    # fname1 <- paste(trimws(id),plan_name,".parquet",sep = "") #Save it in the directory for the parsed DVH objects
    # write_parquet(x = data,sink=fname1) #Save as parquet which can be queried as a dataset later on.
    
    #write(paste("DVH Object created:",fname,sep=" "),file = txtfile,append = TRUE ) #Finally write the names of the object created in a text file
  }
  
  #end_time <- Sys.time()
  #time_taken <- end_time-start_time
  #print(time_taken)
  
}