create_midi2 <- function(seq_arg, note_length){

  note_length <- switch(note_length,
                        "sn" = "18",
                        "en" = "30",
                        "qn" = "60")

  # "hn" = "81 40",
  # "wn" = "83 00"

  instruments <- purrr::map(seq_arg, function(x){
    strsplit(attr(x, "meta"), " ")
  })

  hex_tracks <- purrr::map(seq_arg %>% unname, function(seq_orig){

    cc_stuff <- attr(seq_orig, "cc")
    v_stuff <- attr(seq_orig, "v")
    seq <- seq_modify(seq_orig)

    cc_stuff <- attr_chunk(seq, seq_orig, cc_stuff)
    v_stuff <- attr_chunk(seq, seq_orig, v_stuff)

    if(is.null(cc_stuff)){
      cc_stuff <- NA
    }

    if(is.null(v_stuff)){
      v_stuff <- NA
    }



    purrr::pmap(list(seq, seq_along(seq), cc_stuff, v_stuff), function(x, y, z, a){

      rest_hex <- first_rests(x, note_length = note_length)

      x <- x[x != "rest"]

      note1_hex = note2_hex <- x %>% stringr::str_replace(., "h|t|f1|f2|g1|g2|g3", "") %>% note_to_hex()

      event1_hex <- "90"
      event2_hex <- "80"

      velocity1_hex <- vel_helper(a, event1_hex)
      velocity2_hex <- vel_helper(a, event2_hex)

      note_length_hex <- note_length

      if(grepl("h", x)){
        note_length_hex <- (note_length %>% as.hexmode()/2) %>% as.character()

      }else if(grepl("t", x)){
        note_length_hex <- (note_length %>% as.hexmode()/3) %>% as.character()

      }else if(grepl("f1", x)){
        event2_hex <- "90"
        velocity2_hex <- vel_helper(a, event2_hex)
        note_length_hex <- "04"

      }else if(grepl("f2", x)){
        event1_hex <- "80"
        velocity1_hex <- vel_helper(a, event1_hex)
        rest_hex <- (note_length_hex %>% as.hexmode() %>% as.numeric - 4) %>% as.hexmode() %>% as.character()
        note_length_hex <- "00"

      }else if(grepl("g1", x)){
        event2_hex <- "90"
        velocity2_hex <- "7f"
        note2_hex <- seq[y+1][[1]][length(seq[y+1][[1]])] %>%
          stringr::str_replace(., "h|t|f1|f2|g1|g2|g3", "") %>% note_to_hex()

      }else if(grepl("g2", x)){
        event1_hex <- "80"
        velocity1_hex <- vel_helper(a, event1_hex)
        event2_hex <- "90"
        velocity2_hex <- vel_helper(a, event2_hex)
        rest_hex <- "04"
        note_length_hex <- (note_length_hex %>% as.hexmode() %>% as.numeric - 4) %>% as.hexmode() %>% as.character()
        note1_hex <- seq[y-1][[1]][length(seq[y-1][[1]])] %>%
          stringr::str_replace(., "h|t|f1|f2|g1|g2|g3", "") %>% note_to_hex()

        note2_hex <- seq[y+1][[1]][length(seq[y+1][[1]])] %>%
          stringr::str_replace(., "h|t|f1|f2|g1|g2|g3", "") %>% note_to_hex()

      }else if(grepl("g3", x)){
        event1_hex <- "80"
        velocity1_hex <- vel_helper(a, event1_hex)
        note1_hex <- seq[y-1][[1]][length(seq[y-1][[1]])] %>%
          stringr::str_replace(., "h|t|f1|f2|g1|g2|g3", "") %>% note_to_hex()
        rest_hex <- "04"
        note_length_hex <- (note_length_hex %>% as.hexmode() %>% as.numeric - 4) %>% as.hexmode() %>% as.character()
      }

      if(is.na(z)){

        return(c(rest_hex, event1_hex, note1_hex, velocity1_hex,
                 note_length_hex, event2_hex, note2_hex, velocity2_hex))
      }else{

        return(c(rest_hex, "B0", stringr::str_extract(z, ".{2}$"), stringr::str_extract(z, ".{1,}(?=-)"),
                 "00", event1_hex, note1_hex, velocity1_hex,
                 note_length_hex, event2_hex, note2_hex, velocity2_hex,
                 "00", "B0", stringr::str_extract(z, ".{2}$"), stringr::str_extract(z, ".{1,}(?=-)")))
      }

    }) %>% unlist

  })



  hex_tracks <- purrr::map2(hex_tracks, instruments, ~c(.y, .x))


  tracks_fin <- purrr::map(hex_tracks, function(track){

    c(c("4D", "54", "72", "6B"), as.character(special_hexmode(length(track))), track)

  })

  return(give_header_and_tempo(tracks_fin))

}


#### Helper Functions ####

# Creates a list of pairs of note events
seq_modify <- function(seq){

  seq <- doubles_rolls_adj(seq) %>% flam_adj() #%>% glide_adj()

  purrr::map2(which(seq != "rest"), seq_along(which(seq != "rest")), function(x, y){

    idx <- which(seq != "rest")[y-1]

    if(!purrr::is_empty(seq[idx])){

      if(idx != (x-1)){
        idx2 <- (idx+1):(x-1)
      }else{idx2 <- 0}

    }else{
      if(x == 1){
        idx2 <- 0
      }else{
        idx2 <- 1:(x-1)
      }
    }

    return(c(seq[idx2], seq[x]))

  }
  )
}

# Adjust for glides
glide_adj <- function(seq){

  stuff <- grepl("g", seq)
  stuff[which(stuff == TRUE) + 1] <- TRUE
  stuff_lst <- split(seq, f = cumsum(c(1, diff(stuff) != 0))) %>% unname

  purrr::map(stuff_lst, function(x){

    if(any(grepl("g", x))){

      rests_vec <- x[x == "rest"]
      notes_vec <- x[x != "rest"]

      notes_vec[1] <- paste0(notes_vec[1], "1")
      notes_vec[length(notes_vec)] <- paste0(notes_vec[length(notes_vec)], "g3")

      if(length(notes_vec) > 2){
        notes_vec[2:(length(notes_vec)-1)] <- paste0(notes_vec[2:(length(notes_vec)-1)], "2")
      }

      return(c(rests_vec, notes_vec))

    }else{
      return(x)
    }
  }) %>% unlist

}

# Adjust for doubles and rolls
doubles_rolls_adj <- function(seq){

  purrr::map(seq, function(x){

    if(grepl("d", x)){
      x <- substr(x, 1, nchar(x)-1)
      return(c(paste0(x, "h"), paste0(x, "h")))
    }else if(grepl("l", x)){
      x <- substr(x, 1, nchar(x)-1)
      return(c(paste0(x, "t"), paste0(x, "t"), paste0(x, "t")))
    }else{
      return(x)
    }

  }) %>% unlist

}

# Adjust for flams
flam_adj <- function(seq){

  stuff <- grepl("f", seq)
  stuff_lst <- split(seq, f = cumsum(c(1, diff(stuff) != 0))) %>% unname

  purrr::map(stuff_lst, function(x){

    if(any(grepl("f", x))){
      return(c(paste0(x, "1"), paste0(x, "2")))
    }else{
      return(x)
    }

  }) %>% unlist

}

# Turn rests into hex
first_rests <- function(x, note_length){

  rest_stuff <- x[x == "rest"]

  if(!purrr::is_empty(rest_stuff)){
    return(rep(note_length, length(rest_stuff)) %>% as.hexmode() %>% as.numeric() %>%
             cumsum() %>% as.hexmode_mod() %>% .[[length(.)]] %>% strsplit(., " "))
  }else{
    return("00")
  }

}



# Create multibyte hex from number
special_hexmode <- function(number){

  quotient <- number %/% 256
  remainder <- number %% 256
  remainder_hex <- as.character(as.hexmode(remainder))


  if(quotient < 256){

    quotient_hex <- as.character(as.hexmode(quotient))
    return(c("00", "00", quotient_hex, remainder_hex))

  }else{

    quotient2 <- quotient %/% 256
    remainder2 <- quotient %% 256
    quotient_hex <- as.character(as.hexmode(remainder2))
    quotient2_hex <- as.character(as.hexmode(quotient2))

    return(c("00", quotient2_hex, quotient_hex, remainder_hex))

  }

}

# Give header and tempo tracks to midi track
give_header_and_tempo <- function(track_info){

  tempo_track <- c("4D", "54", "72", "6B", "00", "00", "00", "14",
                   "00", "FF", "58", "04", "04", "02", "18", "08", "00", "FF", "51", "03", "07", "A1", "20",
                   "83", "00", "FF", "2F", "00")

  # Create main midi header
  hex_header <- c(c("4D", "54", "68", "64", "00", "00", "00", "06", "00", "01", "00"), as.character(length(track_info)+1),
                  c("00", "60"))

  return(c(hex_header, tempo_track, track_info %>% unlist))
}

# Convert note to hex
note_to_hex <- function(note){
  # Apply function to character string of notes
  lapply(note, function(x){

    # Split string into character vector of notes
    x <- stringr::str_split(x, " ") %>% unlist %>% stringr::str_split(., "-") %>% unlist
    # Return appropriate hex for note followed by 'rest'
    c(as.character(as.hexmode(0:119)), "rest")[which(c(paste0(c("C", "C#", "D", "D#", "E", "F",
                                                                "F#", "G", "G#", "A", "Bb", "B"),
                                                              rep(seq(-1,8), each = 12)), "rest") %in% x)]}) %>% unname()
}


