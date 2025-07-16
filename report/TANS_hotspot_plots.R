# Get command-line arguments
args <- commandArgs(trailingOnly = TRUE)
rlibpath <- args[1]
sub <- args[2]
root <- args[3]
conditions <- strsplit(args[4], ",")[[1]]
Ein <- args[5]

cat("Arguments received:\n")
cat(args, sep = "\n")

# Open a null device 
pdf(NULL)

# Ensure any open graphics devices are closed
graphics.off()

# Set the new library paths
.libPaths(rlibpath)

# Verify the library paths
cat("Library paths after adding new paths:\n")
print(.libPaths())

if(!require("readr")) {install.packages("readr", dependencies = TRUE, repos = "http://cran.us.r-project.org"); require ("readr")}
if(!require("ggplot2")) {install.packages("ggplot2", dependencies = TRUE, repos = "http://cran.us.r-project.org"); require ("ggplot2")}
if(!require("reshape2")) {install.packages("reshape2", dependencies = TRUE, repos = "http://cran.us.r-project.org"); require("reshape2")}

library(grid)

avoidance <- "A0"
label <- ""

blank <- grid.rect(gp=gpar(fill="white", lwd = 0, col = "white"))
percents <- c("99.9 %", "99.8 %","99.7 %","99.6 %","99.5 %","99.4 %","99.3 %","99.2 %","99.1 %","99.0 %")

networks_ordered_disp <- c("DN-A", "DN-B", "LANG", "FPN-A", "FPN-B", "dATN-A", "dATN-B", "SAL/PMN", "CG-OP", "PM-PPr", "VIS-C", "VIS-P", "SMOT-A", "SMOT-B", "AUD")

rgb_colors <- c("100 49 73",
                "205 61 77",
                "11 47 255",
                "240 147 33",
                "228 228 0",
                "10 112 33",
                "98 206 61",
                "254 188 236",
                "184 89 251",
                "66 231 206",
                "119 17 133",
                "170 70 125",
                "73 145 175",
                "27 179 242",
                "231 215 165")

hex_colors <- sapply(strsplit(rgb_colors, " "), function(rgb_colors)
                    rgb(rgb_colors[1], rgb_colors[2], rgb_colors[3], maxColorValue=255))

wd_taskdata <- root
setwd(wd_taskdata)

path <- paste(root, sub, Ein, "report", "barplot", sep="/")

# Check if the directory exists, and if not, create it
if (!dir.exists(path)) {
  dir.create(path, recursive = TRUE)
}

for (c in 1:length(conditions)) {
  data.sub <- read_csv(paste(root, sub, Ein, "report", "hotspot_values",
                             paste0(sub, "_", conditions[c], "_", avoidance, "_hotspotval", label, ".csv"), sep="/"))
  data_long <- reshape2::melt(data.sub, id.vars = "Network", measure.vars = paste0("V_p99.", 0:9))
  # Remove the "V_" prefix and add a "%" sign to the 'variable' column
  data_long$variable <- gsub("V_p", "", data_long$variable)  # Remove 'V_p'
  data_long$variable <- paste0(data_long$variable, " %")     # Add ' %'
  data_long$Network <- factor(data_long$Network, levels = networks_ordered_disp)
  data_long$Percentile <- factor(data_long$variable, levels = percents)
  
  p1 <- ggplot2::ggplot(data_long, aes(x = Percentile, y = value, fill = Network)) +
    geom_bar(stat = "identity", position = "stack") +
    coord_flip() +
    scale_fill_manual(limits = networks_ordered_disp, values = hex_colors) +
    labs(title = "",
         x = "Threshold", 
         y = "Percent",
         fill = "Network") +
    theme_minimal() +
    theme(legend.position = "none",
          plot.title = element_text(hjust = 0.5, size = 22, family = "Helvetica", colour = "black"), 
          plot.title.position = "plot",  # Ensure title is centered in the plot area
          axis.title = element_text(size = 35, family = "Helvetica", colour = "black"), 
          axis.text = element_text(size = 30, family = "Helvetica", colour = "black", vjust = 0.1),
          panel.grid.major = element_blank(), panel.grid.minor = element_blank(),
          panel.border = element_blank())  # Remove plot border
  # print(plot)
  ggsave(paste(sub, "_", conditions[c], "_", avoidance, "_barplot", label, ".png", sep=""), 
         plot = p1, device = "png", width = 10, height = 7, dpi= 300, unit= "in", 
         path = path)
  
  # Close any open graphics devices
  graphics.off()
}

if (file.exists("Rplots.pdf")) {
  file.remove("Rplots.pdf")
}
