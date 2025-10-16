/**
 * @name ThreadLocal memory leak
 * @description ThreadLocal.remove() çağrılmaz thread pool'larda memory leak olur
 * @kind problem
 * @problem.severity error
 * @precision high
 * @id java/threadlocal-not-removed
 * @tags reliability
 *       performance
 *       memory
 *       threading
 */

import java

/**
 * ThreadLocal field
 */
predicate isThreadLocalField(Field f) {
  f.getType().(RefType).hasQualifiedName("java.lang", "ThreadLocal")
}

/**
 * ThreadLocal.get() çağrısı
 */
predicate hasThreadLocalGet(Field f, Method m) {
  exists(MethodAccess ma |
    ma.getEnclosingCallable() = m and
    ma.getQualifier().(FieldAccess).getField() = f and
    ma.getMethod().hasName("get")
  )
}

/**
 * ThreadLocal.remove() çağrısı
 */
predicate hasThreadLocalRemove(Field f) {
  exists(MethodAccess ma |
    ma.getQualifier().(FieldAccess).getField() = f and
    ma.getMethod().hasName("remove")
  )
}

/**
 * ThreadLocal büyük nesne tutuyor mu?
 */
predicate holdsLargeObject(Field f) {
  exists(MethodAccess ma, ArrayCreationExpr ace |
    ma.getQualifier().(FieldAccess).getField() = f and
    ma.getMethod().hasName("withInitial") and
    ace.getParent*() = ma.getArgument(0) and
    (
      // Büyük array
      ace.getDimension(0).(CompileTimeConstantExpr).getIntValue() > 10000 or
      // ByteBuffer gibi off-heap
      exists(MethodAccess allocate |
        allocate.getParent*() = ma.getArgument(0) and
        allocate.getMethod().hasName("allocateDirect")
      )
    )
  )
}

/**
 * Static ThreadLocal mi? (Daha riskli)
 */
predicate isStaticThreadLocal(Field f) {
  isThreadLocalField(f) and f.isStatic()
}

/**
 * Try-finally içinde remove var mı?
 */
predicate hasProperCleanup(Field f, Method m) {
  exists(TryStmt try, MethodAccess ma |
    hasThreadLocalGet(f, m) and
    ma.getQualifier().(FieldAccess).getField() = f and
    ma.getMethod().hasName("remove") and
    ma.getEnclosingStmt().getEnclosingStmt*() = try.getFinally()
  )
}

from Field f, Method m, string riskLevel
where
  isThreadLocalField(f) and
  hasThreadLocalGet(f, m) and
  not hasThreadLocalRemove(f) and
  not hasProperCleanup(f, m) and
  (
    (isStaticThreadLocal(f) and holdsLargeObject(f) and
     riskLevel = "KRITIK - Static ThreadLocal + büyük object") or
    (isStaticThreadLocal(f) and
     riskLevel = "YÜKSEK - Static ThreadLocal") or
    (holdsLargeObject(f) and
     riskLevel = "YÜKSEK - Büyük object tutuyor") or
    riskLevel = "ORTA - ThreadLocal leak riski"
  )
select f,
  "MEMORY LEAK (" + riskLevel + "): ThreadLocal '" + f.getName() +
  "' kullanılıyor ama remove() çağrılmıyor. " +
  "Thread pool ortamında her thread için memory leak olur. " +
  (if holdsLargeObject(f) then "Büyük object tutuluyor - leak büyük! " else "") +
  "Method '" + m.getName() + "' sonunda try-finally bloğunda remove() çağrın."
