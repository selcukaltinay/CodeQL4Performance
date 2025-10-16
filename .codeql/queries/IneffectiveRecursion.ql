/**
 * @name Memoization olmayan recursive method
 * @description Fibonacci gibi recursive algoritmalar cache olmadan exponential complexity'ye sahip
 * @kind problem
 * @problem.severity warning
 * @precision medium
 * @id java/ineffective-recursion
 * @tags performance
 *       algorithmic-complexity
 */

import java

/**
 * Method kendini çağırıyor mu? (recursive)
 */
predicate isRecursive(Method m) {
  exists(MethodAccess ma |
    ma.getEnclosingCallable() = m and
    ma.getMethod() = m
  )
}

/**
 * Method içinde caching/memoization var mı?
 */
predicate hasMemoization(Method m) {
  exists(MethodAccess ma |
    ma.getEnclosingCallable() = m and
    (
      // Map.get veya Map.containsKey çağrısı
      (ma.getMethod().hasName("get") or ma.getMethod().hasName("containsKey")) and
      ma.getQualifier().getType().(RefType).hasQualifiedName("java.util", "Map")
    )
  )
}

/**
 * Recursive call sayısı (multiple recursive call = exponential)
 */
int recursiveCallCount(Method m) {
  result = count(MethodAccess ma |
    ma.getEnclosingCallable() = m and
    ma.getMethod() = m
  )
}

/**
 * Tail recursion mu?
 */
predicate isTailRecursive(Method m) {
  exists(MethodAccess ma, ReturnStmt ret |
    ma.getEnclosingCallable() = m and
    ma.getMethod() = m and
    ret.getEnclosingCallable() = m and
    ret.getResult() = ma
  )
}

from Method m, int callCount
where
  isRecursive(m) and
  not hasMemoization(m) and
  callCount = recursiveCallCount(m) and
  callCount >= 2 and  // Multiple recursive calls = exponential
  not isTailRecursive(m)
select m,
  "PERFORMANS: Recursive method memoization kullanmıyor ve " + callCount + " recursive çağrı yapıyor. " +
  "Bu exponential time complexity (O(2^n)) anlamına gelir. " +
  "Memoization ekleyin veya iterative versiyona çevirin. " +
  (if callCount >= 2 then "İkili recursive çağrı tespit edildi (örn: fibonacci pattern)." else "")
