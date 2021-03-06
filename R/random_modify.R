#' Randomly modify MIDI sequence
#'
#' @description Takes sequence produced by drum_machine function and applies modification to this sequence.
#' @param seq_arg The sequence to be modified.  This should be the output of the drum_machine function.
#' @param modifier ("double", "flam", "roll", "cc") The modification to apply.
#' @param prob (default = 1) The probability a note in the sequence will receive the modification.
#' @param position (default = "all") The position of items in the sequence to be modified.
#' @param track_apply An integer or vector of integers indicating which tracks (hh, kick, snare) to apply the modification to.
#' @return A modified MIDI sequence to be entered into the create_midi function.
#' @examples
#'# Applies double modification to first track (hh, or hi-hat) of drum sequence with .5 probability.
#'
#' drum_machine(hh = 1:16, kick = seq(1, 16, by = 4), snare = c(5, 13)) %>%
#' random_modify(., modifier = "double", prob = .5, track_apply = 1)
#'
#'
random_modify <- function(seq_arg = NULL, modifier = NULL, prob = 1, position = "all", track_apply = NULL){

  instruments <- purrr::map(seq_arg, ~attr(.x, "meta"))

  mod_arg <- switch(modifier,
                    double = "d",
                    flam = "f",
                    roll = "l")

  if(is.null(seq_arg) | seq_arg[1] == "rand_seq"){
    obj <- as.list(match.call())
    obj$func <- sys.function()
    return(obj)
  }

  # Selecting tracks(s) to apply modification to
  track_arg = rep(TRUE, length(seq_arg))
  if(!is.null(track_apply)){
    track_arg = rep(FALSE, length(seq_arg))
    track_arg[track_apply] = TRUE
  }

  lst <- purrr::pmap(list(seq_arg, track_arg, instruments), function(seq, track, instr){

    if(!track){
      return(seq)
    }else{

      mappings = template_and_builder_aux(seq = seq, position = position, prob = prob)

      pos_mappings = mappings[[1]]
      prob_mappings = mappings[[2]]
      prob_mappings = prob_mappings[!pos_mappings %in% which(seq == "rest")]
      pos_mappings = pos_mappings[!pos_mappings %in% which(seq == "rest")]

      seq[pos_mappings] <- purrr::pmap(list(pos_mappings, prob_mappings), function(x, y){
        sample(c(paste0(seq[x], mod_arg), seq[x]), 1, prob = c(y, 1-y))}) %>% unlist

      # Fix items with two modifiers (remove second modifier)
      seq <- purrr::map(seq, function(x){
        if(x != "rest"){
          gsub("(?<=[a-z]{1})[a-z]{1}", "", x, perl = TRUE) %>%
            gsub("(?<=g[123])[a-z]{1}", "", ., perl = TRUE) %>%
            gsub("(?<=[a-z]{1})g[123]", "", ., perl = TRUE)
        }else{x}
      }) %>% unlist

      attr(seq, "class") <- "seq"
      attr(seq, "meta") <- instr

      return(seq)

    }

  })

  return(lst)

}

