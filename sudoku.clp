;;; Version 1.2
;;; 
;;; JRules Changes

;;; Reference Material
;;;
;;; http://www.angusj.com/sudoku/hints
;;; http://www.scanraid.com/BasicStrategies.htm
;;; http://www.sudokuoftheday.com/pages/techniques-overview
;;; http://www.sudokuonline.us/sudoku_solving_techniques
;;; http://www.sadmansoftware.com/sudoku/techniques.htm
;;; http://www.krazydad.com/blog/2005/09/29/an-index-of-sudoku-strategies/

;;; #######################
;;; DEFTEMPLATES & DEFFACTS
;;; #######################

(deftemplate possible
   (slot row)
   (slot column)
   (slot value)
   (slot group)
   (slot id)
   (slot diagonal))
   
(deftemplate impossible
   (slot id)
   (slot value)
   (slot rank)
   (slot reason))
   
(deftemplate technique-employed
   (slot reason)
   (slot rank))

(deftemplate technique
   (slot name)
   (slot rank))
   
(deftemplate size-value
   (slot size)
   (slot value))
   
(deftemplate iterate-rc
   (slot row)
   (slot column)
   (slot index)
   (slot diagonal))
   
(deftemplate rank
   (slot value)
   (slot process))
   
(deftemplate unsolved
   (slot row)
   (slot column))
      
;;; ###########
;;; SETUP RULES
;;; ###########

;;; **********
;;; initialize
;;; **********

(defrule initialize

   =>

   (assert (phase grid-values))

   (assert (size-value (size 1) (value 1)))
   (assert (size-value (size 2) (value 2)))
   (assert (size-value (size 2) (value 3)))
   (assert (size-value (size 2) (value 4)))
   (assert (size-value (size 3) (value 5)))
   (assert (size-value (size 3) (value 6))))

;;; ***********
;;; stress-test
;;; ***********

(defrule stress-test
   
   (declare (salience 10))
   
   (phase match)
   
   (stress-test)
   
   (rank (value ?last))
   
   (not (rank (value ?p&:(> ?p ?last))))
   
   (technique (rank ?next&:(> ?next ?last)))
   
   (not (technique (rank ?p&:(> ?p ?last)&:(< ?p ?next))))
   
   =>
   
   (assert (rank (value ?next) (process yes))))
   
;;; *****************
;;; enable-techniques
;;; *****************

(defrule enable-techniques

   (declare (salience 10))
   
   (phase match)
   
   (size ?)
   
   (not (possible (value any)))
   
   (not (rank))
   
   =>
   
   (assert (rank (value 1) (process yes))))


;;; ****************
;;; expand-any-start
;;; ****************

(defrule expand-any-start

   (declare (salience 10))

   (phase expand-any)
   
   (possible (row ?r) (column ?c) (value any) (id ?id) (diagonal ?d))
  
   (not (possible (value any) (id ?id2&:(< ?id2 ?id)) (diagonal ?d)))
      
   =>
      
   (assert (iterate-rc (row ?r) (column ?c) (index 1) (diagonal ?d))))

;;; **********
;;; expand-any
;;; **********

(defrule expand-any

   (declare (salience 10))

   (phase expand-any)
   
   (possible (row ?r) (column ?c) (value any) (group ?g) (id ?id) (diagonal ?d))
  
   (not (possible (value any) (id ?id2&:(< ?id2 ?id)) (diagonal ?d)))
   
   (size ?s)
   
   ?f <- (iterate-rc (row ?r) (column ?c) (index ?v) (diagonal ?d))
   
   (size-value (size ?as&:(<= ?as ?s)) (value ?v))
   
   (not (possible (row ?r) (column ?c) (value ?v)(diagonal ?d)) )
     
   =>
   
   (assert (possible (row ?r) (column ?c) (value ?v) (group ?g) (id ?id) (diagonal ?d)))
   
   (modify ?f (index (+ ?v 1))))
   
;;; *****************
;;; position-expanded
;;; *****************

(defrule position-expanded

   (declare (salience 10))

   (phase expand-any)
   
   ?f1 <- (possible (row ?r) (column ?c) (value any) (diagonal ?d))
     
   (size ?s)
   
   ?f2 <- (iterate-rc (row ?r) (column ?c) (index ?v) (diagonal ?d))
   
   (not (size-value (size ?as&:(<= ?as ?s)) (value ?v)))

   =>
   
   (assert (unsolved (row ?r) (column ?c)))
   
   (retract ?f1 ?f2))
   
;;; ###########
;;; PHASE RULES
;;; ###########

;;; ***************
;;; expand-any-done
;;; ***************

(defrule expand-any-done

   (declare (salience 10))

   ?f <- (phase expand-any)

   (not (possible (value any)))
   
   =>
   
   (retract ?f)
   
   (assert (phase initial-output))
   (assert (print-position 1 1)))
   
;;; ***********
;;; begin-match
;;; ***********

(defrule begin-match

   (declare (salience -20))
   
   ?f <- (phase initial-output)
      
   =>
   
   (retract ?f)
   
   (assert (phase match)))

;;; *****************
;;; begin-elimination
;;; *****************

(defrule begin-elimination

   (declare (salience -20))
   
   ?f <- (phase match)
   
   (not (not (impossible)))
   
   =>
   
   (retract ?f)
   
   (assert (phase elimination)))

;;; ******************
;;; next-rank-unsolved
;;; ******************

(defrule next-rank-unsolved

   (declare (salience -20))
   
   (phase match)
   
   (not (impossible))
   
   (rank (value ?last))
   
   (not (rank (value ?p&:(> ?p ?last))))
   
   (technique (rank ?next&:(> ?next ?last)))
   
   (not (technique (rank ?p&:(> ?p ?last)&:(< ?p ?next))))
   
   (exists (unsolved))
      
   =>
      
   (assert (rank (value ?next) (process yes))))

;;; **********************
;;; next-rank-not-unsolved
;;; **********************

(defrule next-rank-not-unsolved

   (declare (salience -20))

   (phase match)
   
   (not (impossible))
   
   (rank (value ?last))
   
   (not (rank (value ?p&:(> ?p ?last))))
   
   (technique (rank ?next&:(> ?next ?last)))
   
   (not (technique (rank ?p&:(> ?p ?last)&:(< ?p ?next))))
   
   (not (unsolved))
   
   =>
      
   (assert (rank (value ?next) (process no))))

;;; ************
;;; begin-output
;;; ************

(defrule begin-output

   (declare (salience -20))
   
   ?f <- (phase match)
   
   (not (impossible))
   
   (rank (value ?last))
   
   (not (rank (value ?p&:(> ?p ?last))))

   (not (technique (rank ?next&:(> ?next ?last))))
   
   =>
   
   (retract ?f)
   
   (assert (phase final-output))
   (assert (print-position 1 1)))