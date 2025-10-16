/**
 * @name Synchronized blok içinde ağır işlem
 * @description Lock tutarken ağır işlem yapmak thread contention'a yol açar
 * @kind problem
 * @problem.severity warning
 * @precision high
 * @id java/synchronized-heavy-operation
 * @tags performance
 *       threading
 *       concurrency
 */

import java

/**
 * Synchronized method veya block
 */
predicate isSynchronized(Callable c) {
  c.(Method).isSynchronized() or
  exists(SynchronizedStmt sync |
    sync.getEnclosingCallable() = c
  )
}

/**
 * Method içinde blocking call var mı?
 */
predicate hasBlockingCall(Callable c) {
  exists(MethodAccess ma |
    ma.getEnclosingCallable() = c and
    (
      ma.getMethod().hasName("sleep") or
      ma.getMethod().hasName("wait") or
      ma.getMethod().hasName("join") or
      // I/O
      ma.getMethod().getDeclaringType().hasQualifiedName("java.io", _) or
      // Network
      ma.getMethod().getDeclaringType().hasQualifiedName("java.net", _) or
      // Database
      ma.getMethod().hasName("executeQuery") or
      ma.getMethod().hasName("executeUpdate")
    )
  )
}

/**
 * Method içinde loop var mı?
 */
predicate hasLoop(Callable c) {
  exists(LoopStmt loop |
    loop.getEnclosingCallable() = c
  )
}

/**
 * Synchronized block içinde ne kadar işlem var?
 */
int estimateOperationCount(SynchronizedStmt sync) {
  result = count(Stmt s | s.getEnclosingStmt+() = sync)
}

from Callable c, string issue
where
  isSynchronized(c) and
  (
    (hasBlockingCall(c) and issue = "blocking I/O veya sleep çağrısı") or
    (hasLoop(c) and issue = "loop içeren işlem")
  )
select c,
  "PERFORMANS UYARISI: Synchronized method/block içinde " + issue + " var. " +
  "Lock süresi minimize edilmeli. İşlemi lock dışına alın veya finer-grained locking kullanın."
