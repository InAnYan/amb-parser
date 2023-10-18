#lang racket

(define (lower-grammar g)
  (cons 'parser-syntax
        (append-map lower-rule (rest g))))

(define (lower-rule rule)
  (match rule
    [(list 'rule rule-name
           (list 'alteration a1 ...
                 (list 'expansion
                       x ...
                       (list type name maybe-star ... "?")
                       y ...)
                 a2 ...)) 
     (lower-rule
      `(rule ,rule-name
             (alteration ,@a1
                         (expansion ,@x (,type ,name ,@maybe-star) ,@y)
                         (expansion ,@x ,@y)
                         ,@a2)))]
    [(list 'rule rule-name
           (list 'alteration a1 ...
                 (list 'expansion
                       x ...
                       (list type name "*")
                       y ...)
                 a2 ...))
     (cons `(rule ,(string-append name "*")
                  (alteration (expansion (,type ,name) (non-terminal ,(string-append name "*")))
                              (expansion)))
           (lower-rule `(rule ,rule-name
                              (alteration ,@a1
                                          (expansion ,@x (non-terminal ,(string-append name "*")) ,@y)
                                          ,@a2))))]
    [_ (list rule)]))

(provide lower-grammar)

(module+ test
  (require rackunit)

  (define-syntax-rule (check-lower? got should)
    (check-equal? (lower-grammar (cons 'parser-syntax got))
                  (cons 'parser-syntax should)))
  
  (check-lower?
   '((rule "a"
           (alteration
            (expansion (non-terminal "prea")
                       (terminal "b" "?")
                       (non-terminal "c")))))
   '((rule "a"
           (alteration
            (expansion (non-terminal "prea")
                       (terminal "b")
                       (non-terminal "c"))
            (expansion (non-terminal "prea")
                       (non-terminal "c"))))))

  (check-lower?
   '((rule "NP"
           (alteration
            (expansion (terminal "determiner")
                       (terminal "adjective" "*")
                       (terminal "noun")))))
   '((rule "adjective*"
           (alteration (expansion (terminal "adjective")
                                  (non-terminal "adjective*"))
                       (expansion)))
     (rule "NP"
           (alteration (expansion (terminal "determiner")
                                  (non-terminal "adjective*")
                                  (terminal "noun"))))))

  (check-lower? 
   '((rule "a"
           (alteration
            (expansion (non-terminal "prea")
                       (non-terminal "b" "?")
                       (non-terminal "c")))))
   '((rule "a"
           (alteration
            (expansion (non-terminal "prea")
                       (non-terminal "b")
                       (non-terminal "c"))
            (expansion (non-terminal "prea")
                       (non-terminal "c"))))))

  (check-lower?
   '((rule "NP"
           (alteration
            (expansion (terminal "determiner")
                       (non-terminal "adjective" "*")
                       (terminal "noun")))))
   '((rule "adjective*"
           (alteration (expansion (non-terminal "adjective")
                                  (non-terminal "adjective*"))
                       (expansion)))
     (rule "NP"
           (alteration (expansion (terminal "determiner")
                                  (non-terminal "adjective*")
                                  (terminal "noun"))))))

  (check-lower?
   '((rule "NP"
           (alteration (expansion (terminal "determiner" "?")
                                  (terminal "adjective" "*")
                                  (terminal "noun")))))
   '((rule "adjective*"
           (alteration (expansion (terminal "adjective")
                                  (non-terminal "adjective*"))
                       (expansion)))
     (rule "adjective*"
           (alteration (expansion (terminal "adjective")
                                  (non-terminal "adjective*"))
                       (expansion)))
     (rule "NP"
           (alteration (expansion (terminal "determiner")
                                  (non-terminal "adjective*")
                                  (terminal "noun"))
                       (expansion (non-terminal "adjective*")
                                  (terminal "noun"))))))

  (check-lower? 
   '((rule "a"
           (alteration
            (expansion (non-terminal "prea")
                       (terminal "b" "*" "?")
                       (non-terminal "c")))))
   '((rule "b*"
           (alteration
            (expansion (terminal "b")
                       (non-terminal "b*"))
            (expansion)))
     (rule "a"
           (alteration
            (expansion (non-terminal "prea")
                       (non-terminal "b*")
                       (non-terminal "c"))
            (expansion (non-terminal "prea")
                       (non-terminal "c")))))))
