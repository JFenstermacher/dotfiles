(let [(ok? {: setup}) (pcall require "flit")]
  (when ok?
    (setup {})))
