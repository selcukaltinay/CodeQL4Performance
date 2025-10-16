/**
 * @name Ağır işlem içeren Runnable tespit
 * @description Runnable içinde nested loop, I/O veya blocking işlemler performans sorununa yol açar
 * @kind problem
 * @problem.severity warning
 * @precision medium
 * @id java/heavy-runnable
 * @tags performance
 *       threading
 *       scalability
 */

import java

/**
 * Nested loop sayısını hesaplar
 */
int getNestedLoopDepth(Stmt s) {
  if s instanceof LoopStmt then
    result = 1 + max(Stmt child | child = s.getAChild() | getNestedLoopDepth(child))
  else
    result = max(Stmt child | child = s.getAChild() | getNestedLoopDepth(child))
}

/**
 * Bir methodun içindeki nested loop depth'ini bulur
 */
predicate hasDeepNestedLoops(Method m, int depth) {
  depth = max(Stmt s | s.getEnclosingCallable() = m | getNestedLoopDepth(s)) and
  depth >= 3
}

/**
 * Runnable içinde I/O işlemi var mı?
 */
predicate hasIOOperation(Method m) {
  exists(MethodAccess ma |
    ma.getEnclosingCallable() = m and
    (
      ma.getMethod().getDeclaringType().hasQualifiedName("java.io", _) or
      ma.getMethod().getDeclaringType().hasQualifiedName("java.nio", _) or
      ma.getMethod().getName().matches("%read%") or
      ma.getMethod().getName().matches("%write%")
    )
  )
}

/**
 * Runnable içinde sleep veya wait var mı?
 */
predicate hasBlockingOperation(Method m) {
  exists(MethodAccess ma |
    ma.getEnclosingCallable() = m and
    (
      ma.getMethod().hasName("sleep") or
      ma.getMethod().hasName("wait") or
      ma.getMethod().hasName("join")
    )
  )
}

/**
 * Runnable içinde loop var ve loop içinde method call var
 */
predicate hasLoopWithMethodCalls(Method m) {
  exists(LoopStmt loop, MethodAccess ma |
    loop.getEnclosingCallable() = m and
    ma.getEnclosingStmt().getEnclosingStmt*() = loop and
    // I/O, sleep gibi ağır işlemler
    (
      ma.getMethod().getName().matches("%query%") or
      ma.getMethod().getName().matches("%execute%") or
      ma.getMethod().getName().matches("%read%") or
      ma.getMethod().getName().matches("%write%") or
      ma.getMethod().getName().matches("%sleep%")
    )
  )
}

from Method runMethod, TypeRunnable runnableType, int depth
where
  runMethod.getName() = "run" and
  runMethod.getDeclaringType().getASupertype*() = runnableType and
  (
    hasDeepNestedLoops(runMethod, depth) or
    hasIOOperation(runMethod) or
    hasBlockingOperation(runMethod) or
    hasLoopWithMethodCalls(runMethod)
  )
select runMethod,
  "Bu Runnable ağır işlem içeriyor: " +
  (if hasDeepNestedLoops(runMethod, depth) then "nested loops (depth=" + depth + ")" else "") +
  (if hasIOOperation(runMethod) then ", I/O işlemleri" else "") +
  (if hasBlockingOperation(runMethod) then ", blocking işlemler" else "") +
  (if hasLoopWithMethodCalls(runMethod) then ", loop içinde method çağrıları" else "")
