#lang info

(define collection "amb-parser")
(define version "1.0")
(define scribblings '(("scribblings/amb-parser.scrbl")))
(define pkg-desc "Simple parser generator for ambiguous grammars")
(define deps '("base"
               "brag-lib"))
(define build-deps '("brag"
                     "racket-doc"
                     "rackunit-lib"
                     "scribble-lib"))
