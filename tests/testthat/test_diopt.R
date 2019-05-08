context('diopt')


test_that('DIOPT',{
    out = diopt(c('GZMH'),inTax = 9606, outTax = 10090)
    
    expect_true(all(c('Gzmd','Gzme','Gzmg','Gzmf') %in% out$`Mouse Symbol`))
})    