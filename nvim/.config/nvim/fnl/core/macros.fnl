(local M {})

(fn M.setup! [name opts?]
  `#(let [(ok?# mod#) (pcall require ,name)]
      (when ok?#
        (mod#.setup (or ,opts? {})))))

:return M
