#lang racket

(struct token (str pos)
  #:transparent)

(provide token
         token?
         token-str
         token-pos)
