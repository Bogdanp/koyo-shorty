#lang racket/base

(require db
         deta
         gregor
         koyo/database
         koyo/profiler
         koyo/url
         racket/contract
         racket/format
         racket/port
         racket/random
         racket/string
         threading)

(provide
 (schema-out short-url)
 short-url-link
 lookup-short-url
 list-short-urls
 create-short-url!)

(define (generate-code)
  (with-output-to-string
   (lambda ()
     (for ([b (crypto-random-bytes 2)])
       (display (~a (number->string b 16)
                    #:align 'right
                    #:left-pad-string "0"
                    #:width 2))))))

(define-schema short-url
  #:table "short_urls"
  ([id id/f #:primary-key #:auto-increment]
   [code string/f]
   [url string/f #:contract non-empty-string? #:wrapper string-trim]
   [user-id integer/f]
   [(created-at (now/moment)) datetime-tz/f]))

(define/contract (short-url-link u)
  (-> short-url? string?)
  (make-application-url (short-url-code u)))

(define/contract (lookup-short-url db code)
  (-> database? string? (or/c #f short-url?))
  (with-database-connection [conn db]
    (lookup conn (~> (from short-url #:as su)
                     (where (= su.code ,code))))))

(define/contract (list-short-urls db user-id)
  (-> database? id/c (listof short-url?))
  (with-timing 'short-url "(list-short-urls ...)"
    (with-database-connection [conn db]
      (for/list ([u (in-entities conn (~> (from short-url #:as su)
                                          (where (= su.user-id ,user-id))
                                          (order-by ([su.created-at #:desc]))))])
        u))))

(define/contract (create-short-url! db url user-id)
  (-> database? string? id/c short-url?)
  (with-database-connection [conn db]
    (let loop ()
      (with-handlers ([exn:fail:sql?
                       (lambda (e)
                         (case (exn:fail:sql-sqlstate e)
                           [("23505") (loop)]
                           [else (raise e)]))])
        (insert-one! conn (make-short-url #:code (generate-code)
                                          #:url url
                                          #:user-id user-id))))))
