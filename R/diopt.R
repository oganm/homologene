

#' Query DIOPT database
#' 
#' Query DIOPT database (\url{https://www.flyrnai.org/cgi-bin/DRSC_orthologs.pl}) for orthologues.
#' DIOPT database uses multiple tools to find gene orthologues. Sadly they don't have an
#' API so this function queries by visiting the site and filling up the form. By default
#' each query will take a minimum of 10 seconds due to \code{delay} parameter. This
#' is taken from their robots.txt at the time this function is written.
#' Note that DIOPT is not necesariy in sync with homologene database as provided in this package.
#' 
#' DIOPT does not support all species available in the homologene database. The supported
#' species are:
#' 
#' \describe{
#'     \item{4896}{Schizosaccharomyces pombe}
#'     \item{4932}{Saccharomyces cerevisiae}
#'     \item{6239}{Caenorhabditis elegans}
#'     \item{7227}{Drosophila melanogaster}
#'     \item{7955}{Danio rerio}
#'     \item{8364}{Xenopus (Silurana) tropicalis}
#'     \item{9606}{Homo sapiens}
#'     \item{10090}{Mus musculus}
#'     \item{10116}{Rattus norvegicus}
#'     \item{3702}{Arabidopsis thaliana}
#' }
#' 
#'
#' @param genes  A vector of gene identifiers. Anything that DIOPT accepts
#' @param inTax taxid of the species that the input genes are coming from
#' @param outTax taxid of the species that you are seeking homology. 0 to query all species.
#' @param delay How many seconds of delay should be between queries. Default is 10
#' based on the robots.txt at the time this function is written.
#'
#' @return A data frame
#' @export
#'
diopt = function(genes, inTax, outTax, delay = 10){
    # rtxt = robotstxt::robotstxt(domain = "flyrnai.org")
    # delay = rtxt$crawl_delay %>% filter(useragent =='*') %$% value %>% as.integer()
    session = rvest::session('https://www.flyrnai.org/cgi-bin/DRSC_orthologs.pl')
    # session = rvest::html_session('https://www.flyrnai.org/cgi-bin/DRSC_orthologs.pl', httr::config(ssl_verifypeer = 0L))
    form = rvest::html_form(session)[[1]]
    
    acceptableInTax= form$fields$input_species$options
    acceptableOutTax = form$fields$output_species$options
    
    assertthat::assert_that(inTax %in% acceptableInTax)
    assertthat::assert_that(outTax %in% acceptableOutTax)
    
    form = rvest::html_form_set(form,
                             input_species = inTax,
                             output_species = outTax,
                             gene_list = paste(genes,collapse = '\n\r'))
    
    # additional_filters = which(names(form$fields) == 'additional_filter')
    
    # additional_filter_names = form$fields[additional_filters] %>% purrr::map_chr('value')
    
    # form$fields[additional_filters][additional_filter_names %in% 'None'][[1]]$attr$checked = 'checked'
    # form$fields[additional_filters][additional_filter_names %in% 'NoLow'][[1]]$attr$checked = NULL
    
    values = form$fields %>% purrr::map('value')
    additional_filters = names(values) == 'additional_filter'
    noneField = values %>% purrr::map_lgl(function(x){length(x)==1&&x !='None'}) 
    form$fields = form$fields[!(additional_filters & noneField)]
    

    values = form$fields %>% purrr::map('value')
    search_datasets = names(values) == 'search_datasets'
    allField = values %>% purrr::map_lgl(function(x){length(x)==1&&x !='All'}) 
    form$fields = form$fields[!(search_datasets & allField)]
    
    values = form$fields %>% purrr::map('value')
    search_datasets = names(values) == 'search_fields'
    allField = values %>% purrr::map_lgl(function(x){length(x)==1&&x !='***'}) 
    form$fields = form$fields[!(search_datasets & allField)]
    
    Sys.sleep(delay)
    
    response = rvest::html_form_submit(form,submit = 'submit')
    
    writeLines(ogbox::as.char(session$response),'hede.html')
    utils::browseURL('hede.html')
    writeBin(response$content,'hede.html')
    utils::browseURL('hede.html')
    
    output = response %>% 
        xml2::read_html() %>% 
        rvest::html_node('#results') %>% 
        rvest::html_table() %>% 
        dplyr::select(-`Gene2FunctionDetails`,-`Feedback`,-`Alignment & Scores`)
    return(output)
}
