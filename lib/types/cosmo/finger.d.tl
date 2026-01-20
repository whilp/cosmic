-- type declarations for cosmo.finger

local record finger
  FingerSyn: function(syn_packet_bytes: string): number
  GetSynFingerOs: function(synfinger: number): "LINUX"
  DescribeSyn: function(syn_packet_bytes: string): string
end

return finger

