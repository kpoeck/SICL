(cl:in-package #:sicl-hir-to-cl)

(defun make-code-bindings (client initial-instruction context)
  (let ((enter-instructions (sort-functions initial-instruction)))
    (loop for enter-instruction in (butlast enter-instructions)
          collect `(,(gethash enter-instruction (function-names context))
                    ,(translate-enter-instruction client enter-instruction context)))))

(defun find-values-locations (initial-instruction)
  (let ((result (make-hash-table :test #'eq)))
    (cleavir-ir:map-instructions-arbitrary-order
     (lambda (instruction)
       (loop with inputs = (cleavir-ir:inputs instruction)
             with outputs = (cleavir-ir:outputs instruction)
             for datum in (append inputs outputs)
             when (typep datum 'cleavir-ir:values-location)
               do (let ((symbol (gethash datum result)))
                    (if (null symbol)
                        (setf (gethash datum result) (gensym))
                        symbol))))
     initial-instruction)
    result))

(defun all-values-location-names (table)
  (loop for name being each hash-value of table
        collect name))

(defun values-location-name (values-location context)
  (gethash values-location (values-locations context)))

(defun hir-to-cl (client initial-instruction)
  (let* ((enter-instructions (sort-functions initial-instruction))
         (values-locations (find-values-locations initial-instruction))
         (context (make-instance 'context :values-locations values-locations))
         (lexical-locations (find-lexical-locations initial-instruction))
         (successor (first (cleavir-ir:successors initial-instruction)))
         (*static-environment-variable* (gensym "static-environment"))
         (*top-level-function-parameter* (gensym "function-cell"))
         (basic-blocks (compute-basic-blocks initial-instruction))
         (*dynamic-environment-of-basic-block* (make-hash-table :test #'eq))
         (*basic-blocks-in-dynamic-environment* (make-hash-table :test #'eq))
         (*basic-block-of-leader* (make-hash-table :test #'eq))
         (*tag-of-basic-block* (make-hash-table :test #'eq)))
    (loop for basic-block in basic-blocks
          for leader = (first (instructions basic-block))
          for dynamic-environment-location
            = (cleavir-ir:dynamic-environment-location leader)
          do (setf (gethash basic-block *dynamic-environment-of-basic-block*)
                   dynamic-environment-location)
             (push basic-block
                   (gethash dynamic-environment-location
                            *basic-blocks-in-dynamic-environment*))
             (setf (gethash leader *basic-block-of-leader*)
                   basic-block)
             (setf (gethash basic-block *tag-of-basic-block*)
                   (gensym)))
    (loop for enter-instruction in (butlast enter-instructions)
          do (setf (gethash enter-instruction (function-names context))
                   (gensym "code")))
    `(lambda (,*top-level-function-parameter*)
       (let* ((,(static-env-function-var context)
                (car (funcall ,*top-level-function-parameter* 'static-environment-function)))
              ,@(all-values-location-names (values-locations context))
              ,@(make-code-bindings client initial-instruction context)
              ,@(mapcar #'cleavir-ir:name lexical-locations)
              (,*static-environment-variable*
                (vector nil)))
         (declare (ignore ,(cleavir-ir:name
                            (cleavir-ir:dynamic-environment-location initial-instruction))))
         (declare (ignorable ,(cleavir-ir:name
                               (first (cleavir-ir:outputs initial-instruction)))
                             ,*static-environment-variable*))
         (declare (ignorable ,@(mapcar #'cleavir-ir:name lexical-locations)))
         (declare (ignorable ,(static-env-function-var context)))
         (block ,(block-name context)
           (tagbody (go ,(tag-of-basic-block (basic-block-of-leader successor)))
              ,@(loop with dynamic-environment-location
                        = (cleavir-ir:dynamic-environment-location successor)
                      with basic-blocks
                        = (basic-blocks-in-dynamic-environment
                           dynamic-environment-location)
                      for basic-block in basic-blocks
                      collect (tag-of-basic-block basic-block)
                      append (let ((*dynamic-environment-stack*
                                     (list dynamic-environment-location)))
                               (translate-basic-block
                                client
                                basic-block
                                context)))))))))

(defmethod translate
    (client (instruction sicl-hir-transformations::find-function-cell-instruction) context)
  (let* ((name (sicl-hir-transformations::name instruction))
         (output (first (cleavir-ir:outputs instruction)))
         (output-name (cleavir-ir:name output)))
  `((setq ,output-name
          (funcall ,*top-level-function-parameter* ',name)))))
