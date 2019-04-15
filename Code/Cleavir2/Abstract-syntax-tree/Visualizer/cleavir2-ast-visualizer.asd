(cl:in-package #:asdf-user)

(defsystem #:cleavir2-ast-visualizer
  :depends-on (#:cleavir-ast
               #:mcclim
               #:clouseau)
  :serial t
  :components
  ((:file "packages")
   (:file "profiles")
   (:file "layout")
   (:file "gui")))
