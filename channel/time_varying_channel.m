function [r_tv, h_matrix] = time_varying_channel(symbols_tx, h1, h2, mode, switch_idx)
% Apply a step or drifting channel without resetting its memory.

    if nargin < 4 || isempty(mode)
        mode = 'step';
    end
    if nargin < 5 || isempty(switch_idx)
        switch_idx = floor(length(symbols_tx) / 2);
    end

    symbols_tx = symbols_tx(:);
    N_sym      = length(symbols_tx);

    L_h = max(length(h1), length(h2));
    h1_padded = zeros(L_h, 1); h1_padded(1:length(h1)) = h1(:);
    h2_padded = zeros(L_h, 1); h2_padded(1:length(h2)) = h2(:);

    h1_norm = h1_padded / norm(h1_padded);
    h2_norm = h2_padded / norm(h2_padded);

    h_matrix = zeros(L_h, N_sym);
    switch lower(mode)
        case 'step'
            for n = 1:N_sym
                if n <= switch_idx
                    h_matrix(:, n) = h1_norm;
                else
                    h_matrix(:, n) = h2_norm;
                end
            end

        case 'drift'
            alpha_vec = linspace(0, 1, N_sym);
            for n = 1:N_sym
                h_interp = (1 - alpha_vec(n)) * h1_norm + alpha_vec(n) * h2_norm;
                h_matrix(:, n) = h_interp / norm(h_interp); % Preserve unit energy
            end

        otherwise
            error('time_varying_channel: Unknown mode "%s". Use "step" or "drift".', mode);
    end

    r_tv = zeros(N_sym + L_h - 1, 1);
    fir_state = zeros(L_h, 1);

    for n = 1:N_sym
        fir_state = [symbols_tx(n); fir_state(1:L_h-1)];
        r_tv(n)   = sum(h_matrix(:, n) .* fir_state);
    end

    for n = (N_sym + 1):(N_sym + L_h - 1)
        fir_state = [0; fir_state(1:L_h-1)];
        r_tv(n)   = sum(h_matrix(:, end) .* fir_state);
    end
end
