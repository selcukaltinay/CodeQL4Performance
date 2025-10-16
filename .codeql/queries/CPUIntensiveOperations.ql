/**
 * @name CPU-intensive işlemler
 * @description Pahalı matematiksel, kriptografik veya serialization işlemleri
 * @kind problem
 * @problem.severity warning
 * @precision medium
 * @id java/cpu-intensive-operations
 * @tags performance
 *       efficiency
 *       cpu-usage
 */

import java

/**
 * Pahalı matematiksel işlemler
 */
predicate isExpensiveMathOperation(MethodAccess ma) {
  exists(Method m | m = ma.getMethod() |
    m.getDeclaringType().hasQualifiedName("java.lang", "Math") and
    (
      m.hasName("pow") or      // Exponentiation
      m.hasName("exp") or      // e^x
      m.hasName("log") or      // Logarithm
      m.hasName("sqrt") or     // Square root
      m.hasName("sin") or      // Trigonometric
      m.hasName("cos") or
      m.hasName("tan")
    )
  )
}

/**
 * Kriptografik işlemler
 */
predicate isCryptographicOperation(MethodAccess ma) {
  exists(RefType type | type = ma.getMethod().getDeclaringType() |
    type.hasQualifiedName("java.security", "MessageDigest") or
    type.hasQualifiedName("javax.crypto", "Cipher") or
    type.hasQualifiedName("java.security", "Signature") or
    type.hasQualifiedName("javax.crypto", "Mac")
  ) and
  (
    ma.getMethod().hasName("digest") or
    ma.getMethod().hasName("doFinal") or
    ma.getMethod().hasName("update") or
    ma.getMethod().hasName("sign") or
    ma.getMethod().hasName("verify")
  )
}

/**
 * Serialization/Deserialization
 */
predicate isSerializationOperation(MethodAccess ma) {
  (
    ma.getMethod().hasName("writeObject") and
    ma.getMethod().getDeclaringType().hasQualifiedName("java.io", "ObjectOutputStream")
  ) or
  (
    ma.getMethod().hasName("readObject") and
    ma.getMethod().getDeclaringType().hasQualifiedName("java.io", "ObjectInputStream")
  )
}

/**
 * XML/JSON parsing
 */
predicate isParsingOperation(Expr e) {
  // JSON parsing
  exists(ClassInstanceExpr cie |
    cie = e and
    (
      cie.getType().getName().matches("%Gson%") or
      cie.getType().getName().matches("%Jackson%") or
      cie.getType().getName().matches("%JsonParser%")
    )
  ) or
  // XML parsing
  exists(MethodAccess ma |
    ma = e and
    (
      ma.getMethod().getDeclaringType().getName().matches("%DocumentBuilder%") or
      ma.getMethod().getDeclaringType().getName().matches("%SAXParser%")
    ) and
    ma.getMethod().hasName("parse")
  )
}

/**
 * Sorting operations
 */
predicate isSortOperation(MethodAccess ma) {
  (
    ma.getMethod().hasName("sort") and
    (
      ma.getMethod().getDeclaringType().hasQualifiedName("java.util", "Collections") or
      ma.getMethod().getDeclaringType().hasQualifiedName("java.util", "Arrays")
    )
  ) or
  (
    ma.getMethod().hasName("sorted") // Stream.sorted()
  )
}

/**
 * Loop içinde mi?
 */
predicate isInLoop(Expr e) {
  exists(LoopStmt loop | e.getEnclosingStmt().getEnclosingStmt*() = loop)
}

/**
 * Nested loop depth
 */
int nestedLoopDepth(Expr e) {
  if not exists(LoopStmt loop | e.getEnclosingStmt().getEnclosingStmt*() = loop) then
    result = 0
  else
    result = count(LoopStmt loop | e.getEnclosingStmt().getEnclosingStmt*() = loop)
}

/**
 * Method içinde kaç kere çağrılıyor?
 */
int callCount(MethodAccess ma, Method container) {
  ma.getEnclosingCallable() = container and
  result = count(MethodAccess call |
    call.getEnclosingCallable() = container and
    call.getMethod() = ma.getMethod()
  )
}

from Expr cpuOp, string opType, string context, int loopDepth
where
  (
    (isExpensiveMathOperation(cpuOp) and opType = "Pahalı matematik işlemi (Math.pow/sin/cos)") or
    (isCryptographicOperation(cpuOp) and opType = "Kriptografik işlem (hashing/encryption)") or
    (isSerializationOperation(cpuOp) and opType = "Serialization/Deserialization") or
    (isParsingOperation(cpuOp) and opType = "XML/JSON parsing") or
    (isSortOperation(cpuOp) and opType = "Sorting operation")
  ) and
  loopDepth = nestedLoopDepth(cpuOp) and
  (
    (loopDepth >= 2 and context = loopDepth + " seviye nested loop içinde - ÇOK PAHALI!") or
    (loopDepth = 1 and context = "loop içinde - pahalı") or
    (not isInLoop(cpuOp) and context = "normal context")
  )
select cpuOp,
  "CPU-INTENSIVE: " + opType + ". Konum: " + context + ". " +
  (if loopDepth > 0 then "Loop dışına alın, cache'leyin veya batch processing kullanın. " else "") +
  (if isCryptographicOperation(cpuOp) then "Crypto işlemleri pahalıdır - async yapın. " else "") +
  (if isSerializationOperation(cpuOp) then "Serialization yerine JSON kullanın (10x hızlı). " else "")
