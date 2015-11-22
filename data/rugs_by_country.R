library(rvest)
library(stringi)
library(dplyr)
library(ggplot2)

page <- read_html("http://blog.revolutionanalytics.com/local-r-groups.html")

# The code for the page is a mess.  The location of each RUG is inside a paragraph element 
# that has a child.  But they are in different formats so lots of cleaning is needed.
lines <- page %>%
  html_nodes("p") %>%
  html_children %>%
  html_text()
  
# Cut the non-RUG lines  
start <- which(lines == "starting a new R user group") + 1  
end <- which(lines == "GROUPS WANTED") - 1
groups <- lines[start:end]
groups <- groups[nchar(groups) > 3]
Encoding(groups) <- "UTF-8"

# Extract country names.
# Canada/Australia/New Zealand/Brazil/USA have their own format
countries <- stri_match_first_regex(groups, " *([[:alpha:] ]+?) ?\\(")[, 2]
countries[which(stri_detect_fixed(groups, "Edmonton")):which(stri_detect_fixed(groups, "Vancouver"))] <- "Canada"
countries[which(stri_detect_fixed(groups, "Adelaide, SA")):which(stri_detect_fixed(groups, "Sydney, NSW"))] <- "Australia"
countries[which(stri_detect_fixed(groups, "Auckland, NZ")):which(stri_detect_fixed(groups, "Wellington, NZ"))] <- "New Zealand"
countries[which(stri_detect_fixed(groups, "Brazil"))] <- "Brazil"
countries[which(stri_detect_fixed(groups, "Phoenix, AZ")):length(countries)] <- "USA"

# Get counts
rug_country_data <- data.frame(
  Country = countries, 
  IsEnglishSpeaking = countries %in% c("Australia", "Canada", "India", "Ireland", "New Zealand", "Philippines", "Singapore", "South Africa", "UK", "USA")
) %>%
  count_(c("Country", "IsEnglishSpeaking")) %>%
  ungroup %>%
  mutate_(Country = ~ reorder(Country, n))

saveRDS(rug_country_data, "data/rug_country_data.rds")  
  
# Visualize  
rug_country_data %>%
  ggplot(aes(Country, n, fill = IsEnglishSpeaking)) +
  geom_bar(stat = "identity") +
  coord_flip() +
  xlab(NULL) +
  ylab("Number of groups") +
  theme(legend.position = "top")
  
  