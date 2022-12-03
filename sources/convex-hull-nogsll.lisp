;;;; -*- mode: lisp; syntax: ANSI-Common-Lisp; indent-tabs-mode: nil; coding: utf-8; show-trailing-whitespace: t -*-
;;;; convex-hull-nogsll.lisp

(in-package #:convex-hull-nogsll)

;; Functions.

(defun elt- (a b)
  (check-type a (or simple-array
                    simple-vector
                    array))
  (check-type b (or simple-array
                    simple-vector
                    array))
  (assert (equalp (array-dimensions a)
                  (array-dimensions b)))
  (let ((return-value (make-array (array-dimensions a)
                                  :element-type (array-element-type a)
                                  :initial-element (coerce 0 (array-element-type a)))))
    (loop
      for i from 0 below (reduce #'(lambda (x y)
                                     (* x y))
                                 (array-dimensions a))
      do
         (setf (row-major-aref return-value i) (- (row-major-aref a i)
                                                  (row-major-aref b i))))
    return-value))

(defun euclidean-norm (a)
  (check-type a (or simple-array
                    simple-vector
                    array))
  (sqrt (loop
          for i from 0 below (reduce #'(lambda (x y)
                                         (* x y))
                                     (array-dimensions a))
          sum (expt (row-major-aref a i) 2d0))))

(defun make-path (a)
  (check-type a list)
  (loop
    for i from 0 below (1- (length a))
    for j from (1+ i)
    collect (list (nth i a)
		  (nth j a))))

(defun cw (p1 p2 p3)
  "cw return true if p1 p2 and p3 make a clockwise turn."
  (check-type p1 (or simple-array
                     simple-vector
                     array))
  (assert (= 1 (length (array-dimensions p1))))
  (assert (= 2 (array-dimension p1 0)))
  (check-type p2 (or simple-array
                     simple-vector
                     array))
  (assert (= 1 (length (array-dimensions p2))))
  (assert (= 2 (array-dimension p2 0)))
  (check-type p3 (or simple-array
                     simple-vector
                     array))
  (assert (= 1 (length (array-dimensions p3))))
  (assert (= 2 (array-dimension p3 0)))
  (< (+ (* (aref p1 0) (- (aref p2 1) (aref p3 1)))
        (* (aref p2 0) (- (aref p3 1) (aref p1 1)))
        (* (aref p3 0) (- (aref p1 1) (aref p2 1))))
     0d0))

(defun ccw (p1 p2 p3)
  "ccw return true if p1 p2 and p3 make a counter clockwise turn."
  (check-type p1 (or simple-array
                     simple-vector
                     array))
  (assert (= 1 (length (array-dimensions p1))))
  (assert (= 2 (array-dimension p1 0)))
  (check-type p2 (or simple-array
                     simple-vector
                     array))
  (assert (= 1 (length (array-dimensions p2))))
  (assert (= 2 (array-dimension p2 0)))
  (check-type p3 (or simple-array
                     simple-vector
                     array))
  (assert (= 1 (length (array-dimensions p3))))
  (assert (= 2 (array-dimension p3 0)))
  (> (+ (* (aref p1 0) (- (aref p2 1) (aref p3 1)))
        (* (aref p2 0) (- (aref p3 1) (aref p1 1)))
        (* (aref p3 0) (- (aref p1 1) (aref p2 1))))
     0d0))

(defun sort-points (points-list &rest parameters &key
                                                   (verbose nil))
  "Sorts point in respect the angular position of point."
  (declare (ignorable parameters
                      verbose))
  (check-type points-list list)
  (loop
    for point in points-list
    do
       (check-type point (or simple-array
                             simple-vector
                             array))
       (assert (equalp (array-dimensions point) '(2))))
  (let ((return-value nil))
    (when verbose
      (format *standard-output* "Entering sort-points. ========~%")
      (finish-output *standard-output*))
    (setq return-value (sort (copy-seq points-list)
                             #'(lambda (a b)
                                 (or (< (aref a 0) (aref b 0))
                                     (and (= (aref a 0) (aref b 0))
                                          (< (aref a 1) (aref b 1)))))))
    (when verbose
      (format *standard-output* "Sorted points set: ~s~%" return-value)
      (format *standard-output* "Exiting sort-points. ========~%")
      (finish-output *standard-output*))
    return-value))

(defun perimeter (points-list &rest parameters &key (verbose nil))
  "Compute the perimeter for the convex hull."
  (declare (ignorable parameters verbose))
  (check-type points-list list)
  (let ((return-value nil))
    (when verbose
      (format *standard-output* "Entering perimeter. ========~%")
      (format *standard-output* "Input convex hull set: ~a~%" points-list)
      (finish-output *standard-output*))
    (setq return-value (loop
                         for p in points-list
                         sum (euclidean-norm (reduce #'(lambda (x y)
                                                         (elt- (copy-seq x) (copy-seq y)))
                                                     p))))
    (when verbose
      (format *standard-output* "Perimeter value: ~a~%" return-value)
      (format *standard-output* "Exiting sort-points. ========~%")
      (finish-output *standard-output*))
    return-value))

(defun convex-hull-nogsll (points-list &rest parameters &key
                                                          (iterations-limit nil)
                                                          (verbose nil))
  "Compute the convex hull for points set. Result in a stack."
  (declare (ignorable parameters iterations-limit verbose))
  (check-type points-list list)
  (loop
    for point in points-list
    do
       (check-type point (or simple-array
                             simple-vector
                             array))
       (assert (equalp (array-dimensions point) '(2))))
  (when iterations-limit
    (check-type iterations-limit (integer 1)))
  (let ((sorted-points nil)
        (p1 nil)
        (p2 nil)
        (up-stack '())
        (down-stack '())
        (return-value nil))
    (setq sorted-points (sort-points points-list
                                     :verbose verbose))
    (setq p1 (first sorted-points)
          p2 (first (last sorted-points)))
    (when verbose
      (format *standard-output* "Leftmost point: ~a~%Rightmost point: ~a~%" p1 p2)
      (finish-output *standard-output*))
    (push p1 up-stack)
    (push p1 down-stack)
    (loop
      named main-loop
      for i from 1 below (length sorted-points)
      for j from 0
      do
         (when iterations-limit
           (when (>= j iterations-limit)
             (when verbose
               (format *standard-output*
                       "Iterations count limit reached (~a).  Stop.~%"
                       j)
               (finish-output *standard-output*))
             (setq return-value nil)
             (return-from main-loop)))
         (when (or (= i (1- (length sorted-points)))
                   (cw p1 (nth i sorted-points) p2))
           (loop
             while (and (>= (length up-stack) 2)
                        (not (cw (second up-stack) (first up-stack) (nth i sorted-points))))
             do
                (pop up-stack))
           (push (nth i sorted-points) up-stack))
         (when (or (= i (1- (length sorted-points)))
                   (ccw p1 (nth i sorted-points)  p2))
           (loop
             while (and (>= (length down-stack) 2)
                        (not (ccw (second down-stack) (first down-stack) (nth i sorted-points))))
             do
                (pop down-stack))
           (push (nth i sorted-points) down-stack)))
    (when verbose
      (format *standard-output* "Down stack: ~s~%Up stack: ~s~%" down-stack up-stack)
      (finish-output *standard-output*))
    (setq return-value (concatenate 'list
                                    (subseq (reverse down-stack) 0 (1- (length down-stack)))
                                    up-stack))
    (when verbose
      (format *standard-output* "Convex hull: ~s~%" return-value)
      (finish-output *standard-output*))
    (make-path return-value)))

(defun main (points-list &rest parameters &key
                                            (iterations-limit nil)
                                            (verbose nil))
  "Main function."
  (declare (ignorable parameters
                      iterations-limit
                      verbose))
  (check-type points-list list)
  (loop
    for point in points-list
    do
       (check-type point (or simple-array
                             simple-vector
                             array))
       (assert (equalp (array-dimensions point) '(2))))
  (when iterations-limit
    (check-type iterations-limit (integer 1)))
  (convex-hull-nogsll points-list
                      :iterations-limit iterations-limit
                      :verbose verbose))
