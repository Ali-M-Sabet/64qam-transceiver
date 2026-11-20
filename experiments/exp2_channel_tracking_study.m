% Compare frozen MMSE and adaptive LMS on changing channels.
clear; close all;
run(fullfile(fileparts(mfilename('fullpath')), '..', 'config.m'));

fprintf('Experiment 2: Channel tracking\n');

h1 = H_ISI(:) / norm(H_ISI);
h2 = H_TV_STEP(:) / norm(H_TV_STEP);

rng(RNG_SEED, 'twister');
bits_tx = generate_bits(N_BITS, RNG_SEED);
[symbols_tx, ~] = qam_mapper(bits_tx, M);
esn0_test = SNR_REF_DB + 10*log10(k);
T_dbl = lms_types('double');

%% 1. Scenario A: Sudden Channel Step Transition
switch_idx = 20000;

[r_step, h_step_mat] = time_varying_channel(symbols_tx, h1, h2, 'step', switch_idx);
r_step_noisy = add_awgn(r_step, esn0_test);

w_frozen_h1 = design_mmse_equalizer(h1, LMS_N_EQ, LMS_DELAY, esn0_test);
y_frozen_step_full = apply_fir_equalizer(r_step_noisy, w_frozen_h1);
y_frozen_step      = align_and_trim(y_frozen_step_full, N_SYM, LMS_DELAY);

[y_lms_step, ~, w_hist_step, ~] = ...
    lms_core(r_step_noisy, symbols_tx, LMS_MU, LMS_N_EQ, LMS_N_TRAIN, LMS_DELAY, T_dbl);

alpha_smooth = 0.99;
% Use known transmitted symbols offline for a fair error comparison.
mse_hist_step = filter(1 - alpha_smooth, [1, -alpha_smooth], abs(symbols_tx - y_lms_step).^2);

e_frozen_step = abs(symbols_tx - y_frozen_step).^2;
mse_hist_frozen_step = filter(1 - alpha_smooth, [1, -alpha_smooth], e_frozen_step);

pre_range  = (LMS_N_TRAIN + 100) : switch_idx;
post_range = (switch_idx + 1000) : min(N_SYM, switch_idx + 20000);

evm_pre_frozen  = compute_evm(symbols_tx(pre_range), y_frozen_step(pre_range));
evm_post_frozen = compute_evm(symbols_tx(post_range), y_frozen_step(post_range));

evm_pre_lms  = compute_evm(symbols_tx(pre_range), y_lms_step(pre_range));
evm_post_lms = compute_evm(symbols_tx(post_range), y_lms_step(post_range));

bits_tx_post = bits_tx((post_range(1)-1)*k + 1 : post_range(end)*k);
bits_rx_frozen_post = qam_demapper(y_frozen_step(post_range), M);
bits_rx_lms_post    = qam_demapper(y_lms_step(post_range), M);

[ber_frozen_post, ~] = compute_ber_ser(bits_tx_post, bits_rx_frozen_post, k);
[ber_lms_post, ~]    = compute_ber_ser(bits_tx_post, bits_rx_lms_post, k);

bits_tx_pre = bits_tx((pre_range(1)-1)*k + 1 : pre_range(end)*k);
[ber_frozen_pre, ~] = compute_ber_ser(bits_tx_pre, qam_demapper(y_frozen_step(pre_range), M), k);
[ber_lms_pre, ~] = compute_ber_ser(bits_tx_pre, qam_demapper(y_lms_step(pre_range), M), k);

%% 2. Scenario B: Continuous Linear Channel Drift

[r_drift, h_drift_mat] = time_varying_channel(symbols_tx, h1, h2, 'drift');
r_drift_noisy = add_awgn(r_drift, esn0_test);

y_frozen_drift_full = apply_fir_equalizer(r_drift_noisy, w_frozen_h1);
y_frozen_drift      = align_and_trim(y_frozen_drift_full, N_SYM, LMS_DELAY);

[y_lms_drift, ~, ~, ~] = ...
    lms_core(r_drift_noisy, symbols_tx, LMS_MU, LMS_N_EQ, LMS_N_TRAIN, LMS_DELAY, T_dbl);

block_len   = 1000;
N_blocks    = floor(N_SYM / block_len);
evm_frozen_drift_block = zeros(N_SYM, 1);
evm_lms_drift_block    = zeros(N_SYM, 1);

for b = 1:N_blocks
    b_idx = (b-1)*block_len + 1 : b*block_len;
    evm_f_b = compute_evm(symbols_tx(b_idx), y_frozen_drift(b_idx));
    evm_l_b = compute_evm(symbols_tx(b_idx), y_lms_drift(b_idx));
    evm_frozen_drift_block(b_idx) = evm_f_b;
    evm_lms_drift_block(b_idx)    = evm_l_b;
end

pay_range = (LMS_N_TRAIN + 1) : N_SYM;
evm_total_frozen_drift = compute_evm(symbols_tx(pay_range), y_frozen_drift(pay_range));
evm_total_lms_drift    = compute_evm(symbols_tx(pay_range), y_lms_drift(pay_range));

bits_tx_pay = bits_tx(LMS_N_TRAIN*k + 1 : end);
bits_rx_frozen_drift = qam_demapper(y_frozen_drift(pay_range), M);
bits_rx_lms_drift    = qam_demapper(y_lms_drift(pay_range), M);

[ber_frozen_drift, ~] = compute_ber_ser(bits_tx_pay, bits_rx_frozen_drift, k);
[ber_lms_drift, ~]    = compute_ber_ser(bits_tx_pay, bits_rx_lms_drift, k);

%% 3. Figures (Figs 11, 12, 13)

disp_step_samples = min(40000, N_SYM);
time_disp_step    = 1:disp_step_samples;

time_disp_drift   = 1:N_SYM;

[fig10, fig11, fig12] = plot_channel_tracking(...
    time_disp_step, ...
    h_step_mat(:, time_disp_step), ...
    mse_hist_step(time_disp_step), ...
    w_hist_step(:, time_disp_step), ...
    time_disp_drift, ...
    h_drift_mat(:, time_disp_drift), ...
    evm_frozen_drift_block(time_disp_drift), ...
    evm_lms_drift_block(time_disp_drift), ...
    y_lms_step(pre_range(1:min(5000, length(pre_range)))), ...
    y_frozen_step(post_range(1:min(5000, length(post_range)))), ...
    y_lms_step(post_range(1:min(5000, length(post_range)))), ...
    y_lms_drift(post_range(1:min(5000, length(post_range)))), ...
    switch_idx, ...
    mse_hist_frozen_step(time_disp_step));

if EXPORT_FIGS
    export_fig(fig10, REPORT_DIR, 'fig11_channel_step_tracking', FIG_RES);
    export_fig(fig11, REPORT_DIR, 'fig12_channel_drift_tracking', FIG_RES);
    export_fig(fig12, REPORT_DIR, 'fig13_tv_constellations_comparison', FIG_RES);
end

fprintf('Experiment 2 complete.\n\n');
