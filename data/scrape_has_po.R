# devtools::install_github("gaborcsardi/gh")
library("gh")

# retrieve all CRAN repos via the GitHub mirror
# executed 2015-11-20T18:00Z
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
pkg_contents <- list()
for(i in x) {
    # print some status information to track progress
    if( (i %% 200) == 0) {
        message(paste0("Current package (", i,"): ", pkg_names[i]))
    }
    r <- try(gh("/repos/cran/:repo/git/trees/master", repo = pkg_names[i]))
    # check for failures
    if(inherits(r, "try-error")) {
        if (grepl("403 Forbidden", r)) {
            # if failure due to rate limiting, wait until reset time
            reset <- gh("/rate_limit")$rate$reset
            message(paste0("Rate limit exceeded, restarting at: ", 
                           as.POSIXct(reset, origin = "1970-01-01")))
            Sys.sleep(reset - as.integer(Sys.time()))
            r <- try(gh("/repos/cran/:repo/git/trees/master", repo = pkg_names[i]))
            if(inherits(r, "try-error")) {
                pkg_contents[[i]] <- NULL
            } else {
                pkg_contents[[i]] <- r
            }
        }
    } else {
        pkg_contents[[i]] <- r
    }
}

## SEVERAL PACKAGES HAD ERRORS:
## > (x <- sapply(pkg_contents, is.null))
## [1] 1175 2382 4129 4922 5180 6698 6810
## > pkg_names[x]
## [1] "convoSPAT" "fungible"  "minque"    "PAFit"     "phyndr"    "ScoreGGUM" "SensusR"

# save `pkg_contents` locally
saveRDS(pkg_contents, "gh_pkg_contents.RDS")

