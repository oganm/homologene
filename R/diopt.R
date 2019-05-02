

#' Query DIOPT database
#' 
#' Query DIOPT database (\url{https://www.flyrnai.org/cgi-bin/DRSC_orthologs.pl}) for orthologues.
#' DIOPT database uses multiple tools to find gene orthologues. Sadly they don't have an
#' API so this function queries by visiting the site and filling up the form while obeying
#' their robots.txt. All queries will take a minimum of 10 seconds due to crawl delay.
#'
#' @param genes  A vector of gene identifiers. Anything that DIOPT accepts
#' @param inTax taxid of the species that the input genes are coming from
#' @param outTax taxid of the species that you are seeking homology
#'
#' @return
#' @export
#'
diopt = function(genes, inTax, outTax){
    rtxt = robotstxt::robotstxt(domain = "flyrnai.org")
    delay = rtxt$crawl_delay %>% filter(useragent =='*') %$% value %>% as.integer()
    session = rvest::html_session('https://www.flyrnai.org/cgi-bin/DRSC_orthologs.pl')
    form = rvest::html_form(session)[[1]]
    
    acceptableInTax= form$fields$input_species$options
    acceptableOutTax = form$fields$output_species$options
    
    assertthat::assert_that(inTax %in% acceptableInTax)
    assertthat::assert_that(outTax %in% acceptableOutTax)
    
    form = rvest::set_values(form,
                             input_species = inTax,
                             output_species = outTax,
                             gene_list = paste(genes,collapse = '\n\r'))
    
    Sys.sleep(delay)
    
    response = rvest::submit_form(session,form)
    
    # writeLines(as.char(response$response),'hede.html')
    # utils::browseURL('hede.html')
    
    output = response %>% 
        html_node('#results') %>% 
        html_table %>% 
        select(-`Gene2FunctionDetails`,-`Feedback`,-`Alignment & Scores`)
    return(output)
}
