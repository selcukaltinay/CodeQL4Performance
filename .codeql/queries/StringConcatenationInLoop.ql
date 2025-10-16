/**
 * @name Loop içinde String birleştirme
 * @description Loop içinde '+' operatörü ile string birleştirme performans sorununa yol açar
 * @kind problem
 * @problem.severity warning
 * @precision high
 * @id java/string-concatenation-in-loop
 * @tags performance
 *       maintainability
 */

import java

from Assignment assign, AddExpr add, LoopStmt loop, Variable v
where
  assign.getDestVar() = v and
  assign.getRhs() = add and
  add.getAnOperand().getType() instanceof TypeString and
  add.getAnOperand().(VarAccess).getVariable() = v and
  assign.getEnclosingStmt().getEnclosingStmt*() = loop
select assign, "Loop içinde string birleştirme yerine StringBuilder kullanın. Değişken: " + v.getName()
