/**
 * @name Collection boyut optimizasyonu eksik
 * @description HashMap/ArrayList başlangıç kapasitesi verilmeden büyük veri yüklenirse performans kaybı
 * @kind problem
 * @problem.severity warning
 * @precision high
 * @id java/collection-size-not-specified
 * @tags performance
 *       memory
 *       efficiency
 */

import java

/**
 * Collection constructor çağrısı
 */
predicate isCollectionCreation(ClassInstanceExpr cie) {
  exists(RefType type | type = cie.getType() |
    type.hasQualifiedName("java.util", "ArrayList") or
    type.hasQualifiedName("java.util", "HashMap") or
    type.hasQualifiedName("java.util", "HashSet") or
    type.hasQualifiedName("java.util", "LinkedList") or
    type.hasQualifiedName("java.util", "Vector")
  )
}

/**
 * Capacity argümanı verilmiş mi?
 */
predicate hasCapacityArgument(ClassInstanceExpr cie) {
  cie.getNumArgument() > 0
}

/**
 * Loop içinde çok sayıda add/put
 */
predicate hasLoopWithManyAdds(LocalVariableDeclExpr decl) {
  exists(LoopStmt loop, MethodAccess ma, Variable v |
    v = decl.getVariable() and
    ma.getQualifier().(VarAccess).getVariable() = v and
    ma.getEnclosingStmt().getEnclosingStmt*() = loop and
    (ma.getMethod().hasName("add") or ma.getMethod().hasName("put")) and
    // Loop iteration sayısı tahmin edilebilir mi?
    exists(CompileTimeConstantExpr limit |
      limit.getIntValue() > 100 and
      limit.getEnclosingStmt().getEnclosingStmt*() = loop
    )
  )
}

/**
 * StringBuilder capacity belirtilmemiş ama büyük kullanım
 */
predicate isStringBuilderWithoutCapacity(ClassInstanceExpr cie) {
  cie.getType().(RefType).hasQualifiedName("java.lang", "StringBuilder") and
  not hasCapacityArgument(cie) and
  exists(LoopStmt loop, MethodAccess ma, Variable v |
    v.getAnAccess() = cie and
    ma.getQualifier().(VarAccess).getVariable() = v and
    ma.getMethod().hasName("append") and
    ma.getEnclosingStmt().getEnclosingStmt*() = loop
  )
}

/**
 * ThreadLocal buffer without size
 */
predicate isThreadLocalWithoutSize(ClassInstanceExpr cie) {
  cie.getType().(RefType).hasQualifiedName("java.lang", "ThreadLocal") and
  exists(MethodAccess ma |
    ma = cie and
    ma.getMethod().hasName("withInitial") and
    exists(ArrayCreationExpr ace |
      ace.getParent*() = ma.getArgument(0) and
      ace.getType().(Array).getElementType().hasName("byte")
    )
  )
}

from Expr creation, string collectionType, string issue
where
  (
    // Collection without capacity
    isCollectionCreation(creation) and
    not hasCapacityArgument(creation) and
    exists(LocalVariableDeclExpr decl |
      decl.getInit() = creation and
      hasLoopWithManyAdds(decl)
    ) and
    collectionType = creation.(ClassInstanceExpr).getType().getName() and
    issue = "Büyük loop içinde kullanılıyor ama initial capacity yok"
  ) or
  (
    // StringBuilder without capacity
    isStringBuilderWithoutCapacity(creation) and
    collectionType = "StringBuilder" and
    issue = "Loop içinde append ama capacity belirtilmemiş - sürekli resize"
  )
select creation,
  "PERFORMANS: " + collectionType + " " + issue + ". " +
  "Default capacity (16) sürekli resize edilecek - memory churn ve CPU waste. " +
  "Tahmini boyut: new " + collectionType + "(expectedSize) kullanın. " +
  "Kazanç: 2-5x daha az memory allocation."
