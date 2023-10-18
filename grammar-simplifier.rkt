#lang racket

(define (simplify-grammar g)
  (cons 'parser-syntax (map simplify-rule (rest g))))

(define (simplify-rule r)
  (list (first r) (second r) (simplify-alteration (fourth r))))

(define (simplify-alteration alt)
  (filter (lambda (x)
            (not (equal? x "|")))
          alt))

(provide simplify-grammar)

(module+ test
  (require rackunit)

  (define-syntax-rule (check-simplify? got should)
    (check-equal? (simplify-grammar (cons 'parse-syntax (list got)))
                  (cons 'parser-syntax (list should))))

  (check-simplify?
   '(rule "A"
          ":"
          (alteration (expansion
                       (terminal "a")))
          ";")

   '(rule "A" (alteration (expansion (terminal "a")))))

  (check-simplify?
   '(rule "A"
          ":"
          (alteration (expansion (terminal "a"))
                      "|"
                      (expansion (terminal "b")))
          ";")

   '(rule "A" (alteration (expansion (terminal "a"))
                          (expansion (terminal "b"))))))
