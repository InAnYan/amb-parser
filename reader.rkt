#lang racket

(require "tokenizer.rkt"
         "parser.rkt"
         "grammar-simplifier.rkt"
         "grammar-lower.rkt")

(define (read-syntax path port)
  (define parse-tree (parse path (make-tokenizer port)))
  (define module-datum `(module amb-parser-mod amb-parser/expander
                          ,(lower-grammar (simplify-grammar (syntax->datum parse-tree)))))
  (datum->syntax #f module-datum))

(provide (contract-out
          [read-syntax (any/c input-port? . -> . syntax?)]))

(module+ test
  (require rackunit
           brag/support)

  (define (parse-str str)
    (syntax->datum (parse "" (make-tokenizer (open-input-string str)))))

  (define (parse-fail str)
    (lambda ()
      (parse "" (make-tokenizer (open-input-string str)))))

  (define-syntax-rule (check-parse? got should)
    (check-equal? (parse-str got)
                  (cons 'parser-syntax should)))

  (define-syntax-rule (check-parse-fail str)
    (check-exn exn:fail:parsing? (parse-fail str)))

  (check-parse? "S : NP VP;"
                '((rule "S" ":"
                        (alteration
                         (expansion (non-terminal "NP")
                                    (non-terminal "VP")))
                        ";")))

  (check-parse? "S : NP VP; NP : det noun;"
                '((rule "S" ":"
                        (alteration
                         (expansion (non-terminal "NP")
                                    (non-terminal "VP")))
                        ";")
                  (rule "NP" ":"
                        (alteration
                         (expansion (terminal "det")
                                    (terminal "noun")))
                        ";")))

  (check-parse? "A : a? B;"
                '((rule "A" ":"
                        (alteration
                         (expansion (terminal "a" "?")
                                    (non-terminal "B")))
                        ";")))

  (check-parse? "A : a* B;"
                '((rule "A" ":"
                        (alteration
                         (expansion (terminal "a" "*")
                                    (non-terminal "B")))
                        ";")))

  (check-parse? "A : a*? B;"
                '((rule "A" ":"
                        (alteration
                         (expansion (terminal "a" "*" "?")
                                    (non-terminal "B")))
                        ";")))

  (check-parse-fail "a : b c;")
  (check-parse-fail "A b c;")
  (check-parse-fail "A : b c")
  (check-parse-fail "A : b?* c;"))
