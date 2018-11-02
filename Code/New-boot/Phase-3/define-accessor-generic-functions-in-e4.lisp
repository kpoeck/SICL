(cl:in-package #:sicl-new-boot-phase-3)

(defun ensure-generic-function-phase-3 (boot)
  (with-accessors ((e2 sicl-new-boot:e2)
                   (e3 sicl-new-boot:e3)
                   (e4 sicl-new-boot:e4)) boot
    (let* ((gf-class-name 'standard-generic-function)
           (make-instance (sicl-genv:fdefinition 'make-instance e3)))
      (setf (sicl-genv:fdefinition 'ensure-generic-function e4)
            (lambda (function-name &rest arguments
                     &key environment
                     &allow-other-keys)
              (let ((args (copy-list arguments)))
                (loop while (remf args :environment))
                (if (sicl-genv:fboundp function-name environment)
                    (sicl-genv:fdefinition function-name environment)
                    (setf (sicl-genv:fdefinition function-name environment)
                          (apply make-instance
                                 gf-class-name
                                 :name function-name
                                 :method-combination
                                 (funcall (sicl-genv:fdefinition
                                           'sicl-method-combination:find-method-combination e3)
                                          'standard '() e3)
                                 args)))))))))

(defun enable-generic-function-initialization (boot)
  (with-accessors ((e3 sicl-new-boot:e3)) boot
    (import-functions-from-host
     '(cleavir-code-utilities:parse-generic-function-lambda-list
       cleavir-code-utilities:required)
     e3)
    ;; MAKE-LIST is called from the :AROUND method on
    ;; SHARED-INITIALIZE specialized to GENERIC-FUNCTION.
    (import-function-from-host 'make-list e3)
    ;; SET-DIFFERENCE is called by the generic-function initialization
    ;; protocol to verify that the argument precedence order is a
    ;; permutation of the required arguments.
    (import-function-from-host 'set-difference e3)
    ;; STRINGP is called by the generic-function initialization
    ;; protocol to verify that the documentation is a string.
    (import-function-from-host 'stringp e3)
    (load-file "CLOS/generic-function-initialization-support.lisp" e3)
    (setf (sicl-genv:fdefinition 'sicl-clos::invalidate-discriminating-function e3)
          #'identity)
    (load-file "CLOS/generic-function-initialization-defmethods.lisp" e3)))

(defun load-accessor-defgenerics (e4)
  (load-file "CLOS/specializer-direct-generic-functions-defgeneric.lisp" e4)
  (load-file "CLOS/setf-specializer-direct-generic-functions-defgeneric.lisp" e4)
  (load-file "CLOS/specializer-direct-methods-defgeneric.lisp" e4)
  (load-file "CLOS/setf-specializer-direct-methods-defgeneric.lisp" e4)
  (load-file "CLOS/eql-specializer-object-defgeneric.lisp" e4)
  (load-file "CLOS/unique-number-defgeneric.lisp" e4)
  (load-file "CLOS/class-name-defgeneric.lisp" e4)
  (load-file "CLOS/class-direct-subclasses-defgeneric.lisp" e4)
  (load-file "CLOS/setf-class-direct-subclasses-defgeneric.lisp" e4)
  (load-file "CLOS/class-direct-default-initargs-defgeneric.lisp" e4)
  (load-file "CLOS/documentation-defgeneric.lisp" e4)
  (load-file "CLOS/setf-documentation-defgeneric.lisp" e4)
  (load-file "CLOS/class-finalized-p-defgeneric.lisp" e4)
  (load-file "CLOS/setf-class-finalized-p-defgeneric.lisp" e4)
  (load-file "CLOS/class-precedence-list-defgeneric.lisp" e4)
  (load-file "CLOS/precedence-list-defgeneric.lisp" e4)
  (load-file "CLOS/setf-precedence-list-defgeneric.lisp" e4)
  (load-file "CLOS/instance-size-defgeneric.lisp" e4)
  (load-file "CLOS/setf-instance-size-defgeneric.lisp" e4)
  (load-file "CLOS/class-direct-slots-defgeneric.lisp" e4)
  (load-file "CLOS/class-direct-superclasses-defgeneric.lisp" e4)
  (load-file "CLOS/class-default-initargs-defgeneric.lisp" e4)
  (load-file "CLOS/setf-class-default-initargs-defgeneric.lisp" e4)
  (load-file "CLOS/class-slots-defgeneric.lisp" e4)
  (load-file "CLOS/setf-class-slots-defgeneric.lisp" e4)
  (load-file "CLOS/class-prototype-defgeneric.lisp" e4)
  (load-file "CLOS/setf-class-prototype-defgeneric.lisp" e4)
  (load-file "CLOS/dependents-defgeneric.lisp" e4)
  (load-file "CLOS/setf-dependents-defgeneric.lisp" e4)
  (load-file "CLOS/generic-function-name-defgeneric.lisp" e4)
  (load-file "CLOS/generic-function-lambda-list-defgeneric.lisp" e4)
  (load-file "CLOS/generic-function-argument-precedence-order-defgeneric.lisp" e4)
  (load-file "CLOS/generic-function-declarations-defgeneric.lisp" e4)
  (load-file "CLOS/generic-function-method-class-defgeneric.lisp" e4)
  (load-file "CLOS/generic-function-method-combination-defgeneric.lisp" e4)
  (load-file "CLOS/generic-function-methods-defgeneric.lisp" e4)
  (load-file "CLOS/setf-generic-function-methods-defgeneric.lisp" e4)
  (load-file "CLOS/initial-methods-defgeneric.lisp" e4)
  (load-file "CLOS/setf-initial-methods-defgeneric.lisp" e4)
  (load-file "CLOS/call-history-defgeneric.lisp" e4)
  (load-file "CLOS/setf-call-history-defgeneric.lisp" e4)
  (load-file "CLOS/specializer-profile-defgeneric.lisp" e4)
  (load-file "CLOS/setf-specializer-profile-defgeneric.lisp" e4)
  (load-file "CLOS/method-function-defgeneric.lisp" e4)
  (load-file "CLOS/method-generic-function-defgeneric.lisp" e4)
  (load-file "CLOS/setf-method-generic-function-defgeneric.lisp" e4)
  (load-file "CLOS/method-lambda-list-defgeneric.lisp" e4)
  (load-file "CLOS/method-specializers-defgeneric.lisp" e4)
  (load-file "CLOS/method-qualifiers-defgeneric.lisp" e4)
  (load-file "CLOS/accessor-method-slot-definition-defgeneric.lisp" e4)
  (load-file "CLOS/setf-accessor-method-slot-definition-defgeneric.lisp" e4)
  (load-file "CLOS/slot-definition-name-defgeneric.lisp" e4)
  (load-file "CLOS/slot-definition-allocation-defgeneric.lisp" e4)
  (load-file "CLOS/slot-definition-type-defgeneric.lisp" e4)
  (load-file "CLOS/slot-definition-initargs-defgeneric.lisp" e4)
  (load-file "CLOS/slot-definition-initform-defgeneric.lisp" e4)
  (load-file "CLOS/slot-definition-initfunction-defgeneric.lisp" e4)
  (load-file "CLOS/slot-definition-storage-defgeneric.lisp" e4)
  (load-file "CLOS/slot-definition-readers-defgeneric.lisp" e4)
  (load-file "CLOS/slot-definition-writers-defgeneric.lisp" e4)
  (load-file "CLOS/slot-definition-location-defgeneric.lisp" e4)
  (load-file "CLOS/setf-slot-definition-location-defgeneric.lisp" e4)
  (load-file "CLOS/variant-signature-defgeneric.lisp" e4)
  (load-file "CLOS/template-defgeneric.lisp" e4)
  (load-file "CLOS/code-object-defgeneric.lisp" e4))

(defun define-accessor-generic-functions (boot)
  (with-accessors ((e2 sicl-new-boot:e2)
                   (e3 sicl-new-boot:e3)
                   (e4 sicl-new-boot:e4)) boot
    (ensure-generic-function-phase-3 boot)
    (enable-generic-function-initialization boot)
    (sicl-minimal-extrinsic-environment:import-function-from-host
     'sicl-clos:defgeneric-expander e4)
    (load-file "CLOS/defgeneric-defmacro.lisp" e4)
    (load-accessor-defgenerics e4)))