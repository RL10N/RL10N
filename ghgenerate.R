proposal<-"RL10N: R Localization Proposal"
proposal.file<-"isc-proposal.Rmd"
author<-"Richie Cotton and Thomas Leeper"

rmarkdown::render(proposal.file, output_format="html_document",
                  output_dir="out", quiet=TRUE)
rmarkdown::render(proposal.file, output_format="pdf_document",
                  output_dir="out", quiet=TRUE)