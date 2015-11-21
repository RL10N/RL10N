
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
(has_po <- pkg_names[which(unlist(pkg_has_po))])

langs <- setNames(lapply(has_po, function(x) {
    r <- try(gh("/repos/cran/:repo/contents/po", repo = x))
    if(inherits(r, "try-error")) {
        return(NULL)
    } else {
        return(sapply(r, `[[`, "name"))
    }
}), has_po)

saveRDS(langs, "gh_po_langs.RDS")
# langs <- readRDS("gh_po_langs.RDS")

# find languages
translations <- unlist(langs)
# remove .pot, .mo, etc. files
translations <- translations[grepl(".po$", translations)]
# remove file extensions
translations <- sub(".po$", "", translations)

# remove R-level/C-level distinction
translations2 <- sub("^[[:alnum:][:punct:]]+-", "", translations)

# remove two malformed names
translations2 <- translations2[!translations2 == "RcmdrPlugin.EZR"]
translations2[translations2 == "en@quot"] <- "en"

# plot
par(mar = c(4, 6, 0, 1))
barplot(sort(table(translations2), decreasing = TRUE), xlab = "Number of package-level translations", 
        cex.names = 0.6, las = 1, horiz = TRUE, xaxs = "i")
dev.copy(png, file = "po_distribution.png", width = 1000, height = 1000, res = 200)
dev.off()



