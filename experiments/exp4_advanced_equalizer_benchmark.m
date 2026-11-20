% Equalizer comparison, amplitude-step stress, and coefficient leakage.
clear; close all;
run(fullfile(fileparts(mfilename('fullpath')), '..', 'config.m'));

fprintf('Experiment 4: Equalizer stress and leakage\n');

N_eq   = LMS_N_EQ;    % 9 taps
delay  = LMS_DELAY;   % 4 samples
N_tr   = LMS_N_TRAIN;  % 300 pilots
mu_lms = LMS_MU;      % 0.0200
mu_nlms = NLMS_MU;

snr_vec   = 10:2:24;
N_snr     = length(snr_vec);
N_sym_ber = 25000;
N_bits_ber = N_sym_ber * k;
pay_range  = (N_tr + 1) : N_sym_ber;

ber_zf   = zeros(N_snr, 1);
ber_mmse = zeros(N_snr, 1);
ber_lms  = zeros(N_snr, 1);
ber_nlms = zeros(N_snr, 1);

rng(RNG_SEED, 'twister');
bits_all = generate_bits(N_bits_ber, RNG_SEED);
[syms_all, ~] = qam_mapper(bits_all, M);
r_ch_all = apply_fir_channel(syms_all, H_ISI);
bits_tx_pay = bits_all(N_tr*k + 1 : N_sym_ber*k);

w_zf_fixed = design_zf_equalizer(H_ISI, N_eq, delay);
T_dbl = lms_types('double');

for s = 1:N_snr
    snr_val = snr_vec(s);
    esn0_val = snr_val + 10*log10(k);
    r_noisy = add_awgn(r_ch_all, esn0_val);

    y_zf_raw = apply_fir_equalizer(r_noisy, w_zf_fixed);
    y_zf = align_and_trim(y_zf_raw, N_sym_ber, delay);
    bits_rx_zf = qam_demapper(y_zf(pay_range), M);
    [ber_zf(s), ~] = compute_ber_ser(bits_tx_pay, bits_rx_zf, k);

    w_mmse_fixed = design_mmse_equalizer(H_ISI, N_eq, delay, esn0_val);
    y_mmse_raw = apply_fir_equalizer(r_noisy, w_mmse_fixed);
    y_mmse = align_and_trim(y_mmse_raw, N_sym_ber, delay);
    bits_rx_mmse = qam_demapper(y_mmse(pay_range), M);
    [ber_mmse(s), ~] = compute_ber_ser(bits_tx_pay, bits_rx_mmse, k);

    [y_lms, ~, ~, ~] = lms_core(r_noisy, syms_all, mu_lms, N_eq, N_tr, delay, T_dbl);
    bits_rx_lms = qam_demapper(y_lms(pay_range), M);
    [ber_lms(s), ~] = compute_ber_ser(bits_tx_pay, bits_rx_lms, k);

    [y_nlms, ~, ~, ~] = nlms_equalizer(r_noisy, syms_all, M, N_eq, mu_nlms, N_tr, delay, NLMS_EPS);
    bits_rx_nlms = qam_demapper(y_nlms(pay_range), M);
    [ber_nlms(s), ~] = compute_ber_ser(bits_tx_pay, bits_rx_nlms, k);

end

%% 2. Dynamic Power Surge Test at 22 dB

N_sym_dyn = 4000;
N_bits_dyn = N_sym_dyn * k;
rng(RNG_SEED + 55, 'twister');
bits_dyn = generate_bits(N_bits_dyn, RNG_SEED + 55);
[syms_dyn, ~] = qam_mapper(bits_dyn, M);
r_ch_dyn = apply_fir_channel(syms_dyn, H_ISI);
r_noisy_dyn = add_awgn(r_ch_dyn, 22 + 10*log10(k));

[y_lms_stat, ~, ~, e_lms_stat] = lms_core(r_noisy_dyn, syms_dyn, mu_lms, N_eq, N_tr, delay, T_dbl);
[y_nlms_stat, ~, ~, e_nlms_stat] = nlms_equalizer(r_noisy_dyn, syms_dyn, M, N_eq, mu_nlms, N_tr, delay, NLMS_EPS);

alpha_smooth = 0.99;
mse_lms_stat = filter(1 - alpha_smooth, [1, -alpha_smooth], e_lms_stat);
mse_nlms_stat = filter(1 - alpha_smooth, [1, -alpha_smooth], e_nlms_stat);

evm_zf   = compute_evm(syms_all(pay_range), y_zf(pay_range));
evm_mmse = compute_evm(syms_all(pay_range), y_mmse(pay_range));
evm_lms  = compute_evm(syms_dyn(N_tr+1:N_sym_dyn), y_lms_stat(N_tr+1:N_sym_dyn));
evm_nlms = compute_evm(syms_dyn(N_tr+1:N_sym_dyn), y_nlms_stat(N_tr+1:N_sym_dyn));

surge_idx = 2000;
surge_db = 12;
surge_gain = 10^(surge_db/20);
r_surge = r_noisy_dyn;
r_surge(surge_idx:end) = r_surge(surge_idx:end) * surge_gain;
syms_surge = syms_dyn;
syms_surge(surge_idx:end) = syms_surge(surge_idx:end) * surge_gain;

[~, ~, ~, e_lms_surge] = lms_core(r_surge, syms_surge, mu_lms, N_eq, N_tr, delay, T_dbl);
[~, ~, ~, e_nlms_surge] = nlms_equalizer(r_surge, syms_surge, M, N_eq, mu_nlms, N_tr, delay, NLMS_EPS);

mse_lms_surge = filter(1 - alpha_smooth, [1, -alpha_smooth], e_lms_surge);
mse_nlms_surge = filter(1 - alpha_smooth, [1, -alpha_smooth], e_nlms_surge);

%% 3. Tap Weight Drift & Bounding Study

N_sym_long = 15000;
N_bits_long = N_sym_long * k;
rng(RNG_SEED + 77, 'twister');
bits_long = generate_bits(N_bits_long, RNG_SEED + 77);
[syms_long, ~] = qam_mapper(bits_long, M);
r_ch_long = apply_fir_channel(syms_long, H_ISI);
r_noisy_long = add_awgn(r_ch_long, 22 + 10*log10(k));

grad_bias = 0.00015 * (1 + 1j);

w_std = zeros(N_eq, 1);
x_buf = zeros(N_eq, 1);
w_norm_std = zeros(N_sym_long, 1);
scale_factor = sqrt(42); inv_scale = 1.0/sqrt(42);

for n = 1:N_sym_long
    x_buf = [r_noisy_long(n); x_buf(1:N_eq-1)];
    y_n = sum(conj(w_std) .* x_buf);
    tx_idx = n - delay;
    if tx_idx >= 1 && tx_idx <= N_sym_long
        if tx_idx <= N_tr
            d_n = syms_long(tx_idx);
        else
            I_dec = 2.0 * round((min(max(real(y_n)*scale_factor, -7.0), 7.0) - 1.0) / 2.0) + 1.0;
            Q_dec = 2.0 * round((min(max(imag(y_n)*scale_factor, -7.0), 7.0) - 1.0) / 2.0) + 1.0;
            d_n = complex(I_dec * inv_scale, Q_dec * inv_scale);
        end
        err = d_n - y_n;
        w_std = w_std + mu_lms * conj(err) * x_buf + grad_bias;
    end
    w_norm_std(n) = norm(w_std);
end

alpha_leak = 0.999;
w_leak = zeros(N_eq, 1);
x_buf = zeros(N_eq, 1);
w_norm_leak = zeros(N_sym_long, 1);

for n = 1:N_sym_long
    x_buf = [r_noisy_long(n); x_buf(1:N_eq-1)];
    y_n = sum(conj(w_leak) .* x_buf);
    tx_idx = n - delay;
    if tx_idx >= 1 && tx_idx <= N_sym_long
        if tx_idx <= N_tr
            d_n = syms_long(tx_idx);
        else
            I_dec = 2.0 * round((min(max(real(y_n)*scale_factor, -7.0), 7.0) - 1.0) / 2.0) + 1.0;
            Q_dec = 2.0 * round((min(max(imag(y_n)*scale_factor, -7.0), 7.0) - 1.0) / 2.0) + 1.0;
            d_n = complex(I_dec * inv_scale, Q_dec * inv_scale);
        end
        err = d_n - y_n;
        w_leak = alpha_leak * w_leak + mu_lms * conj(err) * x_buf + grad_bias;
    end
    w_norm_leak(n) = norm(w_leak);
end

%% 4. Figures 17 & 18

fig16 = figure('Name', 'fig17_equalizer_benchmark_comparison', 'NumberTitle', 'off', ...
               'Position', [100, 100, 1050, 500], 'Color', 'w');

subplot(1, 2, 1);
ax16_1 = gca;
semilogy(ax16_1, snr_vec, max(ber_zf, 1e-6), 'm--d', 'LineWidth', 1.6, 'MarkerFaceColor', 'm', 'MarkerSize', 6); hold(ax16_1, 'on');
semilogy(ax16_1, snr_vec, max(ber_mmse, 1e-6), 'k-s', 'LineWidth', 1.8, 'MarkerFaceColor', 'k', 'MarkerSize', 6);
semilogy(ax16_1, snr_vec, max(ber_lms, 1e-6), 'b-o', 'LineWidth', 1.8, 'MarkerFaceColor', 'b', 'MarkerSize', 6);
semilogy(ax16_1, snr_vec, max(ber_nlms, 1e-6), 'g-^', 'LineWidth', 1.8, 'MarkerFaceColor', [0 0.6 0], 'MarkerSize', 6);
set(ax16_1, 'Color', 'w', 'XColor', [0.15 0.15 0.15], 'YColor', [0.15 0.15 0.15], ...
            'LineWidth', 1.1, 'FontSize', 10, 'FontName', 'Helvetica');
grid(ax16_1, 'on'); set(ax16_1, 'GridColor', [0.75 0.75 0.75], 'GridAlpha', 0.4);
box(ax16_1, 'on');
xlabel(ax16_1, 'E_b/N_0 (dB)', 'FontWeight', 'bold', 'FontSize', 11, 'Color', [0.1 0.1 0.1]);
ylabel(ax16_1, 'Bit Error Rate (BER)', 'FontWeight', 'bold', 'FontSize', 11, 'Color', [0.1 0.1 0.1]);
title(ax16_1, '(a) Nominal BER: NLMS Comparable to LMS', 'FontWeight', 'bold', 'FontSize', 11, 'Color', [0.05 0.05 0.05]);
lgd16_1 = legend(ax16_1, {'Zero-Forcing (ZF)', 'Matrix MMSE', 'Standard LMS (\mu=0.02)', 'Normalized LMS (NLMS)'}, ...
                 'Location', 'southwest', 'FontSize', 9, 'Color', 'w', 'EdgeColor', [0.8 0.8 0.8]);
set(lgd16_1, 'TextColor', [0 0 0]);
ylim(ax16_1, [1e-6, 1.0]); xlim(ax16_1, [snr_vec(1), snr_vec(end)]);

subplot(1, 2, 2);
ax16_2 = gca;
iter_axis = 1:N_sym_dyn;
semilogy(ax16_2, iter_axis, mse_lms_stat(iter_axis), 'b-', 'LineWidth', 1.5); hold(ax16_2, 'on');
semilogy(ax16_2, iter_axis, mse_nlms_stat(iter_axis), 'Color', [0 0.6 0], 'LineWidth', 1.5);
mse_clip_level = 1e3;
mse_lms_surge_plot = min(mse_lms_surge(iter_axis), mse_clip_level);
semilogy(ax16_2, iter_axis, mse_lms_surge_plot, 'b--', 'LineWidth', 1.4);
semilogy(ax16_2, iter_axis, mse_nlms_surge(iter_axis), 'Color', [0 0.6 0], 'LineStyle', '--', 'LineWidth', 1.4);
xline(ax16_2, N_tr + delay, 'k:', 'LineWidth', 1.3);
text(ax16_2, N_tr + 30, 2.0, 'DD Switch', 'FontSize', 8.5, 'FontWeight', 'bold', 'Color', [0.1 0.1 0.1]);

xline(ax16_2, surge_idx, 'r-.', 'LineWidth', 1.3);
text(ax16_2, surge_idx + 40, 2.0, sprintf('+%d dB Surge', surge_db), 'FontSize', 8.5, 'FontWeight', 'bold', 'Color', [0.8 0.1 0.1]);
text(ax16_2, surge_idx + 180, 18, 'LMS exceeds plot range', 'FontSize', 8.5, 'FontWeight', 'bold', 'Color', [0 0 0.8]);
text(ax16_2, surge_idx + 520, 0.045, 'NLMS recovers', 'FontSize', 8.5, 'FontWeight', 'bold', 'Color', [0 0.45 0]);
set(ax16_2, 'Color', 'w', 'XColor', [0.15 0.15 0.15], 'YColor', [0.15 0.15 0.15], ...
            'LineWidth', 1.1, 'FontSize', 10, 'FontName', 'Helvetica');
grid(ax16_2, 'on'); set(ax16_2, 'GridColor', [0.75 0.75 0.75], 'GridAlpha', 0.4);
box(ax16_2, 'on');
xlabel(ax16_2, 'Iteration / Symbol Index (n)', 'FontWeight', 'bold', 'FontSize', 11, 'Color', [0.1 0.1 0.1]);
ylabel(ax16_2, 'Smoothed MSE', 'FontWeight', 'bold', 'FontSize', 11, 'Color', [0.1 0.1 0.1]);
title(ax16_2, sprintf('(b) +%d dB Surge: NLMS Recovers, LMS Unstable', surge_db), 'FontWeight', 'bold', 'FontSize', 11, 'Color', [0.05 0.05 0.05]);
lgd16_2 = legend(ax16_2, {'Standard LMS (Static)', 'NLMS (Static)', sprintf('Standard LMS (+%d dB)', surge_db), sprintf('NLMS (+%d dB)', surge_db)}, ...
                 'Location', 'northeast', 'FontSize', 8.5, 'Color', 'w', 'EdgeColor', [0.8 0.8 0.8]);
set(lgd16_2, 'TextColor', [0 0 0]);
yline(ax16_2, mse_clip_level, 'k:', 'Display ceiling (not a limiter)', 'LineWidth', 1.1, 'LabelHorizontalAlignment', 'left', 'HandleVisibility', 'off');
ylim(ax16_2, [1e-3, mse_clip_level]); xlim(ax16_2, [1, N_sym_dyn]);

fig17 = figure('Name', 'fig18_leaky_lms_bias', 'NumberTitle', 'off', ...
               'Position', [120, 120, 950, 420], 'Color', 'w');

subplot(1, 2, 1);
ax17_1 = gca;
plot(ax17_1, 1:N_sym_long, w_norm_std, 'r--', 'LineWidth', 1.5); hold(ax17_1, 'on');
plot(ax17_1, 1:N_sym_long, w_norm_leak, 'b-', 'LineWidth', 1.8);
yline(ax17_1, 2.0, 'k:', 'Tap-norm reference (2.0)', 'LineWidth', 1.2);
set(ax17_1, 'Color', 'w', 'XColor', [0.15 0.15 0.15], 'YColor', [0.15 0.15 0.15], ...
            'LineWidth', 1.1, 'FontSize', 10, 'FontName', 'Helvetica');
grid(ax17_1, 'on'); set(ax17_1, 'GridColor', [0.75 0.75 0.75], 'GridAlpha', 0.4);
box(ax17_1, 'on');
xlabel(ax17_1, 'Symbol Index (n)', 'FontWeight', 'bold', 'Color', [0.1 0.1 0.1]);
ylabel(ax17_1, 'Tap Weight Norm ||w[n]||', 'FontWeight', 'bold', 'Color', [0.1 0.1 0.1]);
title(ax17_1, '(a) Weight Drift Suppression with Bias', 'FontWeight', 'bold', 'FontSize', 10.5, 'Color', [0.05 0.05 0.05]);
lgd17_1 = legend(ax17_1, {'Standard LMS (Biased)', 'Leaky LMS (\alpha=0.999)', 'Tap-norm reference'}, ...
                 'Location', 'northwest', 'FontSize', 8.5, 'Color', 'w', 'EdgeColor', [0.8 0.8 0.8]);
set(lgd17_1, 'TextColor', [0 0 0]);

subplot(1, 2, 2);
ax17_2 = gca;
final_norms = [w_norm_std(end), w_norm_leak(end)];
b = bar(ax17_2, 1:2, final_norms, 0.50, 'FaceColor', 'flat');
b.CData(1, :) = [0.85 0.10 0.10];
b.CData(2, :) = [0.00 0.20 0.85];
set(ax17_2, 'Color', 'w', 'XColor', [0.15 0.15 0.15], 'YColor', [0.15 0.15 0.15], ...
            'XTick', 1:2, 'XTickLabel', {'Standard', 'Leaky'}, 'FontSize', 9.5);
grid(ax17_2, 'on'); set(ax17_2, 'GridColor', [0.75 0.75 0.75], 'GridAlpha', 0.4);
box(ax17_2, 'on');
ylabel(ax17_2, 'Final Tap Norm ||w||', 'FontWeight', 'bold', 'Color', [0.1 0.1 0.1]);
title(ax17_2, '(b) Final Tap Norm Under Bias', 'FontWeight', 'bold', 'FontSize', 10.5, 'Color', [0.05 0.05 0.05]);
yline(ax17_2, 2.0, 'k:', 'Tap-norm reference', 'LineWidth', 1.1);
for norm_idx = 1:2
    text(ax17_2, norm_idx, final_norms(norm_idx) + 0.04, sprintf('%.3f', final_norms(norm_idx)), ...
         'HorizontalAlignment', 'center', 'FontWeight', 'bold', 'FontSize', 9, 'Color', [0.1 0.1 0.1]);
end
ylim(ax17_2, [0, 2.2]);

if EXPORT_FIGS
    export_fig(fig16, REPORT_DIR, 'fig17_equalizer_benchmark_comparison', FIG_RES);
    export_fig(fig17, REPORT_DIR, 'fig18_leaky_lms_bias', FIG_RES);
end

fprintf('Experiment 4 complete.\n\n');
