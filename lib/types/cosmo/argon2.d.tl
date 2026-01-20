-- type declarations for cosmo.argon2

local record argon2
  hash_encoded: function(pass: string, salt: string, config: Config): string
  verify: function(encoded: string, pass: string): boolean
end

return argon2

