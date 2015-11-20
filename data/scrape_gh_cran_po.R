# devtools::install_github("gaborcsardi/gh")
library("gh")

# retrieve all CRAN repos via the GitHub mirror
cran_repos <- list()
z <- 1
p <- 0
while (length(z)) {
    p <- p + 1
    z <- gh("/users/cran/repos", page = p)
    cran_repos <- append(cran_repos, z)
}

saveRDS(cran_repos, "gh_cran_repos.RDS")
# cran_repos <- readRDS("gh_cran_repos.RDS")

# extract package/repo names from `cran_repos`
pkg_names <- vapply(cran_repos, function(x) x$name, character(1))

# query directory tree for each repo
## API has 5000 request/hour rate limit
pkg_contents <- lapply(pkg_names, function(pkg_name)
  {
    Sys.sleep(0.25) # two second sleep between
    r <- gh("/repos/cran/:repo/git/trees/master", repo = pkg_name)
    # print some status information to track progress
    m <- match(pkg_name, pkg_names)
    if( (m %% 200) == 0) {
        message(paste0("Current package (", m,"): ", pkg_name))
    }
    return(r)
  }
)

# save `pkg_contents` locally
saveRDS(pkg_contents, "gh_pkg_contents.RDS")
# pkg_contents <- readRDS("gh_pkg_contents.RDS")

# identify `/po` directories
pkg_has_po <- lapply(pkg_contents, function(x) {
    "po" %in% sapply(x$tree, `[[`, "path")
})

names(pkg_has_po) <- pkg_names

table(unlist(pkg_has_po))

saveRDS(pkg_has_po, "gh_cran_po.RDS")
# pkg_has_po <- readRDS("gh_cran_po.RDS")

