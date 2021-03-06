#' @title cAMARETTO_ModuleNetwork
#' 
#' Creates a module network.
#'
#' @param cAMARETTOresults 
#' @param pvalue pvalue cut-off for each gene set
#' @param inter minimal overlap between two gene sets
#' @param color_list An optional list with colors
#' @param edge_method Define edge weights based p-values or overlap between the gene sets.
#'
#' @return a list with the module network, layout for the network, used p-value, used overlap en colors
#' 
#' @import randomcoloR
#' @import tidyverse
#' @import igraph
#' 
#' @examples 
#' 
#' cAMARETTOnetworkM<-cAMARETTO_ModuleNetwork(cAMARETTOresults,0.10,5)
#' 
#' @export
cAMARETTO_ModuleNetwork<-function(cAMARETTOresults, pvalue=0.05, inter=5, color_list=NULL, edge_method="pvalue"){
  
  output_hgt_allcombinations_filtered <- cAMARETTOresults$hgt_modules %>% 
                                            filter(padj<=pvalue & n_Overlapping>=inter)
  node_information <- as.data.frame(unique(c(output_hgt_allcombinations_filtered$Geneset1, output_hgt_allcombinations_filtered$Geneset2)))
  colnames(node_information) <- c("modulenames")
  node_information <- node_information %>% 
                        mutate(run=sub("\\|.*$","",modulenames))
  module_network <- graph_from_data_frame(d=output_hgt_allcombinations_filtered%>% dplyr::select(-RunName1,-RunName2), vertices=node_information, directed=FALSE)
  if (is.null(color_list)){
    color_list <- randomColor(length(c(cAMARETTOresults$runnames,cAMARETTOresults$gmtnames)),luminosity="bright")
    names(color_list) <- c(cAMARETTOresults$runnames,cAMARETTOresults$gmtnames)
  } else {
    c(cAMARETTOresults$runnames,cAMARETTOresults$gmtnames) %in% names(color_list)
  }
  V(module_network)$color <- color_list[V(module_network)$run]
  V(module_network)$size <- 2*sqrt(igraph::degree(module_network, mode="all"))
  if (edge_method=="pvalue"){
    E(module_network)$width <- -(log10(E(module_network)$p_value))*0.2
  } else if (edge_method=="overlap"){
    E(module_network)$width <- E(module_network)$n_Overlapping/8
  } else {
    stop("The edge method is not properly defined.")
  }
  layoutMN <- layout_with_fr(module_network)
  plot(module_network, vertex.frame.color=NA, layout=layoutMN, vertex.label=NA, main="Module network", edge.color="gray80")
  legendMN <- legend(x = -1.5, y = -1.1+0.05*length(color_list), legend = names(color_list), col = color_list, pch=19, bty="n",ncol=ceiling(length(color_list)/5))
  legendMN
  return(list(module_network=module_network, layoutMN=layoutMN, pvalue=pvalue, inter=inter, colMN=color_list))
}
