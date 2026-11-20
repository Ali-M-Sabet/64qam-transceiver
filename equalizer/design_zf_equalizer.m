function [w_zf, H_conv] = design_zf_equalizer(h, N_eq, D)
% Find a finite least-squares inverse at the selected delay.

    h   = h(:);
    L   = length(h);
    L_c = N_eq + L - 1;

    H_conv = convmtx(h, N_eq);

    e_D = zeros(L_c, 1);
    e_D(D + 1) = 1.0;

    w_zf = H_conv \ e_D;
end
