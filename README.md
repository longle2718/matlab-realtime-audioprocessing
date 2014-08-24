matlab-realtime-audio
====

This project show how to capture realtime audio in matlab and do some processing with PMTK
This project uses subroutines from PMTK. However, because PMTK does not use the logexpsum trick,
the algorithm will crash after a few iteration. Therefore I made a patch for PMTK which is
in the file "pmtk.patch". Please apply this patch on PMTK before run.

