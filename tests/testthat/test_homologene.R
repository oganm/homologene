context('homologene testing')

test_that('Multiple orthologues',{
    humanOrthos = human2mouse(c("GZMH"))
    expect_equal(humanOrthos$mouseGene,c('Gzmd','Gzme','Gzmg','Gzmf'))
})

test_that('Regular functionality',{
    expect_equal(mouse2human(c('Eno2','Mog'))$humanGene,c('ENO2','MOG'))
    expect_equal(dim(mouse2human(c('lolwut'))), c(0,4))
})

test_that('Other species',{
    homoSubsets = homologene::taxData$tax_id %>% sapply(function(x){
        homologene::homologeneData %>% subset(Taxonomy==x) %>% dim
    })
    expect_true(all(homoSubsets[1,]>100))
    
})



test_that('homologene2',{
    mouse2human(c('Mesd',
                  'Trp53rka',
                  'Cstdc4',
                  'Ifit3b'),
                db = homologeneData2) -> 
        genes
    
    expect_true(all(genes$humanGene == c("MESD", "TP53RK", "CSTA", "IFIT3")))
    
    mouse2human(c('Mesd',
                  'Trp53rka',
                  'Cstdc4',
                  'Ifit3b'),
                db = homologeneData) -> 
        genes
    
    expect_true(nrow(genes)==0)

})




test_that('Detached behaviour',{
    detach("package:homologene", unload=TRUE)
    expect_equal(homologene::mouse2human(c('Eno2','Mog'))$humanGene,c('ENO2','MOG'))
    expect_equal(dim(homologene::human2mouse(c('lolwut'))), c(0,4))
})


