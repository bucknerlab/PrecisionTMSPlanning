# Get command-line arguments
args <- commandArgs(trailingOnly = TRUE)
rlibpath <- args[1]
sub <- args[2]
root <- args[3]
conditions <- strsplit(args[4], ",")[[1]]
Ein <- args[5]

cat("Arguments received:\n")
cat(args, sep = "\n")

# Open a null device to prevent accidental plotting to Rplots.pdf
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

avoidance = "A0"
label <- ""

colortable <- read.csv(paste0(root, '/MASKS/ColorMap_15.txt'), header = TRUE)
colortable = colortable[, 2:5]
colortable$color <- rgb(colortable$R, colortable$G, colortable$B, maxColorValue = 255)
colnames(colortable)[1] = "Network"
coltab = colortable[, c(1, 5)]
net_of_interest = c("FPN-A", "FPN-B", "SAL", "CG-OP", "LANG", "DN-B", "DN-A", "dATN-A", "dATN-B")

xmin = 0.9 #41
incr = 0.2 #3
xmaxdisp = xmin+3*incr #50
xmax = xmaxdisp+0.1 #51.5
yval = 0.15 #0.0002

for (c in 1:length(conditions)) {

    path <- paste(root, sub, Ein, "/report/density/", sep = "/")

    # Check if the directory exists, and if not, create it
    if (!dir.exists(path)) {
        dir.create(path, recursive = TRUE)
    }
    
    N15_efield <- read_csv(paste(root, "/", sub, "/", Ein, "/report/efield_values/",
                                 sub, '_', conditions[c], '_', avoidance, '_efieldval', label, '.csv', sep = ""), show_col_types = FALSE)
    
    df = merge(N15_efield, coltab, by = "Network")
    
    # Replace "SAL/PMN" with "SAL" in the Network column
    df$Network <- gsub("SAL/PMN", "SAL", df$Network)
    
    dfreport = df[df$Network %in% net_of_interest, ]
    network_order = c("FPN-A", "FPN-B", "SAL", "CG-OP", "LANG", "DN-B", "DN-A", "dATN-A", "dATN-B")
    dfreport$Network <- factor(dfreport$Network, levels = network_order)
    
    # Example cumulative distribution function (CDF)
    cdf <- ecdf(dfreport$EfieldVal) # Assume dfreport is defined earlier
    
    # Calculate CDF values
    cdf_0_9 = cdf(xmin)
    cdf_1_5 = cdf(xmaxdisp)
    
    # Count elements greater than 0.9 and 1.5
    count_greater_0_9 = sum(dfreport$EfieldVal > xmin)
    count_greater_1_5 = sum(dfreport$EfieldVal > xmaxdisp)
    
    # Using paste() for formatted output
    output = paste(
        "CDF at 0.9:", cdf_0_9,
        "\nCDF at 1.5:", cdf_1_5,
        "\nCount of EfieldVal lower limit:", count_greater_0_9,
        "\nCount of EfieldVal upper limit:", count_greater_1_5,
        "done"
    )
    
    cat(output)
    
    # Create the plot
    p1 = ggplot(dfreport, aes(x = EfieldVal, fill = color)) + 
        geom_density(adjust = 0.3, color = NA) +  
        scale_fill_identity() + 
        facet_wrap(Network ~ ., nrow = length(unique(dfreport$Network)), strip.position = "top") +
        labs(x = "E-field magnitude (V/m)", y = "Network", fill = "Network") +
        theme_minimal() +
        theme(
            panel.grid.major = element_blank(),  # Remove major grid lines
            panel.grid.minor = element_blank(),  # Remove minor grid lines
            axis.line = element_line(color = "black", linewidth = 1),
            axis.ticks.length = unit(0.5, "cm"),  # Customize tick length
            axis.ticks = element_line(color = "black"),  # Customize tick color and size
            axis.text.y = element_blank(),  # Remove y-axis tick labels
            axis.ticks.y = element_blank(),  # Remove y-axis ticks
            strip.background = element_blank(),
            panel.spacing = unit(0, "lines"),
            strip.text.x = element_text(size = 37, hjust = 0, family = "Helvetica", color = "black"),
            axis.text.x = element_text(size = 32, family = "Helvetica", color = "black"),
            axis.title.y = element_text(size = 37, family = "Helvetica", color = "black", hjust = 0.5, margin = margin(r = -7)),  # Adjust hjust and margin here
            axis.title.x = element_text(size = 37, family = "Helvetica", color = "black"),
            plot.margin = margin(t = 0, r = 0, b = 0, l = 0)  # Adjust plot margins
        ) +
        scale_x_continuous(breaks = seq(xmin, xmaxdisp, by = incr)) +  # Include 0.9 on the x-axis
        coord_cartesian(xlim = c(xmin, xmax), ylim = c(NA, yval)) +
        geom_vline(xintercept = xmin + 2 * incr, linetype = "dashed", color = "black", linewidth = 2) +
        geom_vline(xintercept = xmaxdisp, linetype = "dashed", color = "black", linewidth = 2)
    
    # Save the plot
    ggsave(paste(sub, "_", conditions[c], '_', avoidance, "_density", label, ".png", sep = ""), 
           plot = p1, device = "png", width = 9.75, height = 12, dpi = 300, unit = "in", 
           path = paste(root, sub, Ein, "report/density/", sep = "/"))      
    
    # Close any open graphics devices
    graphics.off()
}

if (file.exists("Rplots.pdf")) {
  file.remove("Rplots.pdf")
}
