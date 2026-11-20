% MMSE seeds, fixed-filter tap length, and channel mismatch.
clear; close all;
run(fullfile(fileparts(mfilename('fullpath')), '..', 'config.m'));

fprintf('Experiment 1: Parameter sensitivity\n');

%% 1. MMSE seed comparison
seeds = [42, 100, 2026];
EbN0_points = [12, 16, 20, 22];
results_seed_ber = zeros(length(seeds), length(EbN0_points));

for s_idx = 1:length(seeds)
    s = seeds(s_idx);
    bits = generate_bits(N_BITS, s);
    [syms, ~] = qam_mapper(bits, M);
    [r_ch, ~] = apply_fir_channel(syms, H_ISI);

    for e_idx = 1:length(EbN0_points)
        ebn0 = EbN0_points(e_idx);
        esn0 = ebn0 + 10*log10(k);

        r_noisy = add_awgn(r_ch, esn0);
        w_mmse  = design_mmse_equalizer(H_ISI, EQ_LEN, EQ_DELAY, esn0);
        y_eq    = apply_fir_equalizer(r_noisy, w_mmse);
        y_align = align_and_trim(y_eq, N_SYM, EQ_DELAY);

        bits_rx = qam_demapper(y_align, M);
        [results_seed_ber(s_idx, e_idx), ~] = compute_ber_ser(bits, bits_rx, k);
    end
end

%% 2. Equalizer tap count
tap_vec   = 5:2:21;
evm_taps  = zeros(1, length(tap_vec));
ber_taps  = zeros(1, length(tap_vec));

snr_audit = SNR_REF_DB;
esn0_aud  = snr_audit + 10*log10(k);

bits_base = generate_bits(N_BITS, RNG_SEED);
[syms_base, ~] = qam_mapper(bits_base, M);
[r_ch_base, ~] = apply_fir_channel(syms_base, H_ISI);
r_noisy_aud    = add_awgn(r_ch_base, esn0_aud);

for idx = 1:length(tap_vec)
    N_t = tap_vec(idx);
    D_t = floor((N_t - 1) / 2);

    w_zf_t = design_zf_equalizer(H_ISI, N_t, D_t);
    y_eq_t = apply_fir_equalizer(r_noisy_aud, w_zf_t);
    y_al_t = align_and_trim(y_eq_t, N_SYM, D_t);

    bits_rx_t = qam_demapper(y_al_t, M);
    [ber_taps(idx), ~] = compute_ber_ser(bits_base, bits_rx_t, k);
    evm_taps(idx) = compute_evm(syms_base, y_al_t);

end

%% 3. Channel mismatch
err_pct_vec  = [0, 2, 5, 8, 10, 15, 20];
evm_mismatch = zeros(1, length(err_pct_vec));
ber_mismatch = zeros(1, length(err_pct_vec));

for idx = 1:length(err_pct_vec)
    pct = err_pct_vec(idx);
    delta_h = [0, pct/100 * H_ISI(2), -pct/100 * H_ISI(3)];
    h_est = (H_ISI + delta_h);
    h_est = h_est / norm(h_est);

    w_zf_mis = design_zf_equalizer(h_est, EQ_LEN, EQ_DELAY);
    y_eq_mis = apply_fir_equalizer(r_noisy_aud, w_zf_mis);
    y_al_mis = align_and_trim(y_eq_mis, N_SYM, EQ_DELAY);

    bits_rx_mis = qam_demapper(y_al_mis, M);
    [ber_mismatch(idx), ~] = compute_ber_ser(bits_base, bits_rx_mis, k);
    evm_mismatch(idx) = compute_evm(syms_base, y_al_mis);

end

%% 4. Figures
[fig8, fig9] = plot_sensitivity_curves(tap_vec, evm_taps, ber_taps, ...
                                      err_pct_vec, evm_mismatch, ber_mismatch);

if EXPORT_FIGS
    export_fig(fig8, REPORT_DIR, 'fig09_tap_length_sensitivity', FIG_RES);
    export_fig(fig9, REPORT_DIR, 'fig10_channel_mismatch_sensitivity', FIG_RES);
end

fprintf('Experiment 1 complete.\n\n');
