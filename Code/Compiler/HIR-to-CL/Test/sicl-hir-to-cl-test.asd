(cl:in-package #:asdf-user)

(defsystem #:sicl-hir-to-cl-test
  :depends-on (#:sicl-alternative-extrinsic-environment
               #:concrete-syntax-tree
               #:cleavir2-ast
               #:cleavir2-cst-to-ast
               #:cleavir-primop
               #:sicl-hir-to-cl)
  :components
  ((:file "packages")
   (:file "eval")
   (:file "test")))
