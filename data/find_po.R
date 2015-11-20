
# scrape GitHub CRAN mirror
# source("scrape_has_po.R")

# open scraped contents from local file
cran_repos <- readRDS("gh_cran_repos.RDS")
pkg_contents <- readRDS("gh_pkg_contents.RDS")

# extract package/repo names from `cran_repos`
pkg_names <- vapply(cran_repos, function(x) x$name, character(1))

# identify `/po` directories
pkg_has_po <- lapply(pkg_contents, function(x) {
    "po" %in% sapply(x$tree, `[[`, "path")
})

# tabulate
table(unlist(pkg_has_po))

# identify packages
pkg_names[which(unlist(pkg_has_po))]
