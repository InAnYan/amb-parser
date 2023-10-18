#lang racket

(require (for-syntax racket/syntax)
         "token.rkt")

(define parse-table (make-hash))

(define (parse name str)
  ((hash-ref parse-table name) str))

(struct parser-result
  (data rest)
  #:transparent)

(provide (contract-out
          [parse (symbol? (listof token?) . -> . (listof parser-result?))])
         parser-result
         parser-result?
         parser-result-data
         parser-result-rest)

(define-syntax-rule (amb-parser-mb PARSE-TREE)
  (#%module-begin
   PARSE-TREE))

(define-syntax-rule (parser-syntax RULES ...)
  (begin RULES ...))

(provide parser-syntax)

(define-syntax rule
  (syntax-rules ()
    [(rule NAME EXPANSION)
     (let* ([name-sym (string->symbol NAME)]
            [fn (lambda (str)
                  (map (lambda (res)
                         (prepend-node name-sym res))
                       (EXPANSION str)))])
       (hash-set! parse-table
                  name-sym
                  fn))]))

(define (prepend-node name res)
  (parser-result (cons name (parser-result-data res))
                 (parser-result-rest res)))

(provide rule)

(define-syntax alteration
  (syntax-rules ()
    [(alteration EXPS ...)
     (lambda (str)
       (append-map (lambda (fn)
                     (fn str))
                   (list EXPS ...)))]))

(provide alteration)

(define-syntax-rule (expansion FNS ...)
  (lambda (str)
    (parse-expansion str (list FNS ...))))

(provide expansion)

(define (parse-expansion str fns)
  (if (empty? fns)
      (list (parser-result empty str))
      (parse-non-empty-expansion str fns)))

(define (parse-non-empty-expansion str fns)
  (for/fold ([ress (parse-first-expansion str (first fns))])
            ([fn (rest fns)])
    (append-map
     (lambda (res)
       (map (lambda (pres)
              (parser-result (append (parser-result-data res)
                                     (list (parser-result-data pres)))
                             (parser-result-rest pres)))
            (fn (parser-result-rest res))))
     ress)))

(define (parse-first-expansion str fn)
  (map (lambda (res)
         (parser-result (list (parser-result-data res))
                        (parser-result-rest res)))
       (fn str)))

(define (parse-terminal term str)
  (if (not (null? str))
      (let ([fst (first str)])
        (if (member term (token-pos fst))
            (list (parser-result (list term (token-str fst))
                                 (rest str)))
            empty))
      empty))

(provide parse-expansion)

(define-syntax-rule (non-terminal NAME)
  (lambda (str)
    (parse (string->symbol NAME) str)))

(provide non-terminal)

(define-syntax-rule (terminal NAME)
  (lambda (str)
    (parse-terminal (string->symbol NAME) str)))

(provide terminal)

(provide (except-out (all-from-out racket) #%module-begin)
         (rename-out [amb-parser-mb #%module-begin]))
