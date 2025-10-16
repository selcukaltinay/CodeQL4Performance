/**
 * @name Loop içinde pahalı işlemler
 * @description Reflection, regex compilation, I/O gibi pahalı işlemler loop dışına alınmalı
 * @kind problem
 * @problem.severity warning
 * @precision high
 * @id java/expensive-operation-in-loop
 * @tags performance
 *       efficiency
 */

import java

/**
 * Reflection kullanımı - Çok yavaş
 */
predicate isReflectionCall(MethodAccess ma) {
  ma.getMethod().getDeclaringType().hasQualifiedName("java.lang.reflect", _) or
  ma.getMethod().hasName("getClass") or
  ma.getMethod().hasName("getMethod") or
  ma.getMethod().hasName("getDeclaredMethod") or
  ma.getMethod().hasName("getField") or
  ma.getMethod().hasName("invoke")
}

/**
 * Regex compilation - Pattern.compile veya String.matches
 */
predicate isRegexCompilation(MethodAccess ma) {
  (
    ma.getMethod().hasName("compile") and
    ma.getMethod().getDeclaringType().hasQualifiedName("java.util.regex", "Pattern")
  ) or
  (
    ma.getMethod().hasName("matches") and
    ma.getQualifier().getType() instanceof TypeString
  ) or
  ma.getMethod().hasName("replaceAll") or
  ma.getMethod().hasName("replaceFirst") or
  ma.getMethod().hasName("split")
}

/**
 * I/O işlemi
 */
predicate isIOOperation(MethodAccess ma) {
  exists(RefType type | type = ma.getMethod().getDeclaringType() |
    type.hasQualifiedName("java.io", _) or
    type.hasQualifiedName("java.nio", _)
  ) and
  (
    ma.getMethod().getName().matches("%read%") or
    ma.getMethod().getName().matches("%write%") or
    ma.getMethod().getName().matches("%open%") or
    ma.getMethod().getName().matches("%close%")
  )
}

/**
 * Veritabanı sorgusu
 */
predicate isDatabaseQuery(MethodAccess ma) {
  ma.getMethod().hasName("executeQuery") or
  ma.getMethod().hasName("executeUpdate") or
  ma.getMethod().hasName("execute") or
  (
    ma.getMethod().hasName("query") and
    exists(RefType type | type = ma.getMethod().getDeclaringType() |
      type.getName().matches("%Repository%") or
      type.getName().matches("%Dao%") or
      type.getName().matches("%Service%")
    )
  )
}

/**
 * Thread oluşturma - Pahalı işlem
 */
predicate isThreadCreation(Expr e) {
  exists(ClassInstanceExpr cie |
    cie = e and
    cie.getType().hasName("Thread")
  )
}

/**
 * Synchronization - Lock alma
 */
predicate hasSynchronization(Stmt s) {
  s instanceof SynchronizedStmt or
  exists(MethodAccess ma |
    ma.getEnclosingStmt() = s and
    (
      ma.getMethod().hasName("lock") or
      ma.getMethod().hasName("tryLock")
    )
  )
}

/**
 * Collection üzerinde expensive işlem
 */
predicate isExpensiveCollectionOperation(MethodAccess ma) {
  (
    // contains on List - O(n)
    ma.getMethod().hasName("contains") and
    ma.getQualifier().getType().(RefType).hasQualifiedName("java.util", "List")
  ) or
  (
    // remove on ArrayList from middle - O(n)
    ma.getMethod().hasName("remove") and
    ma.getQualifier().getType().(RefType).hasQualifiedName("java.util", "ArrayList")
  ) or
  (
    // LinkedList.get(i) - O(n)
    ma.getMethod().hasName("get") and
    ma.getQualifier().getType().(RefType).hasQualifiedName("java.util", "LinkedList")
  )
}

string getOperationType(Expr e) {
  if isReflectionCall(e) then result = "Reflection"
  else if isRegexCompilation(e) then result = "Regex compilation"
  else if isIOOperation(e) then result = "I/O işlemi"
  else if isDatabaseQuery(e) then result = "Veritabanı sorgusu"
  else if isThreadCreation(e) then result = "Thread oluşturma"
  else if isExpensiveCollectionOperation(e) then result = "Pahalı collection işlemi"
  else result = "Pahalı işlem"
}

from LoopStmt loop, Expr expensiveOp, string opType
where
  expensiveOp.getEnclosingStmt().getEnclosingStmt*() = loop and
  opType = getOperationType(expensiveOp) and
  (
    isReflectionCall(expensiveOp) or
    isRegexCompilation(expensiveOp) or
    isIOOperation(expensiveOp) or
    isDatabaseQuery(expensiveOp) or
    isThreadCreation(expensiveOp) or
    isExpensiveCollectionOperation(expensiveOp)
  )
select expensiveOp,
  "PERFORMANS: Loop içinde " + opType + " tespit edildi. " +
  "Bu işlem loop dışına alınmalı veya cache'lenmelidir."
