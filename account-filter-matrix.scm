;; -*-scheme-*-

(define-module (gnucash reports example account-filter-matrix))

(use-modules (gnucash engine))
(use-modules (gnucash utilities))
(use-modules (gnucash core-utils))
(use-modules (gnucash app-utils))
(use-modules (gnucash report))
(use-modules (gnucash html))
(use-modules (srfi srfi-1))
(use-modules (ice-9 regex))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Options Configuration Layout
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(define (account-filter-matrix-options)
  (let* ((options (gnc:new-options))
         (optiondb (options #t)))

    (gnc-register-date-option-set
     optiondb
     "General" "Start Date"
     "1-start-date" "Beginning of reporting period."
     '(today
       start-cur-month
       start-prev-month
       start-cur-quarter
       start-prev-quarter
       start-cal-year
       start-prev-year
       start-accounting-period)
     #t)

    (gnc-register-date-option-set
     optiondb
     "General" "End Date"
     "2-end-date" "End of reporting period."
     '(today
       end-cur-month
       end-prev-month
       end-cur-quarter
       end-prev-quarter
       end-cal-year
       end-prev-year
       end-accounting-period)
     #t)

    (gnc-register-account-list-option
     optiondb
     "General"
     "Select Accounts to Display"
     "3-accounts"
     ""
     (gnc-account-list-from-types
      (gnc-get-current-book)
      (list ACCT-TYPE-BANK ACCT-TYPE-ASSET ACCT-TYPE-LIABILITY ACCT-TYPE-INCOME ACCT-TYPE-EXPENSE)))

    (gnc-register-string-option
     optiondb
     "General"
     "Filter Text"
     "4-filter-text"
     "Filter records matching this prefix. Leave blank for plain balances."
     "Cust")

    options))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Account Filtering & Naming Maps
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(define account-types
  (list
   ACCT-TYPE-BANK
   ACCT-TYPE-ASSET
   ACCT-TYPE-LIABILITY
   ACCT-TYPE-INCOME
   ACCT-TYPE-EXPENSE))

(define (get-account-type-name type-id)
  (cond
   ((= type-id ACCT-TYPE-BANK) "BANK")
   ((= type-id ACCT-TYPE-ASSET) "ASSET")
   ((= type-id ACCT-TYPE-LIABILITY) "LIABILITY")
   ((= type-id ACCT-TYPE-INCOME) "INCOME")
   ((= type-id ACCT-TYPE-EXPENSE) "EXPENSE")
   (else "UNMATCHED")))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Filter Classification
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(define (lower-case text)
  (string-downcase (or text "")))

(define (split-filter split filter-word)
  (let* ((transaction (xaccSplitGetParent split))
         (split-memo (lower-case (xaccSplitGetMemo split)))
         (description (lower-case (xaccTransGetDescription transaction)))
         (notes (lower-case (xaccTransGetNotes transaction)))
         (combined-text (string-append split-memo " " description " " notes))
         (target-word (lower-case filter-word)))

    (if (or (string=? target-word "") (not filter-word))
        "Unmatched"
        (let* ((pattern (string-append "\\b(" (regexp-quote target-word) "[a-zA-Z0-9_-]*)"))
               (match (string-match pattern combined-text)))
          (if match
              (string-titlecase (match:substring match 1))
              "Unmatched")))))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Period Filter Match Verification
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(define (split-in-period? split start-time end-time)
  (let* ((transaction (xaccSplitGetParent split))
         (tx-date (xaccTransGetDate transaction)))
    (cond
     ((and start-time end-time) (and (>= tx-date start-time) (<= tx-date end-time)))
     (start-time (>= tx-date start-time))
     (end-time (<= tx-date end-time))
     (else #t))))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; HTML Helpers (Aligned to Style Sheet Class Tokens)
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(define (format-gnc-numeric value commodity)
  (let* ((actual-commodity (if commodity commodity (gnc-default-currency)))
         (print-info (gnc-commodity-print-info actual-commodity #f)))
    (xaccPrintAmount value print-info)))

(define (number-cell value commodity)
  (if (gnc-numeric-zero-p value)
      (gnc:make-html-table-cell/markup "number-cell" "")
      (gnc:make-html-table-cell/markup "number-cell" (format-gnc-numeric value commodity))))

(define (bold-number-cell value commodity)
  (if (gnc-numeric-zero-p value)
      (gnc:make-html-table-cell/markup "total-number-cell" "")
      (gnc:make-html-table-cell/markup "total-number-cell" (format-gnc-numeric value commodity))))

(define (text-cell value)
  (gnc:make-html-table-cell/markup "text-cell" value))

(define (header-cell value)
  (gnc:make-html-table-cell/markup "column-heading-left" value))

(define (type-heading-cell value)
  (gnc:make-html-table-header-cell/markup "column-heading-left" value))

(define (empty-cell)
  (gnc:make-html-table-cell/markup "text-cell" ""))

(define (bold-text-cell value)
  (gnc:make-html-table-cell/markup "total-label-cell" value))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Renderer
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(define (account-filter-matrix-renderer report-obj)
  (define (op-value section name)
    (let ((options-raw (gnc:report-options report-obj)))
      (gnc-optiondb-lookup-value (if (procedure? options-raw) (options-raw 'lookup) options-raw)
                                  section name)))

  (let* ((start-date-opt (op-value "General" "Start Date"))
         (end-date-opt   (op-value "General" "End Date"))

         (start-date (and start-date-opt (gnc:date-option-absolute-time start-date-opt)))
         (end-date   (and end-date-opt   (gnc:date-option-absolute-time end-date-opt)))

         (selected-accounts (op-value "General" "Select Accounts to Display"))
         (raw-filter-text (op-value "General" "Filter Text"))
         (filter-text (if raw-filter-text (string-trim-both raw-filter-text) ""))
         (has-filter? (not (string=? filter-text "")))

         (document (gnc:make-html-document))
         (table    (gnc:make-html-table))
         (root     (gnc-get-current-root-account))

         (all-accounts (if (and selected-accounts (not (null? selected-accounts)))
                           selected-accounts
                           (gnc-account-get-descendants root)))

         (unmatched "Unmatched"))

    ;; Data Collection Engine
    (define (get-total account target-filter)
      (let ((splits (xaccAccountGetSplitList account)))
        (fold
         (lambda (split accum)
           (let* ((filter-name (split-filter split filter-text))
                  (val (xaccSplitGetValue split)))
             (cond
              ((not (split-in-period? split start-date end-date)) accum)
              ((not target-filter) (gnc-numeric-add accum val GNC-DENOM-AUTO GNC-HOW-RND-ROUND))
              ((string=? filter-name target-filter) (gnc-numeric-add accum val GNC-DENOM-AUTO GNC-HOW-RND-ROUND))
              (else accum))))
         (gnc-numeric-zero)
         splits)))

    ;; Dynamic Filter Scanner Engine
    (define (extract-dynamic-filters accounts)
      (if (not has-filter?)
          '()
          (delete-duplicates
           (filter
            (lambda (name) (and (not (string=? name "Unmatched"))
                                (string-prefix-ci? filter-text name)))
            (append-map
             (lambda (acc)
               (map (lambda (s) (split-filter s filter-text)) (xaccAccountGetSplitList acc)))
             accounts))
           string=?)))

    ;; Full tree path builder
    (define (build-full-name account)
      (let loop ((acc account) (path-list '()))
        (if (or (not acc) (gnc-account-is-root acc))
            (string-join path-list ":")
            (loop (gnc-account-get-parent acc)
                  (cons (xaccAccountGetName acc) path-list)))))

    ;; Populate the active list of discovered filter tokens
    (define active-filters (sort (extract-dynamic-filters all-accounts) string<?))
    (gnc:html-document-set-title! document (N_ "Account Filter Matrix"))

    ;; Dynamic Header Subtitles
    (let ((start-str (if start-date (qof-print-date start-date) #f))
          (end-str   (if end-date   (qof-print-date end-date)   #f)))
      (gnc:html-document-add-object! document
        (gnc:make-html-text
         (format #f "<p style=\"font-weight: bold; margin-bottom: 5px;\">Period: ~a</p><p style=\"font-style: italic; margin-bottom: 15px;\">Filter Text: ~a</p>"
                 (cond ((and start-str end-str) (format #f "~a to ~a" start-str end-str))
                       (start-str (format #f "From ~a onwards" start-str))
                       (end-str   (format #f "Up to ~a" end-str))
                       (else "All Time"))
                 (if has-filter? (format #f "\"~a\"" filter-text) "None (Plain Account Balances)")))))

    ;; Header row
    (gnc:html-table-append-row!
     table
     (append
      (list (header-cell "Account"))
      (map header-cell active-filters)
      (if has-filter? (list (header-cell unmatched)) '())
      (list (header-cell "Total"))))

    ;; Map groupings across target ledger accounts
    (for-each
     (lambda (type-id)
       (let ((type-accounts
              (filter
               (lambda (acc) (= (xaccAccountGetType acc) type-id))
               all-accounts)))

         (if (not (null? type-accounts))
             (begin
               ;; Type Heading Row
               (gnc:html-table-append-row/markup!
                table
                "primary-subheading"
                (append
                 (list (type-heading-cell (string-upcase (get-account-type-name type-id))))
                 (map (lambda (x) (empty-cell)) active-filters)
                 (if has-filter? (list (empty-cell)) '())
                 (list (empty-cell))))

               ;; Record Mapping Generation (Only Display Rows with a Non-Zero Value)
               (for-each
                (lambda (account)
                  (let* ((comm (xaccAccountGetCommodity account))
                         (filter-vals (map (lambda (f) (get-total account f)) active-filters))
                         (ot-val    (get-total account unmatched))
                         (tt-val    (get-total account #f))
                         ;; Consolidate all individual column figures in the row
                         (all-row-vals (cons ot-val filter-vals)))

                    ;; Only output row if at least one column has a non-zero value
                    (if (any (lambda (val) (not (gnc-numeric-zero-p val))) all-row-vals)
                        (gnc:html-table-append-row!
                         table
                         (append
                          (list (text-cell (build-full-name account)))
                          (map (lambda (v) (number-cell v comm)) filter-vals)
                          (if has-filter? (list (number-cell ot-val comm)) '())
                          (list (number-cell tt-val comm)))))))
                type-accounts)

               ;; Category Totals Layout
               (let* ((sub-filters (map (lambda (f) (fold (lambda (a t) (gnc-numeric-add t (get-total a f) GNC-DENOM-AUTO GNC-HOW-RND-ROUND)) (gnc-numeric-zero) type-accounts)) active-filters))
                      (sub-ot    (fold (lambda (a t) (gnc-numeric-add t (get-total a unmatched) GNC-DENOM-AUTO GNC-HOW-RND-ROUND)) (gnc-numeric-zero) type-accounts))
                      (sub-tt    (fold (lambda (a t) (gnc-numeric-add t (get-total a #f) GNC-DENOM-AUTO GNC-HOW-RND-ROUND)) (gnc-numeric-zero) type-accounts)))
                 (gnc:html-table-append-row!
                  table
                  (append
                   (list (bold-text-cell (format #f "Total ~a" (string-titlecase (get-account-type-name type-id)))))
                   (map (lambda (v) (bold-number-cell v #f)) sub-filters)
                   (if has-filter? (list (bold-number-cell sub-ot #f)) '())
                   (list (bold-number-cell sub-tt #f)))))))))
     account-types)

    ;; Final Matrix Calculation Generation
    (let* ((grand-filters (map (lambda (f) (fold (lambda (a t) (gnc-numeric-add t (get-total a f) GNC-DENOM-AUTO GNC-HOW-RND-ROUND)) (gnc-numeric-zero) all-accounts)) active-filters))
           (grand-ot    (fold (lambda (a t) (gnc-numeric-add t (get-total a unmatched) GNC-DENOM-AUTO GNC-HOW-RND-ROUND)) (gnc-numeric-zero) all-accounts))
           (grand-tt    (fold (lambda (a t) (gnc-numeric-add t (get-total a #f) GNC-DENOM-AUTO GNC-HOW-RND-ROUND)) (gnc-numeric-zero) all-accounts)))
      (gnc:html-table-append-row/markup!
       table
       "grand-total"
       (append
        (list (bold-text-cell "Grand Total"))
        (map (lambda (v) (bold-number-cell v #f)) grand-filters)
        (if has-filter? (list (bold-number-cell grand-ot #f)) '())
        (list (bold-number-cell grand-tt #f)))))

    (gnc:html-document-add-object! document table)
    document))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Report Registration
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(gnc:define-report
 'version 1
 'name (N_ "Account Filter Matrix")
 'report-guid "7b37f3b79b2f4b2f8b2d0bb91b5f3db7"
 'menu-path (list gnc:menuname-example)
 'options-generator account-filter-matrix-options
 'renderer account-filter-matrix-renderer)
