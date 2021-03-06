% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/write_midi.R
\name{write_midi}
\alias{write_midi}
\title{Write MIDI file.}
\usage{
write_midi(midi_hex, path)
}
\arguments{
\item{midi_hex}{This is a hexadecimal string, output from the create_midi function.}

\item{path}{The name of the file.}
}
\description{
Takes a hexadecimal MIDI sequence and writes it to the harddrive.
}
\examples{
# Saves a MIDI sequence as a .mid file called example_midi.mid

drum_machine(hh = 1:16, kick = seq(1, 16, by = 4), snare = c(5, 13)) \%>\%
create_midi() \%>\% write_midi(., "example_midi.mid")


}
