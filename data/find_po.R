library(plyr)
library(magrittr)
library(ggplot2)
library(stringi)

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
(pkgs_with_po <- pkg_names[pkg_has_po])

# Get the contents of the po dir
if(!file.exists("data/gh_po_langs.RDS"))
{
  langs <- setNames(lapply(pkgs_with_po, function(x) {
      r <- try(gh("/repos/cran/:repo/contents/po", repo = x))
      if(inherits(r, "try-error")) {
          return(NULL)
      } else {
          return(sapply(r, `[[`, "name"))
      }
  }), has_po)
  saveRDS(langs, "data/gh_po_langs.RDS")
} else
{
  langs <- readRDS("data/gh_po_langs.RDS")
}

# Count the number of translations by pkg
# Do this next bit in two steps so we can reuse translations_by_lang
translations_by_lang <- lapply(
  langs,
  function(x)
  {
    po_files <- x[grepl(".po$", x)]
    po_files %>%
      stri_replace_first_regex("^R-", "") %>%
      stri_replace_first_regex("\\.po$", "") %>%
      stri_replace_first_regex("RcmdrPlugin.EZR", "ja") %>%
      stri_replace_first_regex("(?:orloca|Rigroup|RcmdrPlugin\\.[[:alnum:]]+)[-]?", "") %>%
      stri_replace_first_fixed("en@quot", "en") %>%
      unique
  }
)

n_translations_with_po <- vapply(
  translations_by_lang,
  length,
  integer(1)
)

# Add in some zeroes for pkgs without a po dir
pkgs_without_po <- pkg_names[!pkg_has_po]
n_translations_without_po <- setNames(
  integer(length(pkgs_without_po)),
  pkgs_without_po
)

# Count number of translations
n_translations_per_pkg <- count(
  c(n_translations_with_po, n_translations_without_po)
)

saveRDS(n_translations_per_pkg, "data/n_translations_per_pkg.rds")

# Visualize the number of translations per pkg
(p_per_pkg <- n_translations_per_pkg %>% 
  ggplot(aes(x, freq)) +
  geom_histogram(binwidth = 1, stat = "identity") +
  xlab("Number of translations") +
  ylab("Count")
)  


# Count use of languages
n_translations_by_lang <- translations_by_lang %>%
  unlist(use.names = FALSE) %>%
  count
n_translations_by_lang$x <- with(n_translations_by_lang, reorder(x, freq))

saveRDS(n_translations_by_lang, "data/n_translations_by_lang.rds")

# Visualize the number of translations to each lang
(p_by_lang <- n_translations_by_lang %>% 
  ggplot(aes(x, freq)) +
  geom_histogram(binwidth = 1, stat = "identity") +
  coord_flip() +
  xlab("Language") +
  ylab("Count")
)
