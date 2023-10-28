mypackages <- c("shiny","gridlayout","bslib","tidyverse")

checkpkg <- mypackages[!(mypackages %in% installed.packages()[,"Package"])]

if(length(checkpkg)) install.packages(checkpkg, dependencies = TRUE)


library(shiny)
library(gridlayout)
library(bslib)
library(tidyverse)


# Source the file containing the extract_dvh_data function
source("dvh_functions.R")

ui <- grid_page(
  theme = bs_theme(
    bootswatch = "vapor",
    enable_gradients = TRUE,
    font_scale = 0.95
  ),
  layout = c(
    "header              header               header              ",
    "upload_instructions process_instructions process_instructions",
    "upload              extract              download            "
  ),
  row_sizes = c("75px",
                "1.06fr",
                "0.94fr"),
  col_sizes = c("410px",
                "1.11fr",
                "0.89fr"),
  gap_size = "1rem",
  grid_card_text(
    area = "header",
    content = "Eclipse DVH Data Extractor",
    alignment = "start",
    is_title = TRUE
  ),
  grid_card(
    area = "upload",
    full_screen = TRUE,
    card_header(strong("Step 1: Upload DVH File(s)")),
    card_body(
      fileInput(
        'files',
        'Click Browse to select DVH file(s)',
        accept = c('.txt'),
        multiple = TRUE
      ),
      p(
        "Please upload only .txt files. .csv and .xls files are not accepted."
      ),
      strong("Only DVH data exported from Eclipse TPS (Varian) are supported !")
    )
  ),
  grid_card(
    area = "extract",
    full_screen = TRUE,
    card_header(strong("Step 2: Extract DVH(s)")),
    card_body(
      actionButton(
        inputId = "process",
        label = "Click here to extract Data",
        class = "btn-lg btn-primary"
      ),
      br(),
      p(
        "Please wait while the processing is completed. You can see the progress bar on the bottom right. The number of extracted files will be displayed at the bottom after data extraction has been completed."
      )
    ),
    card_footer(textOutput(outputId = "status"))
  ),
  grid_card(
    area = "download",
    full_screen = TRUE,
    card_header(strong("Step 3: Download DVH(s)")),
    card_body(
      downloadButton('downloadData', 'Download Files', class = "btn-lg btn-secondary"),
      br(),
      p(
        "Click the Download button to download the zip file with extracted DVH. All the uploaded files will be deleted after you close the window or tab !"
      )
    )
  ),
  grid_card(area = "upload_instructions",
            card_body(markdown(
              mds = c(
                "#### File Requirement",
                "To start the process of DVH extraction we need to have the files in a specific format. This application requires that the files are saved as a text file. That is they should have a .txt extension. The final extracted DVH will be in a CSV file format that can be easily read by most statistical software. ",
                "",
                "#### Recommendations",
                "1. Please try to extract DVH from plan sums if available. This ensures that full dose data is available.",
                "2. Always try to select the absolute dose and absolute volume. This gives maximum flexibility in data analysis. ",
                "3. Keep a fine dose grid (10 cGy or less) to ensure that you can use the data properly.",
                "4. When multiple files are to be extracted ensure that they the same dose grid for easier analysis (has no impact on this function)."
              )
            ))),
  grid_card(area = "process_instructions",
            card_body(markdown(
              mds = c(
                "After you have uploaded the file(s), please click the button to extract the data from the DVH files. ",
                "The data elements that will be extracted are:",
                "1. Patient ID (id)",
                "2. Structure name (structure)",
                "3. Volume in cc (vol)",
                "4. Mean (dmean), Median (d50), Minimum (dmin) and Maximum (dmax) doses",
                "5. Prescribed dose (prescribed_dose) if available",
                "6. Absolute Dose (absolute_dose),Absolute Volume (absolute_volume),Relative Dose (relative_dose), Relative Volume (relative_volume). The columns to be extracted depend on the type of export option chosen.",
                "7. Plan name (plan) ",
                "8. Dose and Volume type (dose_type & vol_type): These are indicators to help understand the units of the dose and volume extracted ",
                "",
                "The extracted data will be arranged in rows with one row representing a single dose volume bin. The structure name, mean, median dose and other information will be repeated. ",
                "After the processing is complete, click the ***Download Files*** button to download the files.",
                "Eclipse allows export of absolute and relative dose for single plans and absolute dose only for plan sums. Absolute and relative volumes can be exported for both single plans and plan sums. Thus for example if the user had chosen to export the absolute dose and the relative volume then absolute volume and relative dose coloumns will remain empty.",
                "",
                "***Eclipse does not provide prescribed dose for plan sums.***"
              )
            )))
)


server <- function(input, output, session) {
  observeEvent(input$process, {
    inFiles <- input$files
    
    if (is.null(inFiles))
      return(NULL)
    
    withProgress(message = "Now", value = 0 , {
      n <- length(inFiles)
      
      # Process each file in a loop
      for (i in seq_along(inFiles$datapath)) {
        extract_dvh_data(inFiles$datapath[i]) # This is the name of the function used to extract DVH data
        incProgress(1 / n, detail = paste("Extracting DVH", i))
      }
    })
    
    # Zip the parquet files (they will be in the current directory after running the function)
    zip(zipfile = "processed_data.zip", files = dir(pattern = "*.csv"))
    
    output$status <-
      renderText({
        paste(length(inFiles$name), "files extracted successfully!")
      })
  })
  
  output$downloadData <- downloadHandler(
    filename = function() {
      paste("processed_data.zip")
    },
    content = function(file) {
      file.copy("processed_data.zip", file)
    }
  )
  
  session$onSessionEnded(function() {
    cat("Session Ended\n")
    unlink("*.csv")
    unlink("processed_data.zip")
  })
  
}

shinyApp(ui = ui, server = server)
