#lang racket/base

(require forms
         koyo/continuation
         koyo/database
         koyo/haml
         koyo/url
         racket/contract
         racket/match
         web-server/dispatchers/dispatch
         web-server/http
         "../components/auth.rkt"
         "../components/short-url.rkt"
         "../components/template.rkt"
         "../components/user.rkt")

(provide
 short-url-redirect-page
 short-urls-page
 create-short-url-page)

(define/contract ((short-url-redirect-page db) req code)
  (-> database? (-> request? string? response?))
  (define u (lookup-short-url db code))
  (unless u
    (next-dispatcher))
  (redirect-to (short-url-url u)))

(define/contract ((short-urls-page db) req)
  (-> database? (-> request? response?))
  (page
   (haml
    (.container
     (:h1 "Your Short URLs")
     (:table
      (:thead
       (:tr
        (:th "Code")
        (:th "Destination")
        (:th "Link")))
      (:tbody
       ,@(for/list ([u (in-list (list-short-urls db (user-id (current-user))))])
           (haml
            (:tr
             (:td (short-url-code u))
             (:td (short-url-url u))
             (:td (:a
                   ([:href (short-url-link u)])
                   (short-url-link u))))))))))))

(define short-url-form
  (form* ([url (ensure binding/text (required) (shorter-than 500))])
    url))

(define/contract ((create-short-url-page db) req)
  (-> database? (-> request? response?))
  (let loop ([req req])
    (send/suspend/dispatch/protect
     (lambda (embed/url)
       (match (form-run short-url-form req)
         [(list 'passed url _)
          (define the-url (create-short-url! db url (user-id (current-user))))
          (redirect-to (reverse-uri 'short-urls-page))]

         [(list _ _ rw)
          (page
           (haml
            (.container
             (:h1 "Create a short URL")
             (:form
              ([:action (embed/url loop)]
               [:method "POST"])
              (:label
               "URL:"
               (rw "url" (widget-text)))
              ,@(rw "url" (widget-errors))
              (:button
               ([:type "submit"])
               "Create Short URL")))))])))))
