function y_full = apply_fir_equalizer(r, w)
% Filter the received samples with fixed equalizer taps.

    r = r(:);
    w = w(:);

    y_full = conv(r, w);
end
