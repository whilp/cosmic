local record tl
  record Error
    filename: string
    y: number
    x: number
    msg: string
  end

  record Result
    ast: any
    syntax_errors: {Error}
    type_errors: {Error}
    warnings: {Error}
  end

  loader: function()
  init_env: function(boolean): any
  process_string: function(string, boolean, any, string): Result, string
  generate: function(any, {string:any}): string
end

return tl
