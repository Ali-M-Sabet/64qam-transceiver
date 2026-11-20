function [y_out, w_final, w_hist, e_hist, ranges] = lms_core(r_in, s_train_in, mu_in, N_eq, N_train, delay, T) %#codegen
% Complex LMS with training and decision-directed updates.

r_in = r_in(:);
s_train_in = s_train_in(:);
N_rx = numel(r_in);
N_tx = numel(s_train_in);

r_cast  = cast(r_in, 'like', T.r);
s_train = cast(s_train_in, 'like', T.s_train);
mu      = cast(mu_in, 'like', T.mu);

% Request the fifth output to measure the explicit register casts.
log_ranges = nargout > 4;
ranges = zeros(13, 7);
if log_ranges
    ranges(:, [1, 3]) = Inf;
    ranges(:, [2, 4]) = -Inf;
    ranges(1,:) = log_quantization(ranges(1,:), r_in, r_cast, T.r);
    ranges(2,:) = log_quantization(ranges(2,:), s_train_in, s_train, T.s_train);
    ranges(3,:) = log_quantization(ranges(3,:), mu_in, mu, T.mu);
end

if N_rx < N_tx + delay
    pad_len = N_tx + delay - N_rx;
    r = [r_cast; cast(zeros(pad_len, 1), 'like', T.r)];
    N_rx = length(r);
else
    r = r_cast;
end

w = cast(zeros(N_eq, 1), 'like', T.w);
x = cast(zeros(N_eq, 1), 'like', T.x);

y_raw  = cast(zeros(N_rx, 1), 'like', T.y_hat);
e_hist = zeros(N_rx, 1);
w_hist = zeros(N_eq, N_rx);

scale_factor = cast(sqrt(42), 'like', T.scale_factor);
inv_scale    = cast(1.0 / sqrt(42), 'like', T.inv_scale);
if log_ranges
    ranges(4,:) = log_quantization(ranges(4,:), sqrt(42), scale_factor, T.scale_factor);
    ranges(5,:) = log_quantization(ranges(5,:), 1/sqrt(42), inv_scale, T.inv_scale);
end

for n = 1:N_rx
    x(2:end) = x(1:end-1);
    x(1)     = cast(r(n), 'like', T.x);

    filter_sum = sum(conj(w) .* x);
    y_hat    = cast(filter_sum, 'like', T.y_hat);
    y_raw(n) = y_hat;
    if log_ranges
        ranges(6,:) = log_quantization(ranges(6,:), r(n), x(1), T.x);
        ranges(7,:) = log_quantization(ranges(7,:), filter_sum, y_hat, T.y_hat);
    end

    tx_idx = n - delay;

    if tx_idx >= 1 && tx_idx <= N_tx
        if tx_idx <= N_train
            d = cast(s_train(tx_idx), 'like', T.d);
            if log_ranges
                ranges(8,:) = log_quantization(ranges(8,:), s_train(tx_idx), d, T.d);
            end
        else
            y_real = real(y_hat) * scale_factor;
            y_imag = imag(y_hat) * scale_factor;

            I_clip = min(max(y_real, -7.0), 7.0);
            Q_clip = min(max(y_imag, -7.0), 7.0);

            I_dec = 2.0 * round((I_clip - 1.0) / 2.0) + 1.0;
            Q_dec = 2.0 * round((Q_clip - 1.0) / 2.0) + 1.0;

            d_real = I_dec * inv_scale;
            d_imag = Q_dec * inv_scale;
            decision = complex(d_real, d_imag);
            d = cast(decision, 'like', T.d);
            if log_ranges
                ranges(8,:) = log_quantization(ranges(8,:), decision, d, T.d);
            end
        end

        error_raw = d - y_hat;
        err      = cast(error_raw, 'like', T.err);
        err_conj = conj(err);

        gradient_raw = x .* err_conj;
        grad       = cast(gradient_raw, 'like', T.grad);
        update_raw = grad .* mu;
        update_vec = cast(update_raw, 'like', T.update_vec);
        weight_raw = w + update_vec;
        w_next     = cast(weight_raw, 'like', T.w_next);

        w = cast(w_next, 'like', T.w);
        if log_ranges
            ranges(9,:) = log_quantization(ranges(9,:), error_raw, err, T.err);
            ranges(10,:) = log_quantization(ranges(10,:), gradient_raw, grad, T.grad);
            ranges(11,:) = log_quantization(ranges(11,:), update_raw, update_vec, T.update_vec);
            ranges(12,:) = log_quantization(ranges(12,:), weight_raw, w_next, T.w_next);
            ranges(13,:) = log_quantization(ranges(13,:), w_next, w, T.w);
        end

        e_hist(n) = double(abs(err)^2);
    end

    w_hist(:, n) = double(w);
end

w_final = w;

y_out = align_and_trim(y_raw, N_tx, delay);
end
