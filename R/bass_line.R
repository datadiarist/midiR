bass_line <- function(..., note_length = NULL, instrument = 1, rep = 1){

  args <- list(...)
  names <- names(args)

  seq <- purrr::map2(args, names, function(x, y){rep(y, x)}) %>% unlist
  names(seq) <- NULL

  z = as.character(instrument)
  seq <- rep(seq, rep)

  seq <- purrr::map(seq, function(x){

    if(grepl("\\|", x)){

      return(sample(strsplit(x, "\\|")[[1]], 1))

    }else{
      return(x)
    }
  }) %>% unlist

  z = switch(z,
             "1" = "Acoustic Bass",
             "2" = "Electric Bass (finger)",
             "3" = "Electric Bass (pick)",
             "4" = "Fretless Bass",
             "5" = "Slap Bass 1",
             "6" = "Slap Bass 2",
             "7" = "Synth Bass 1",
             "8" = "Synth Bass 2")

  class(seq) = "seq"
  attr(seq, "note_length") = note_length
  attr(seq, "meta") = paste("00", "Cf", instrument_to_hex(z))

  seq <- list(seq)
  names(seq) <- "bassline"

  return(seq)

}
