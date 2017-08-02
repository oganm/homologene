context('homologene testing')

test_that('Multiple orthologues',{
    expect_that(human2mouse(c("GZMH"))$mouseGene,equals(c('Gzmd','Gzme','Gzmg','Gzmf')))
})

test_that('Regular functionality',{
    expect_that(mouse2human(c('Eno2','Mog'))$humanGene,equals(c('ENO2','MOG')))
    expect_that(dim(mouse2human(c('lolwut'))), equals(c(0,2)))
})

test_that('Other species',{
    homoSubsets = homologene::taxData$tax_id %>% sapply(function(x){
        homologene::homologeneData %>% subset(Taxonomy==x) %>% dim
    })
    expect_true(all(homoSubsets[1,]>100))
    
})

test_that('Detached behaviour',{
    detach("package:homologene", unload=TRUE)
    expect_that(homologene::mouse2human(c('Eno2','Mog'))$humanGene,equals(c('ENO2','MOG')))
    expect_that(dim(homologene::mouse2human(c('lolwut'))), equals(c(0,2)))
})

