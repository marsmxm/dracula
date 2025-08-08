#lang racket

(require "teachpacks/testing.rkt")

(check-expect (+ 1 1) 2)
(check-within (/ 22 7) 3.14 0.01)
(check-error (/ 1 0) "division by zero")

(generate-report)
