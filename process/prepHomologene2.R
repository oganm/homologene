library(readr)
library(magrittr)
library(dplyr)
library(purrr)
library(glue)
library(git2r)
library(usethis)
library(ogbox)



devtools::load_all()

# if(!exists("homologeneData2")){
#     homologeneData2 = homologeneData
# }

# takes about 15 minutes. I might as well update it from scratch each time.
tictoc::tic()
homologeneData2 = 
    updateHomologene(destfile = 'data-raw/homologene2.tsv',
                     baseline = homologeneData)
tictoc::toc()

usethis::use_data(homologeneData2,overwrite = TRUE)



glue('
#\' homologeneData2
#\'
#\' A modified copy of the homologene database. Homologene was updated at 2014 and many of its gene IDs and
#\' symbols are out of date. Here the IDs and symbols are replaced with their most current version
#\' Last update: {date()}
"homologeneData2"
') %>% 
    writeLines(con = 'R/homologeneData2.R')

devtools::document()


# github stuff --------------
repo = repository('.')
add(repo,'R/homologeneData2.R')
add(repo,'data/homologeneData2.rda')
add(repo,'man/homologeneData2.Rd')
add(repo,'data-raw/homologene2.tsv')

version = getVersion()
version %<>% strsplit('\\.') %>% {.[[1]]}
dateTail = format(Sys.Date(),'%y.%m.%d') %>% 
    gsub(pattern = '\\.0','.',x=.) %>% strsplit('\\.') %>% {.[[1]]}

version[4:6] = dateTail

setVersion(paste(version,collapse = '.'))
ogbox::setDate(format(Sys.Date(),'%Y-%m-%d'))

add(repo,'DESCRIPTION')

git2r::commit(repo,message = 'homologeneData2 automatic update')


token = readLines('data-raw/auth')
Sys.setenv(GITHUB_PAT = token)
cred = git2r::cred_token()
git2r::push(repo,credentials = cred)