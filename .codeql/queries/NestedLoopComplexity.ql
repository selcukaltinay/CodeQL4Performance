/**
 * @name Yüksek karmaşıklıkta nested loop
 * @description 3 veya daha fazla iç içe loop O(n³) veya daha kötü complexity anlamına gelir
 * @kind problem
 * @problem.severity warning
 * @precision high
 * @id java/nested-loop-complexity
 * @tags performance
 *       algorithmic-complexity
 *       maintainability
 */

import java

/**
 * Bir loop'un içindeki maksimum nested depth'i hesaplar
 */
int nestedLoopDepth(LoopStmt loop) {
  if not exists(LoopStmt inner | inner.getEnclosingStmt+() = loop) then
    result = 1
  else
    result = 1 + max(LoopStmt inner | inner.getEnclosingStmt+() = loop | nestedLoopDepth(inner))
}

/**
 * Loop içinde collection veya array boyutu
 */
predicate hasLargeIterationSpace(LoopStmt loop) {
  exists(CompileTimeConstantExpr limit |
    limit.getIntValue() > 100 and
    (
      // for (i < 1000)
      limit.getEnclosingStmt().getEnclosingStmt*() = loop or
      // while (i < 1000)
      limit.getParent*() = loop.getCondition()
    )
  )
}

/**
 * Toplam iterasyon sayısını tahmin et (nested loop için)
 */
string estimateComplexity(int depth) {
  if depth = 1 then result = "O(n)"
  else if depth = 2 then result = "O(n²)"
  else if depth = 3 then result = "O(n³)"
  else if depth = 4 then result = "O(n⁴)"
  else result = "O(n^" + depth + ")"
}

/**
 * Loop içinde memory allocation var mı?
 */
predicate hasMemoryAllocationInLoop(LoopStmt loop) {
  exists(ClassInstanceExpr create |
    create.getEnclosingStmt().getEnclosingStmt*() = loop and
    (
      create.getType().hasName("ArrayList") or
      create.getType().hasName("HashMap") or
      create.getType().hasName("LinkedList") or
      create.getType() instanceof Array
    )
  )
}

from LoopStmt outerLoop, int depth
where
  depth = nestedLoopDepth(outerLoop) and
  depth >= 3 and
  // En dıştaki loop'u bul (parent loop yoksa)
  not exists(LoopStmt parent | outerLoop.getEnclosingStmt+() = parent)
select outerLoop,
  "PERFORMANS UYARISI: " + depth + " seviye iç içe loop tespit edildi. " +
  "Algoritma karmaşıklığı: " + estimateComplexity(depth) + ". " +
  (if hasLargeIterationSpace(outerLoop) then "Büyük iterasyon aralığı tespit edildi. " else "") +
  (if hasMemoryAllocationInLoop(outerLoop) then "Loop içinde memory allocation var!" else "") +
  " → Algoritma optimizasyonu gerekli."
