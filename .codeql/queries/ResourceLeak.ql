/**
 * @name Kapatılmayan kaynak (Resource Leak)
 * @description Dosya, stream veya connection gibi kaynaklar try-with-resources kullanılarak kapatılmalı
 * @kind problem
 * @problem.severity error
 * @precision high
 * @id java/resource-leak
 * @tags reliability
 *       performance
 *       resource-management
 */

import java

from LocalVariableDecl v, ClassInstanceExpr create, TryStmt try
where
  create.getType().(RefType).hasQualifiedName("java.io", _) and
  v.getAnInit() = create and
  not exists(TryStmt t |
    t.getAResourceDecl() = v or
    t.getBlock().getAStmt*().getAChildStmt*().(ExprStmt).getExpr().(MethodAccess).getMethod().hasName("close")
  )
select create, "Bu kaynak (stream/reader) kapatılmıyor. try-with-resources kullanın."
