#lang scheme/gui

(require drscheme/tool
         string-constants
         "dict.ss")

(provide language-level^
         language-level@)

(define-namespace-anchor the-anchor)

(define-signature language-level^
  (simple-language-level%
   make-language-level
   language-level-render-mixin
   language-level-capability-mixin
   language-level-no-executable-mixin
   language-level-macro-stepper-mixin
   language-level-check-expect-mixin
   language-level-settings-mixin
   language-level-metadata-mixin
   language-level-dynamic-setup-mixin))

(define-unit language-level@
  (import drscheme:tool^)
  (export language-level^)

  (define (make-language-level
           name path
           #:number [number (equal-hash-code name)]
           #:hierarchy [hierarchy experimental-language-hierarchy]
           #:summary [summary name]
           #:url [url #f]
           #:reader [reader read-syntax]
           . mixins)
    (let* ([mx-default (drscheme:language:get-default-mixin)]
           [mx-custom (apply compose (reverse mixins))])
      (new (mx-custom (mx-default simple-language-level%))
           [module path]
           [language-position (append (map car hierarchy) (list name))]
           [language-numbers (append (map cdr hierarchy) (list number))]
           [one-line-summary summary]
           [language-url url]
           [reader (make-namespace-syntax-reader reader)])))

  (define simple-language-level%
    (drscheme:language:module-based-language->language-mixin
     (drscheme:language:simple-module-based-language->module-based-language-mixin
      drscheme:language:simple-module-based-language%)))

  (define (language-level-render-mixin to-sexp show-void?)
    (mixin (drscheme:language:language<%>) ()
      (super-new)

      (define/override (render-value/format value settings port width)
        (unless (and (void? value) (not show-void?))
          (super render-value/format (to-sexp value) settings port width)))))

  (define (language-level-capability-mixin dict)
    (mixin (drscheme:language:language<%>) ()
      (super-new)

      (define/augment (capability-value key)
        (dict-ref/failure
         dict key
         (lambda ()
           (inner (drscheme:language:get-capability-default key)
                  capability-value key))))))

  (define language-level-no-executable-mixin
    (mixin (drscheme:language:language<%>) ()
      (super-new)
      (inherit get-language-name)

      (define/override (create-executable settings parent filename)
        (message-box
         "Create Executable: Error"
         (format "Sorry, ~a does not support creating executables."
                 (get-language-name))
         #f '(ok stop)))))

  (define language-level-macro-stepper-mixin
    (language-level-capability-mixin
     (make-immutable-hasheq
      (list (cons 'macro-stepper:enabled #t)))))

  (define (language-level-dynamic-setup-mixin proc)
    (mixin (drscheme:language:language<%>) ()
      (super-new)
      (define/override (on-execute settings run-in-user-thread)
        (run-in-user-thread (proc this settings))
        (super on-execute settings run-in-user-thread))))

  (define language-level-check-expect-mixin
    (compose
      (language-level-capability-mixin
        (make-immutable-hasheq
          (list (cons 'tests:test-menu #true)
                (cons 'tests:dock-menu #true))))
      (language-level-dynamic-setup-mixin
        (lambda (lang settings)
          (lambda ()
            ;; Test engine integration has been simplified
            ;; The new test-engine handles display automatically
            (void))))))

  (define (language-level-settings-mixin default is-default? build-config)
    (mixin (drscheme:language:language<%>) ()
      (super-new)

      (define/override (default-settings) default)
      (define/override (default-settings? settings) (is-default? settings))
      (define/override (config-panel parent) (build-config parent))))

  (define (language-level-metadata-mixin reader-module
                                         meta-lines
                                         meta->settings
                                         settings->meta)
    (mixin (drscheme:language:language<%>) ()
      (inherit default-settings)
      (super-new)

      (define/override (get-reader-module) reader-module)

      (define/override (get-metadata modname settings)
        (settings->meta modname settings))

      (define/override (metadata->settings metadata)
        (meta->settings metadata (default-settings)))

      (define/override (get-metadata-lines) meta-lines)))

  (define (generic-syntax-reader . args)
    (parameterize ([read-accept-reader #t])
      (apply read-syntax args)))

  (define (make-namespace-syntax-reader reader)
    (lambda args
      (let ([stx (apply reader args)])
        (if (syntax? stx) (namespace-syntax-introduce stx) stx))))

  (define drscheme-eventspace (current-eventspace))

  (define experimental-language-hierarchy
    (list (cons (string-constant experimental-languages)
                1000))))
