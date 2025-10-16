/**
 * @name Memory leak tespiti
 * @description Collection'lara ekleme yapılıp temizlenmeyen durumlar memory leak'e yol açar
 * @kind problem
 * @problem.severity error
 * @precision high
 * @id java/memory-leak-collection
 * @tags reliability
 *       performance
 *       memory
 */

import java

/**
 * Static veya instance field collection
 */
predicate isFieldCollection(Field f) {
  f.getType().(RefType).hasQualifiedName("java.util", "List") or
  f.getType().(RefType).hasQualifiedName("java.util", "Map") or
  f.getType().(RefType).hasQualifiedName("java.util", "Set") or
  f.getType().(RefType).hasQualifiedName("java.util", "Queue")
}

/**
 * Collection'a add/put yapılıyor
 */
predicate hasAddOperation(Field f, Method m) {
  exists(MethodAccess ma |
    ma.getEnclosingCallable() = m and
    ma.getQualifier().(FieldAccess).getField() = f and
    (
      ma.getMethod().hasName("add") or
      ma.getMethod().hasName("put") or
      ma.getMethod().hasName("offer") or
      ma.getMethod().hasName("push")
    )
  )
}

/**
 * Collection hiç temizlenmiyor (clear, remove yok)
 */
predicate neverCleared(Field f) {
  not exists(MethodAccess ma, Method m |
    ma.getEnclosingCallable() = m and
    ma.getQualifier().(FieldAccess).getField() = f and
    (
      ma.getMethod().hasName("clear") or
      ma.getMethod().hasName("remove") or
      ma.getMethod().hasName("poll")
    )
  )
}

/**
 * Unbounded growth - loop içinde ekleme
 */
predicate hasUnboundedGrowth(Field f) {
  exists(MethodAccess ma, LoopStmt loop |
    ma.getQualifier().(FieldAccess).getField() = f and
    ma.getEnclosingStmt().getEnclosingStmt*() = loop and
    (ma.getMethod().hasName("add") or ma.getMethod().hasName("put"))
  )
}

from Field f, Method m, string issue
where
  isFieldCollection(f) and
  hasAddOperation(f, m) and
  neverCleared(f) and
  (
    (f.isStatic() and issue = "STATIC collection - Application-wide memory leak!") or
    (not f.isStatic() and issue = "Instance collection - Per-object memory leak")
  )
select f,
  "MEMORY LEAK: " + issue + " Collection '" + f.getName() +
  "' sürekli büyüyor ama hiç temizlenmiyor. " +
  (if hasUnboundedGrowth(f) then "Loop içinde ekleme yapılıyor! " else "") +
  "clear() veya size limit ekleyin."
