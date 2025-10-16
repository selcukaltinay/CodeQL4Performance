/**
 * @name Büyük memory allocation
 * @description Loop içinde veya sık çağrılan methodlarda büyük array/collection allocation
 * @kind problem
 * @problem.severity warning
 * @precision high
 * @id java/large-memory-allocation
 * @tags performance
 *       memory
 *       resource-management
 */

import java

/**
 * Array allocation boyutu
 */
int getArraySize(ArrayCreationExpr ace) {
  result = ace.getDimension(0).(CompileTimeConstantExpr).getIntValue()
}

/**
 * Büyük array mi? (10KB+)
 */
predicate isLargeArray(ArrayCreationExpr ace) {
  exists(int size | size = getArraySize(ace) |
    size >= 10000 or  // 10K+ elements
    // byte array için
    (ace.getType().(Array).getElementType().hasName("byte") and size >= 10240)
  )
}

/**
 * Loop içinde allocation
 */
predicate isInLoop(Expr e) {
  exists(LoopStmt loop | e.getEnclosingStmt().getEnclosingStmt*() = loop)
}

/**
 * Sık çağrılan method mu? (public API, getter, utility)
 */
predicate isHotMethod(Method m) {
  m.isPublic() or
  m.getName().matches("get%") or
  m.getName().matches("process%") or
  m.getName().matches("handle%")
}

/**
 * Collection initialization büyük capacity ile
 */
predicate isLargeCollectionInit(ClassInstanceExpr cie) {
  exists(int capacity |
    cie.getType().(RefType).hasQualifiedName("java.util", _) and
    capacity = cie.getArgument(0).(CompileTimeConstantExpr).getIntValue() and
    capacity >= 10000
  )
}

/**
 * Allocation edilip kullanılmayan
 */
predicate isUnusedAllocation(Expr e) {
  exists(LocalVariableDecl v |
    v.getAnInit() = e and
    not exists(VarAccess va | va.getVariable() = v and va != e)
  )
}

/**
 * ByteBuffer.allocateDirect - Off-heap memory
 */
predicate isDirectBufferAllocation(MethodAccess ma) {
  ma.getMethod().hasName("allocateDirect") and
  ma.getMethod().getDeclaringType().hasQualifiedName("java.nio", "ByteBuffer")
}

from Expr alloc, string allocType, int size, string location
where
  (
    // Büyük array
    (isLargeArray(alloc) and
     allocType = "Array allocation" and
     size = getArraySize(alloc))
    or
    // Büyük collection
    (isLargeCollectionInit(alloc) and
     allocType = "Collection initialization" and
     size = alloc.(ClassInstanceExpr).getArgument(0).(CompileTimeConstantExpr).getIntValue())
    or
    // Direct buffer
    (isDirectBufferAllocation(alloc) and
     allocType = "Direct ByteBuffer (off-heap)" and
     size = alloc.(MethodAccess).getArgument(0).(CompileTimeConstantExpr).getIntValue())
  ) and
  (
    (isInLoop(alloc) and location = "loop içinde - YÜKSEK MEMORY CHURN") or
    (isHotMethod(alloc.getEnclosingCallable()) and location = "sık çağrılan methodda") or
    location = "normal context"
  )
select alloc,
  "MEMORY: " + allocType + " - " + size + " element/byte. " +
  "Konum: " + location + ". " +
  (if isInLoop(alloc) then "Loop dışına alın veya object pool kullanın. " else "") +
  (if isUnusedAllocation(alloc) then "Allocation kullanılmıyor! " else "") +
  "Tahmini boyut: " + (size / 1024) + " KB"
