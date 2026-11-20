% 64-QAM link with fixed and adaptive equalizers.
clear; close all;

run(fullfile(fileparts(mfilename('fullpath')), 'config.m'));

fprintf('64-QAM link simulation\n');

if EXPORT_FIGS && ~exist(REPORT_DIR, 'dir')
    mkdir(REPORT_DIR);
end

%% 1. Transmitter and loopback

bits_tx = generate_bits(N_BITS, RNG_SEED);

[symbols_tx, constellation] = qam_mapper(bits_tx, M);
avg_power = mean(abs(symbols_tx).^2);

bits_rx_ideal = qam_demapper(symbols_tx, M);
n_err_ideal   = sum(bits_tx ~= bits_rx_ideal);
assert(n_err_ideal == 0, 'main:Loopback', 'Ideal loopback has %d bit errors.', n_err_ideal);

fig1 = plot_constellation(constellation, ...
    sprintf('Ideal 64-QAM Constellation (Gray-Coded, E_s = 1 (normalized))\nM = %d, k = %d bits/sym', M, k), ...
    constellation, 'fig01_ideal_constellation');
if EXPORT_FIGS
    export_fig(fig1, REPORT_DIR, 'fig01_ideal_constellation', FIG_RES);
end

%% 2. AWGN baseline

N_snr    = length(SNR_EbN0_dB);
BER_awgn = zeros(1, N_snr);
SER_awgn = zeros(1, N_snr);
EVM_awgn = zeros(1, N_snr);

for idx = 1:N_snr
    EbN0_i = SNR_EbN0_dB(idx);
    EsN0_i = EbN0_i + 10*log10(k);

    r_awgn_i = add_awgn(symbols_tx, EsN0_i);

    bits_rx_i = qam_demapper(r_awgn_i, M);
    [BER_awgn(idx), SER_awgn(idx)] = compute_ber_ser(bits_tx, bits_rx_i, k);
    EVM_awgn(idx) = compute_evm(symbols_tx, r_awgn_i);
end

BER_theory_awgn = berawgn(SNR_EbN0_dB, 'qam', M);

fig2 = plot_ber_curve(SNR_EbN0_dB, ...
    {BER_awgn, BER_theory_awgn}, ...
    {'Simulated (AWGN)', 'Theoretical (AWGN)'}, ...
    sprintf('BER vs. E_b/N_0 - 64-QAM over AWGN Channel\nM = %d, N_{bits} = %.1e', M, N_BITS), ...
    'fig02_ber_awgn');
if EXPORT_FIGS
    export_fig(fig2, REPORT_DIR, 'fig02_ber_awgn', FIG_RES);
end

%% 3. Multipath channel

[r_ch_full, ch_delay] = apply_fir_channel(symbols_tx, H_ISI);
fprintf('  Channel convolution complete. Output length = %d samples\n', length(r_ch_full));

fig3 = plot_channel_response(H_ISI, 'fig03_channel_response');
if EXPORT_FIGS
    export_fig(fig3, REPORT_DIR, 'fig03_channel_response', FIG_RES);
end

EsN0_noeq_ref = SNR_REF_DB + 10*log10(k);
r_noeq_ref = add_awgn(r_ch_full(1:N_SYM), EsN0_noeq_ref);
fig4 = plot_constellation(r_noeq_ref, ...
    sprintf('No-Equalizer ISI Constellation at E_b/N_0 = %d dB', SNR_REF_DB), ...
    constellation, 'fig04_isi_noeq_constellation');
if EXPORT_FIGS
    export_fig(fig4, REPORT_DIR, 'fig04_isi_noeq_constellation', FIG_RES);
end

BER_isi_noeq = zeros(1, N_snr);
EVM_isi_noeq = zeros(1, N_snr);

for idx = 1:N_snr
    EbN0_i = SNR_EbN0_dB(idx);
    EsN0_i = EbN0_i + 10*log10(k);

    r_noeq_noisy = add_awgn(r_ch_full(1:N_SYM), EsN0_i);

    bits_rx_noeq = qam_demapper(r_noeq_noisy, M);
    [BER_isi_noeq(idx), ~] = compute_ber_ser(bits_tx, bits_rx_noeq, k);
    EVM_isi_noeq(idx) = compute_evm(symbols_tx, r_noeq_noisy);
end

fig5 = plot_ber_curve(SNR_EbN0_dB, ...
    {BER_awgn, BER_theory_awgn, BER_isi_noeq}, ...
    {'AWGN Simulated', 'AWGN Theory', 'ISI Channel (No Equalizer)'}, ...
    sprintf('BER vs. E_b/N_0 - AWGN Baseline vs. ISI Error Floor\nM = %d, h = [%s]', ...
            M, num2str(H_ISI, '%.3f ')), ...
    'fig05_ber_isi_noeq');
if EXPORT_FIGS
    export_fig(fig5, REPORT_DIR, 'fig05_ber_isi_noeq', FIG_RES);
end

%% 4. ZF and MMSE equalizers

[w_zf, ~]   = design_zf_equalizer(H_ISI, EQ_LEN, EQ_DELAY);
w_mmse_demo = design_mmse_equalizer(H_ISI, EQ_LEN, EQ_DELAY, SNR_REF_DB + 10*log10(k));

fig6 = plot_equalizer_response(H_ISI, w_zf, w_mmse_demo, 'fig06_equalizer_responses');
if EXPORT_FIGS
    export_fig(fig6, REPORT_DIR, 'fig06_equalizer_responses', FIG_RES);
end

EsN0_demo  = SNR_REF_DB + 10*log10(k);
r_isi_demo = add_awgn(r_ch_full, EsN0_demo);

y_zf_full   = apply_fir_equalizer(r_isi_demo, w_zf);
y_zf_demo   = align_and_trim(y_zf_full, N_SYM, EQ_DELAY);
evm_zf_demo = compute_evm(symbols_tx, y_zf_demo);

y_mmse_full   = apply_fir_equalizer(r_isi_demo, w_mmse_demo);
y_mmse_demo   = align_and_trim(y_mmse_full, N_SYM, EQ_DELAY);
evm_mmse_demo = compute_evm(symbols_tx, y_mmse_demo);

BER_zf   = zeros(1, N_snr);
EVM_zf   = zeros(1, N_snr);
BER_mmse = zeros(1, N_snr);
EVM_mmse = zeros(1, N_snr);

for idx = 1:N_snr
    EbN0_i = SNR_EbN0_dB(idx);
    EsN0_i = EbN0_i + 10*log10(k);

    r_noisy_i = add_awgn(r_ch_full, EsN0_i);

    y_zf_i = apply_fir_equalizer(r_noisy_i, w_zf);
    y_zf_al = align_and_trim(y_zf_i, N_SYM, EQ_DELAY);
    bits_rx_zf_i = qam_demapper(y_zf_al, M);
    [BER_zf(idx), ~] = compute_ber_ser(bits_tx, bits_rx_zf_i, k);
    EVM_zf(idx) = compute_evm(symbols_tx, y_zf_al);

    w_mmse_i = design_mmse_equalizer(H_ISI, EQ_LEN, EQ_DELAY, EsN0_i);
    y_mmse_i = apply_fir_equalizer(r_noisy_i, w_mmse_i);
    y_mmse_al = align_and_trim(y_mmse_i, N_SYM, EQ_DELAY);
    bits_rx_mmse_i = qam_demapper(y_mmse_al, M);
    [BER_mmse(idx), ~] = compute_ber_ser(bits_tx, bits_rx_mmse_i, k);
    EVM_mmse(idx) = compute_evm(symbols_tx, y_mmse_al);
end

%% 5. LMS equalizer

T_dbl = lms_types('double');
[y_lms_full, w_lms_final, w_hist_lms, e_hist_lms] = ...
    lms_core(r_isi_demo, symbols_tx, LMS_MU, LMS_N_EQ, LMS_N_TRAIN, LMS_DELAY, T_dbl);

payload_start   = LMS_N_TRAIN + 1;
symbols_tx_pay  = symbols_tx(payload_start : end);
y_lms_payload   = y_lms_full(payload_start : end);

bits_tx_payload = bits_tx((payload_start - 1)*k + 1 : end);
bits_rx_lms_pay = qam_demapper(y_lms_payload, M);

[BER_lms_payload, ~] = compute_ber_ser(bits_tx_payload, bits_rx_lms_pay, k);
EVM_lms_payload      = compute_evm(symbols_tx_pay, y_lms_payload);

alpha_smooth = 0.99;
mse_hist_lms = filter(1 - alpha_smooth, [1, -alpha_smooth], e_hist_lms);
fig8 = plot_lms_learning(mse_hist_lms, w_hist_lms, LMS_N_TRAIN, LMS_MU, 6000, 'fig08_lms_learning_curve', LMS_DELAY);
if EXPORT_FIGS
    export_fig(fig8, REPORT_DIR, 'fig08_lms_learning_curve', FIG_RES);
end

BER_lms = zeros(1, N_snr);
EVM_lms = zeros(1, N_snr);

for idx = 1:N_snr
    EbN0_i = SNR_EbN0_dB(idx);
    EsN0_i = EbN0_i + 10*log10(k);

    r_noisy_i = add_awgn(r_ch_full, EsN0_i);

    [y_lms_i, ~, ~, ~] = lms_core(r_noisy_i, symbols_tx, LMS_MU, LMS_N_EQ, LMS_N_TRAIN, LMS_DELAY, T_dbl);

    y_lms_pay_i   = y_lms_i(payload_start : end);
    bits_rx_lms_i = qam_demapper(y_lms_pay_i, M);

    [BER_lms(idx), ~] = compute_ber_ser(bits_tx_payload, bits_rx_lms_i, k);
    EVM_lms(idx)      = compute_evm(symbols_tx_pay, y_lms_pay_i);
end

fig7 = plot_ber_curve(SNR_EbN0_dB, ...
    {BER_awgn, BER_theory_awgn, BER_isi_noeq, BER_zf, BER_mmse, BER_lms}, ...
    {'AWGN Simulated', 'AWGN Theory', 'ISI No-EQ (Error Floor)', 'ZF Equalizer', 'MMSE Equalizer', 'LMS DD'}, ...
    sprintf('Master BER vs. E_b/N_0 - Equalizer Comparison\n64-QAM, N_{eq} = %d, D = %d', EQ_LEN, EQ_DELAY), ...
    'fig07_ber_master_equalizers');
if EXPORT_FIGS
    export_fig(fig7, REPORT_DIR, 'fig07_ber_master_equalizers', FIG_RES);
end

%% 6. Channel tracking

[r_tv_step, ~] = time_varying_channel(symbols_tx, H_ISI, H_TV_STEP, 'step');
r_tv_step_noisy = add_awgn(r_tv_step, EsN0_demo);

[y_lms_step, ~, ~, ~] = lms_core(r_tv_step_noisy, symbols_tx, LMS_MU, LMS_N_EQ, LMS_N_TRAIN, LMS_DELAY, T_dbl);
bits_rx_lms_step = qam_demapper(y_lms_step(payload_start:end), M);
[BER_lms_step, ~] = compute_ber_ser(bits_tx_payload, bits_rx_lms_step, k);

y_static_step = apply_fir_equalizer(r_tv_step_noisy, conj(w_lms_final));
y_static_step_al = align_and_trim(y_static_step, N_SYM, LMS_DELAY);
bits_rx_static_step = qam_demapper(y_static_step_al(payload_start:end), M);
[BER_static_step, ~] = compute_ber_ser(bits_tx_payload, bits_rx_static_step, k);

%% 7. Fixed-point comparison

N_fx_sym     = 10000;
r_fx_demo    = r_isi_demo(1:N_fx_sym);
syms_fx_demo = symbols_tx(1:N_fx_sym);
bits_fx_pay  = bits_tx(LMS_N_TRAIN*k + 1 : N_fx_sym*k);
pay_fx_range = (LMS_N_TRAIN + 1) : N_fx_sym;

% Use the same block for the floating reference and fixed-point comparisons.
[y_fx_float, ~] = lms_core(r_fx_demo, syms_fx_demo, LMS_MU, LMS_N_EQ, LMS_N_TRAIN, LMS_DELAY, lms_types('double'));
EVM_fx_float = compute_evm(syms_fx_demo(pay_fx_range), y_fx_float(pay_fx_range));
[BER_fx_float, ~] = compute_ber_ser(bits_fx_pay, qam_demapper(y_fx_float(pay_fx_range), M), k);

T_fxpt16 = lms_types('FxPt', FXPT_W_PRIMARY);
[y_fx16, ~, ~, ~] = lms_core(r_fx_demo, syms_fx_demo, LMS_MU, LMS_N_EQ, LMS_N_TRAIN, LMS_DELAY, T_fxpt16);
y_fx16_pay = double(y_fx16(pay_fx_range));
bits_rx_fx16 = qam_demapper(y_fx16_pay, M);
[BER_fx16, ~] = compute_ber_ser(bits_fx_pay, bits_rx_fx16, k);
EVM_fx16 = compute_evm(syms_fx_demo(pay_fx_range), y_fx16_pay);

T_fxpt12 = lms_types('FxPt', FXPT_W_REDUCED);
[y_fx12, ~, ~, ~] = lms_core(r_fx_demo, syms_fx_demo, LMS_MU, LMS_N_EQ, LMS_N_TRAIN, LMS_DELAY, T_fxpt12);
y_fx12_pay = double(y_fx12(pay_fx_range));
bits_rx_fx12 = qam_demapper(y_fx12_pay, M);
[BER_fx12, ~] = compute_ber_ser(bits_fx_pay, bits_rx_fx12, k);
EVM_fx12 = compute_evm(syms_fx_demo(pay_fx_range), y_fx12_pay);

%% 8. Results
fprintf('BER summary\n');
fprintf('   %8s | %13s | %13s | %13s | %13s | %13s | %10s\n', ...
        'Eb/N0(dB)', 'BER (AWGN)', 'BER (No-EQ)', 'BER (ZF)', 'BER (MMSE)', 'BER (LMS DD)', 'EVM (LMS)');
for sp = [10, 14, 18, 22, 26, 30]
    ii = find(SNR_EbN0_dB == sp, 1);
    if ~isempty(ii)
        fprintf('   %8d | %13.4e | %13.4e | %13.4e | %13.4e | %13.4e | %9.2f%%\n', ...
                sp, BER_awgn(ii), BER_isi_noeq(ii), BER_zf(ii), BER_mmse(ii), BER_lms(ii), EVM_lms(ii));
    end
end

fprintf('Main simulation complete.\n');
