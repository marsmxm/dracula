#lang racket

(require htdp/testing)

(provide check-expect check-within check-error generate-report generate-report!)

(define-syntax (generate-report! stx)
  (syntax-case stx ()
    [(_) #'(generate-report)]
    [_ (raise-syntax-error #f
         "expected no arguments"
         stx)]))
