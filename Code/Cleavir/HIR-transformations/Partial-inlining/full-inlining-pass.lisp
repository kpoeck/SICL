(in-package #:cleavir-partial-inlining)

(defun enter-unique-p (enter dag)
  (= (length (gethash enter (cleavir-hir-transformations:dag-nodes dag))) 1))

;; FIXME: move? finesse?
(defun all-parameters-required-p (enter)
  (every (lambda (param) (typep param 'cleavir-ir:lexical-location))
         (cleavir-ir:lambda-list enter)))

;; get one potential inline that can be done, or else NIL.
;; An inline here is a list (enter call uniquep), where uniquep expresses whether the function
;; is not used for anything but this call.
(defun one-potential-inline (dag destinies)
  (let ((trappers (cleavir-hir-transformations:discern-trappers dag destinies)))
    (labels ((maybe-return-inline (node)
               (let ((enter (cleavir-hir-transformations:enter-instruction node)))
                 (when (and (all-parameters-required-p enter)
                            (gethash enter trappers))
                   ;; function's environment does not escape.
                   ;; Now we just need to pick off any recursive uses, direct or indirect.
                   (loop with enclose = (cleavir-hir-transformations:enclose-instruction node)
                         with result
                         with enclose-destinies = (gethash enclose destinies)
                         with enclose-unique-p = (= (length enclose-destinies) 1)
                         with enter-unique-p = (enter-unique-p enter dag)
                         for caller in enclose-destinies
                         when (eq caller :escape)
                           return nil
                         when (parent-node-p node (instruction-owner caller)) ; recursive
                           return nil
                         ;; We're all good, but keep looking through for escapes and recursivity.
                         do (setf result (list enter caller node enclose-unique-p enter-unique-p))
                         finally (return-from one-potential-inline result)))))
             (parent-node-p (parent enter)
               ;; parent is a node (i.e. enclose), enter is an enter instruction
               ;; we return T iff the enter is enclosed by a node that has parent
               ;; as an ancestor.
               (let ((todo (gethash enter (cleavir-hir-transformations:dag-nodes dag))))
                 (loop until (null todo)
                       do (let ((test (pop todo)))
                            (cond ((eq test dag) (return nil)) ; recursed all the way up
                                  ((eq test parent) (return t))
                                  (t (setf todo
                                           (append todo
                                                   (cleavir-hir-transformations:parents test)))))))))
             (depth-first-search (node)
               (maybe-return-inline node)
               ;; It didn't return, so keep going.
               (mapc #'depth-first-search (cleavir-hir-transformations:children node))))
      ;; We don't call maybe-return-inline on the toplevel function itself, since it obviously can't
      ;; be inlined, and doesn't have an enclose-instruction, etc.
      (mapc #'depth-first-search (cleavir-hir-transformations:children dag))
      ;; No dice.
      nil)))

(defun update-destinies-map (worklist destinies-map)
  (let ((encloses '()))
    (dolist (thing worklist)
      (etypecase thing
        (cleavir-ir:enclose-instruction
         (pushnew thing encloses))
        (cleavir-ir:funcall-instruction
         (dolist (enclose (cleavir-hir-transformations:destiny-find-encloses thing))
           (pushnew enclose encloses)))))
    (dolist (enclose encloses)
      (setf (gethash enclose destinies-map)
            (cleavir-hir-transformations:find-enclose-destinies enclose)))))

(defun do-inlining (initial-instruction)
  ;; Need to remove all useless instructions first for incremental
  ;; r-u-i to catch everything.
  (cleavir-remove-useless-instructions:remove-useless-instructions initial-instruction)
  (loop with *instruction-ownerships*
          = (cleavir-hir-transformations:compute-instruction-owners initial-instruction)
        with *location-ownerships*
          = (cleavir-hir-transformations:compute-location-owners initial-instruction)
        with *function-dag* = (cleavir-hir-transformations:build-function-dag initial-instruction)
        with *destinies-map* = (cleavir-hir-transformations:compute-destinies initial-instruction)
        with *destinies-worklist* = '()
        for inline = (one-potential-inline *function-dag* *destinies-map*)
        until (null inline)
        do (destructuring-bind (enter call node enclose-unique-p enter-unique-p) inline
             ;; Find all instructions that could potentially be deleted after inlining.
             (let ((function-defs (cleavir-ir:defining-instructions (first (cleavir-ir:inputs call))))
                   (destinies-map *destinies-map*))
               (if (and enclose-unique-p enter-unique-p)
                   (interpolate-function call enter)
                   (inline-function initial-instruction call enter (make-hash-table :test #'eq)))
               (dolist (deleted
                        (cleavir-remove-useless-instructions:remove-useless-instructions-from function-defs))
                 (typecase deleted
                   (cleavir-ir:enclose-instruction
                    (cleavir-hir-transformations:remove-enclose-from-function-dag
                     *function-dag*
                     deleted
                     (and enclose-unique-p enter-unique-p)))))
               ;; The call is gone, so it is no longer a destiny.
               (update-destinies-map (cons (cleavir-hir-transformations:enclose-instruction node)
                                           *destinies-worklist*)
                                     destinies-map)
               (setf *destinies-worklist* nil))))
  (cleavir-remove-useless-instructions:remove-useless-instructions initial-instruction))
