/**
 * @name Loop içinde gereksiz boxing/unboxing
 * @description Loop içinde wrapper sınıflar kullanmak performans kaybına yol açar
 * @kind problem
 * @problem.severity warning
 * @precision medium
 * @id java/boxing-in-loop
 * @tags performance
 *       efficiency
 */

import java

from Assignment assign, BoxExpr box, LoopStmt loop
where
  assign.getRhs().getAChildExpr*() = box and
  assign.getEnclosingStmt().getEnclosingStmt*() = loop
select box, "Loop içinde boxing/unboxing işlemi performans kaybına yol açar. Primitive tip kullanın."
