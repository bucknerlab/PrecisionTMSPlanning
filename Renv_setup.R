# Get command-line arguments
args <- commandArgs(trailingOnly = TRUE)
rlibpath <- args[1]

# Set the new library paths
.libPaths(rlibpath)

# Verify the library paths
cat("Library paths after adding new paths:\n")
print(.libPaths())

if(!require("readr")) {install.packages("readr", dependencies = TRUE, repos = "http://cran.us.r-project.org"); require ("readr")}
if(!require("ggplot2")) {install.packages("ggplot2", dependencies = TRUE, repos = "http://cran.us.r-project.org"); require ("ggplot2")}
if(!require("reshape2")) {install.packages("reshape2", dependencies = TRUE, repos = "http://cran.us.r-project.org"); require ("reshape2")}
if(!require("gtable")) {install.packages("gtable", dependencies = TRUE, repos = "http://cran.us.r-project.org"); require ("gtable")}
if(!require("formattable")) {install.packages("formattable", dependencies = TRUE, repos = "http://cran.us.r-project.org"); require ("formattable")}
if(!require("grid")) {install.packages("grid", dependencies = TRUE, repos = "http://cran.us.r-project.org"); require ("grid")}
if(!require("gridExtra")) {install.packages("gridExtra", dependencies = TRUE, repos = "http://cran.us.r-project.org"); require ("gridExtra")}
if(!require("gridtext")) {install.packages("gridtext", dependencies = TRUE, repos = "http://cran.us.r-project.org"); require ("gridtext")}
if(!require("data.table")) {install.packages("data.table", dependencies = TRUE, repos = "http://cran.us.r-project.org"); require ("data.table")}
if(!require("plotrix")) {install.packages("plotrix", dependencies = TRUE, repos = "http://cran.us.r-project.org"); require ("plotrix")}
if(!require("stringr")) {install.packages("stringr", dependencies = TRUE, repos = "http://cran.us.r-project.org"); require ("stringr")}
if(!require("plyr")) {install.packages("plyr", dependencies = TRUE, repos = "http://cran.us.r-project.org"); require ("plyr")}
if(!require("dplyr")) {install.packages("dplyr", dependencies = TRUE, repos = "http://cran.us.r-project.org"); require ("dplyr")}

