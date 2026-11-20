function r = add_awgn(s, EsN0_dB)
% Add complex noise for the given Es/N0.

    EsN0_lin = 10^(EsN0_dB / 10);

    sigma2 = 1 / EsN0_lin;

    sigma = sqrt(sigma2 / 2);

    noise = sigma * (randn(size(s)) + 1j * randn(size(s)));

    r = s + noise;
end
