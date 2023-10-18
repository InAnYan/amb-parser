#lang racket

(require brag/support)

(define (make-tokenizer ip)
  (port-count-lines! ip)
  (define the-lexer
    (lexer-src-pos
     [":" (token 'COLON lexeme)]
     [";" (token 'SEMICOLON lexeme)]
     ["|" (token 'ALTERATION lexeme)]
     ["*" (token 'STAR lexeme)]
     ["?" (token 'QUESTION lexeme)]
     [(repetition 1 +inf.0 upper-case)
      (token 'NON-TERMINAL lexeme)]
     [(repetition 1 +inf.0 lower-case)
      (token 'TERMINAL lexeme)]
     [whitespace
      (token 'WHITESPACE lexeme #:skip? #t)]
     [(eof)
      (void)]))
  (define (next-token) (the-lexer ip))
  next-token)

(provide make-tokenizer)

(module+ test
  (require rackunit)

  (define (test-first-token str)
    (token-struct-type
     (position-token-token
      ((make-tokenizer (open-input-string str))))))

  (check-equal? (test-first-token ":") 'COLON)
  (check-equal? (test-first-token ";") 'SEMICOLON)
  (check-equal? (test-first-token "|") 'ALTERATION)
  (check-equal? (test-first-token "*") 'STAR)
  (check-equal? (test-first-token "?") 'QUESTION)
  (check-equal? (test-first-token "S") 'NON-TERMINAL)
  (check-equal? (test-first-token "noun") 'TERMINAL))
