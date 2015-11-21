
# scrape GitHub CRAN mirror
# source("scrape_has_po.R")

# open scraped contents from local file
cran_repos <- readRDS("data/gh_cran_repos.RDS")
pkg_contents <- readRDS("data/gh_pkg_contents.RDS")

# extract package/repo names from `cran_repos`
pkg_names <- vapply(cran_repos, function(x) x$name, character(1))
names(pkg_contents) <- pkg_names


# identify `/po` directories
pkg_has_po <- vapply(pkg_contents, function(x) {
    "po" %in% sapply(x$tree, `[[`, "path")
  },
  logical(1)
)

# tabulate
table(pkg_has_po)

# identify packages
pkg_names[which(pkg_has_po)]


pkgs_with_po <- pkg_names[pkg_has_po]

# Download the pkgs with po to a new library
# (dependencies get downloaded too)
new_r_lib <- "~/r_lib_po"
dir.create(new_r_lib)
install.packages(pkgs_with_po, lib = new_r_lib)

# Did they all install OK?
installed <- dir(new_r_lib)
fails <- setdiff(pkgs_with_po, installed)


# For each po pkg, count the number of subdirectories in the po directory.
n_translations <- vapply(
  installed,
  function(x)
  {
    po_files <- dir(
      file.path(new_r_lib, x, "po")
    )
    length(po_files)
  },
  integer(1)
)

# Data for pkgs that Richie couldn't install, by manual inspection
# EuclideanMaps has a POT file but no translations
n_translations <- c(
  n_translations, 
  colorout = 13,
  Rigroup = 1,
  ROracle = 10
)
  

# Count number of translations
library(plyr)
n_trans_data <- count(n_translations)

saveRDS(n_trans_data, "data/n_translations.rds")

# Visualize the number of translations
library(ggplot2)
(p <- ggplot(n_trans_data, aes(x, freq)) +
  geom_histogram(binwidth = 1, stat = "identity") +
  xlab("Number of translations") +
  ylab("Count")
)  

  
