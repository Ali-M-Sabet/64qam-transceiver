function [r_isi_full, ch_delay] = apply_fir_channel(symbols_tx, h)
% Apply the normalized multipath FIR channel.

symbols_tx = symbols_tx(:);
h          = h(:);
h_norm     = h / norm(h);

r_isi_full = conv(symbols_tx, h_norm);

[~, max_idx] = max(abs(h));
ch_delay     = max_idx - 1;
end
