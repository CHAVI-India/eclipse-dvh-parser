# Welcome

This repository contains the code base for a Shiny application which enables users to extract dose volume histogram data from Eclipse Treatment Planning systems into a easy to analyze tabular format.

# Where is the app

A demo app is hosted at <https://santam.shinyapps.io/eclipse-dvh-parser/>

# Use the app locally

## Prerequisites

1.  **R:** You must have R installed on your computer. If you haven\'t already, you can download and install R from [The Comprehensive R Archive Network (CRAN)](https://cran.r-project.org/).

2.  **RStudio (Optional but Recommended):** While not strictly necessary, RStudio provides an integrated environment for running Shiny apps. You can download and install RStudio from [here](https://rstudio.com/products/rstudio/download/).

3.  **Git:** You need Git installed to clone the GitHub repository. If you haven't installed Git, you can get it from [here](https://git-scm.com/downloads).

4.  **Dependencies:** Before running the app, you'll need to install certain R packages. Specifically, this app relies on the `tidyverse` package.

## Installation steps

### 1. Clone the github repository

Open a terminal (or the command prompt on Windows) and navigate to the directory where you want to clone the repository. Run the following command:

```         
git clone https://santam.shinyapps.io/eclipse-dvh-parser/
```

### 2. Install required packages in R

If you haven\'t already installed the `tidyverse` package, you can do so using the following command in R or RStudio:

``` R
install.packages("tidyverse")
```

### 3. Set the working directory

Navigate to the cloned repository's directory in RStudio and click on the "More" option (three dots) at the top right of the Files pane, and then choose "Set As Working Directory".

Alternatively, you can use the `setwd()` function in R:

``` R
setwd("path/to/cloned/repository/eclipse-dvh-parser")
```

### 4. Launch the app

You can now run the app by executing the following commands in R or R studio

``` R
shiny::runApp("app.R")
```

This will start the Shiny app, and it should automatically open in a new browser window. If it doesn\'t, RStudio will provide a link in the console that you can click on to view the app.

# What is a Dose volume histogram (DVH)

A dose volume histogram is 2 dimensional visualization of the three dimensional radiation dose distribution. Most commonly we work with cumulative dose volume histograms which represent doses on the Y axis and volumes on the X axis. An alternative way of visualization is differential dose volume histograms.

# What is Eclipse

Eclipse is a treatment planning system designed by Varian Medical Systems (<https://www.varian.com/>). Radiotherapy treatment planning is done on such systems. DVH data can be exported from the treatment planning system in text files.

# Why this parser

The default export from Eclipse is the form of a text file that contains data in a mix of formats. The first section is the header section which contains details about the patient This is followed by information on the structure dose metrics. Finally a table shows the dose volume histogram data. This form of data cannot be readily ingested for analysis using statistical software and is difficult to put into a database.

An example of the file structure is shown below. Comments indicate the sections.

```         
==== This is the section of patient headers ===

Patient Name         : XXX
Patient ID           : XXX
Comment              : DVHs for a plan sum
Date                 : Friday, October XX, 2023 XX:XX:XX PM
Exported by          : XXX
Type                 : Cumulative Dose Volume Histogram
Description          : The cumulative DVH displays the percentage (relative)
                       or volume (absolute) of structures that receive a dose
                       equal to or greater than a given dose.
===== Plan information starts here=====
Plan sum: Plan Sum
Course: C1
Total dose [cGy]: not defined
% for dose (%): not defined


==== Structure dose volume metrics starts here====
Structure: Heart
Approval Status: Approved
Plan: Plan Sum
Course: C1
Volume [cm³]: 492.1
Dose Cover.[%]: 100.0
Sampling Cover.[%]: 100.0
Min Dose [cGy]: 1.5
Max Dose [cGy]: 453.0
Mean Dose [cGy]: 50.4
Modal Dose [cGy]: 2.5
Median Dose [cGy]: 32.9
STD [cGy]: 54.5
Equiv. Sphere Diam. [cm]: 9.8
Conformity Index: N/A
Gradient Measure [cm]: N/A
Dose Level [cGy]: 
==== Actual dose volume information starts here ====
Dose [cGy] Ratio of Total Structure Volume [%]
         0                       100
         1                       100
         2                   99.3185
         3                   97.2581
         4                   95.2901
         5                   93.4387
         6                   91.7192
         7                   90.0692
         8                    88.433
         9                   86.8056
        10                   85.1878
        11                   83.5731
        12                   81.9544
        13                   80.3383
        14                   78.7309
        15                   77.1274
        16                   75.5214
        17                   73.9237
        18                   72.3273
        19                   70.7358
        20                   69.1443
```

Another problem is Eclipse allows export of plans in different ways. For example it allows user to choose to export in absolute dose or relative dose (% of the prescribed dose) as well as absolute and relative volumes (% of the actual volume). The headers for these scenarios are different.

Finally there is the special case of plan sums - these are exported with absolute doses only but volumes can be relative or absolute.

Hence data extraction from these files is non-trivial and error prone if done manually.

# What does our parser do.

This function extracts and processes dose-volume histogram (DVH) data from the provided files. The DVH data provides a graphical representation of the distribution of dose within a structure (usually in radiation therapy). The function returns organized data that includes patient ID, total dose, dose units, plan name, approval status, and detailed DVH metrics for various structures.

## Parameters

-   **files**: A list of file paths to be processed. These files are expected to contain DVH data.

## Returns

The function processes each file and extracts:

-   Patient ID

-   Total dose and its units

-   Plan name

-   Approval status

-   Detailed DVH metrics for various structures, including mean, median, minimum, and maximum dose values.

## Internal Workflow

1.  Loop through each file in `files`.

2.  Extract essential details like Patient ID, Total Dose, Plan Name, and Approval Status using regular expressions.

3.  Process and organize the data into a structured format, ensuring consistency.

4.  Handle various export formats from Eclipse (a treatment planning system) that may differ based on user selections.

5.  Return processed DVH data.

## Dependencies

This function relies on various libraries and functions, which should be imported for the function to work properly:

-   `readLines` for reading the file.

-   Functions from `stringr` package like `str_extract` for extracting specific data patterns.

-   `read_table` from `readr` package for reading tabulated data.

-   `grepl` and `gsub` for pattern matching and substitution.

## Notes

It's important to provide files in the text format. The function relies heavily on specific patterns in the DVH data.
