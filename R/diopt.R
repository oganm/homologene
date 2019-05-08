

#' Query DIOPT database
#' 
#' Query DIOPT database (\url{https://www.flyrnai.org/cgi-bin/DRSC_orthologs.pl}) for orthologues.
#' DIOPT database uses multiple tools to find gene orthologues. Sadly they don't have an
#' API so this function queries by visiting the site and filling up the form. By default
#' each query will take a minimum of 10 seconds due to \code{delay} parameter. This
#' is taken from their robots.txt at the time this function is written.
#' Note that DIOPT is not necesariy in sync with homologene database as provided in this package.
#'
#' @param genes  A vector of gene identifiers. Anything that DIOPT accepts
#' @param inTax taxid of the species that the input genes are coming from
#' @param outTax taxid of the species that you are seeking homology
#' @param delay How many seconds of delay should be between queries. Default is 10
#' based on the robots.txt at the time this function is written.
#'
#' @return A data frame
#' @export
#'
diopt = function(genes, inTax, outTax, delay = 10){
    # rtxt = robotstxt::robotstxt(domain = "flyrnai.org")
    # delay = rtxt$crawl_delay %>% filter(useragent =='*') %$% value %>% as.integer()
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
    
    additional_filters = which(names(form$fields) == 'additional_filter')
    
    additional_filter_names = form$fields[additional_filters] %>% purrr::map_chr('value')
    
    form$fields[additional_filters][additional_filter_names %in% 'None'][[1]]$checked = 'checked'
    form$fields[additional_filters][additional_filter_names %in% 'NoLow'][[1]]$checked = NULL
    
    Sys.sleep(delay)
    
    response = rvest::submit_form(session,form)
    
    # writeLines(as.char(response$response),'hede.html')
    # utils::browseURL('hede.html')
    
    output = response %>% 
        rvest::html_node('#results') %>% 
        rvest::html_table() %>% 
        dplyr::select(-`Gene2FunctionDetails`,-`Feedback`,-`Alignment & Scores`)
    return(output)
}
