(cl:in-package #:sicl-hir-to-mir)

(defun find-slot (object-location slot-number slot-address successors)
  (let ((rack-address (make-instance 'cleavir-ir:lexical-location
                        :name '#:rack-address)))
    (make-instance 'cleavir-ir:memref2-instruction
      :offset 3
      :inputs (list object-location)
      :outputs (list rack-address)
      :successors
      (list (make-instance 'cleavir-ir:unsigned-add-instruction
              :inputs (list rack-address slot-number)
              :outputs (list slot-address)
              :successors successors)))))

(defmethod translate ((client sicl-client:sicl-x86-64)
                      (instruction cleavir-ir:slot-read-instruction))
  (let ((slot-address (make-instance 'cleavir-ir:lexical-location
                        :name '#:slot-address)))
    (destructuring-bind (object-location slot-number)
        (cleavir-ir:inputs instruction)
      (find-slot
       object-location slot-number slot-address
       (list (make-instance 'cleavir-ir:memref2-instruction
               :offset -7
               :inputs (list slot-address)
               :outputs (cleavir-ir:outputs instruction)
               :successors (cleavir-ir:successors instruction)))))))

(defmethod translate ((client sicl-client:sicl-x86-64)
                      (instruction cleavir-ir:slot-write-instruction))
  (let ((slot-address (make-instance 'cleavir-ir:lexical-location
                        :name '#:slot-address)))
    (destructuring-bind (object-location slot-number value-location)
        (cleavir-ir:inputs instruction)
      (find-slot
       object-location slot-number slot-address
       (list (make-instance 'cleavir-ir:memset2-instruction
               :offset -7
               :inputs (list slot-address value-location)
               :successors (cleavir-ir:successors instruction)))))))
