(import-macros {: thrice-if : setup!} :core.macros)

(thrice-if (< 1 3) (print "hello"))

(setup! "cmp")
