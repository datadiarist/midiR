## Template Function
template <- function(..., every = 4){

  return(list(..., every, "template"))

}

## Builder Function
builder <- function(..., path = "linear"){

  return(list(..., path, "builder"))

}


# Turns template and builder lists into position and probability mappings (for use in randomizer functions)
template_and_builder_aux <- function(seq = seq, position = position, prob = prob, mapper = NULL){

  if(is.list(position)){bar = position[[length(position) - 1]]
  pos_nums = position[1:(length(position) - 2)]}

  if(is.list(prob)){probs = prob[1:(length(prob) - 2)] %>% unlist
  prob_nums =  purrr::map(seq(1, length(probs), 2), ~probs[c(.x, .x+1)])}

  if(!is.null(mapper)){
    if(position[length(position)] != "template"){
      stop("The position argument should be given the appropriate function, template.")
    }else{
      other_mappings <- rep(mapper, length(seq)/bar)
    }
  }

  if(position[length(position)] == "template"){
    pos_mappings = purrr::map(pos_nums, ~seq(.x, length(seq), bar))
  }else{
    pos_mappings = 1:length(seq)
  }

  if(prob[length(prob)] == "builder"){
    prob_mappings = purrr::map2(list(pos_mappings %>% unlist), prob_nums, ~seq(.y[[1]], .y[[2]], (.y[2] - .y[1])/(length(.x)-1)))
  }else{
    prob_mappings = rep(prob, length(pos_mappings %>% unlist))
  }

  if(exists("other_mappings")){
    return(list(sort(pos_mappings %>% unlist), other_mappings %>% unlist))
  }else{
    return(list(sort(pos_mappings %>% unlist), prob_mappings %>% unlist))
  }

}

# Turn instrument name to corresponding hex code
instrument_to_hex <- function(instrument, data = instrument_df){

  if(instrument %in% instrument_df$instrument)
    return(instrument_df$hex[instrument_df$instrument == instrument])
  else
    stop("The instrument you entered could not be found.")

}



vel_helper <- function(x, event){

  if(event == "90"){

    if(!is.na(x)){
      return(x)
    }else{
      return("7f")
    }

  }else if(event == "80"){

    return("00")
  }

}


attr_chunk <- function(seq, seq_orig, attr_seq){

  attr_seq <- as.list(attr_seq)

  attr_seq <- purrr::map2(seq_orig, attr_seq, function(x, y){

    if(grepl("d|f", x)){

      return(c(y, y))

    }else if(grepl("l", x)){

      return(c(y, y, y))

    }else{

      return(y)

    }


  }) %>% unlist

  return(attr_seq[cumsum(purrr::map(seq, ~length(.x)) %>% unlist)])

}
