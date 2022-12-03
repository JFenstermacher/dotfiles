(local M {})

(fn M.setup! [name opts?]
  `#(let [mod# (require ,name)]
      (mod#.setup (or ,opts? {}))))

:return M
