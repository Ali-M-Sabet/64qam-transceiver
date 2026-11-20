function [w_mmse, H_conv] = design_mmse_equalizer(h, N_eq, D, EsN0_dB)
% Design an MMSE filter for the given channel and noise level.

    h   = h(:);
    L   = length(h);
    L_c = N_eq + L - 1;

    sigma2 = 10^(-EsN0_dB / 10);

    H_conv = convmtx(h, N_eq);

    e_D = zeros(L_c, 1);
    e_D(D + 1) = 1.0;

    w_mmse = (H_conv' * H_conv + sigma2 * eye(N_eq)) \ (H_conv' * e_D);
end
