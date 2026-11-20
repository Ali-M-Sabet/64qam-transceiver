function [y_eq, w_final, w_hist, e_hist] = nlms_equalizer(r, d_train, M, N_eq, mu_norm, N_train, delay, eps_reg)
% 64-QAM LMS with input-energy normalization.

    assert(M == 64, 'nlms_equalizer supports 64-QAM.');

    if nargin < 7 || isempty(delay)
        delay = floor((N_eq - 1) / 2);
    end
    if nargin < 8 || isempty(eps_reg)
        eps_reg = 1e-6;
    end

    r       = r(:);
    d_train = d_train(:);
    N_rx    = length(r);
    N_tx    = length(d_train);

    if N_rx < N_tx + delay
        pad_len = N_tx + delay - N_rx;
        r_buf = [r; zeros(pad_len, 1)];
        N_rx = length(r_buf);
    else
        r_buf = r;
    end

    w      = zeros(N_eq, 1);
    x      = zeros(N_eq, 1);
    y_raw  = zeros(N_rx, 1);
    w_hist = zeros(N_eq, N_rx);
    e_hist = zeros(N_rx, 1);

    scale_factor = sqrt(42);
    inv_scale    = 1.0 / sqrt(42);

    for n = 1:N_rx
        x = [r_buf(n); x(1:N_eq-1)];

        y_hat    = sum(conj(w) .* x);
        y_raw(n) = y_hat;

        tx_idx = n - delay;

        if tx_idx >= 1 && tx_idx <= N_tx
            if tx_idx <= N_train
                d = d_train(tx_idx);
            else
                y_real = real(y_hat) * scale_factor;
                y_imag = imag(y_hat) * scale_factor;

                I_clip = min(max(y_real, -7.0), 7.0);
                Q_clip = min(max(y_imag, -7.0), 7.0);

                I_dec = 2.0 * round((I_clip - 1.0) / 2.0) + 1.0;
                Q_dec = 2.0 * round((Q_clip - 1.0) / 2.0) + 1.0;

                d = complex(I_dec * inv_scale, Q_dec * inv_scale);
            end

            err = d - y_hat;

            x_energy = sum(abs(x).^2);
            mu_eff   = mu_norm / (eps_reg + x_energy);

            w = w + mu_eff * x * conj(err);

            e_hist(n) = abs(err)^2;
        end

        w_hist(:, n) = w;
    end

    w_final = w;

    y_eq = align_and_trim(y_raw, N_tx, delay);
end
