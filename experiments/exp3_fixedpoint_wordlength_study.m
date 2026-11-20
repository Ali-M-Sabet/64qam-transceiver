% Compare floating point with 16/14/12/10/8-bit LMS registers.
clear; close all;
run(fullfile(fileparts(mfilename('fullpath')), '..', 'config.m'));

fprintf('Experiment 3: Fixed-point word lengths\n');

T_double = lms_types('double');
T_fxpt16 = lms_types('FxPt', 16);   % Q(1.14)
T_fxpt14 = lms_types('FxPt', 14);   % Q(1.12)
T_fxpt12 = lms_types('FxPt', 12);   % Q(1.10)
T_fxpt10 = lms_types('FxPt', 10);   % Q(1. 8)
T_fxpt8  = lms_types('FxPt',  8);   % Q(1. 6)

cfg_labels  = {'Double Float (64-bit)', '16-bit Q(1.14)', '14-bit Q(1.12)', ...
               '12-bit Q(1.10)', '10-bit Q(1.8)', '8-bit Q(1.6)'};
cfg_types   = {T_double, T_fxpt16, T_fxpt14, T_fxpt12, T_fxpt10, T_fxpt8};
cfg_colors  = {[0 0.447 0.741], [0.466 0.674 0.188], [0.301 0.745 0.933], ...
               [0.850 0.325 0.098], [0.494 0.184 0.556], [0.635 0.078 0.184]};
cfg_markers = {'o', 's', '^', 'd', 'v', 'p'};
N_cfg = numel(cfg_types);

snr_sweep   = 10:2:24;
N_snr       = length(snr_sweep);
N_sym_sweep = 5000;
N_bits_sweep = N_sym_sweep * k;
pay_range    = (LMS_N_TRAIN + 1) : N_sym_sweep;

esn0_ref    = SNR_REF_DB + 10*log10(k);
N_sym_ref   = 10000;
N_bits_ref  = N_sym_ref * k;
pay_range_ref = (LMS_N_TRAIN + 1) : N_sym_ref;

ber_matrix  = zeros(N_cfg, N_snr);

%% 1. BER sweep

rng(RNG_SEED, 'twister');
bits_sw   = generate_bits(N_bits_sweep, RNG_SEED);
[syms_sw, ~] = qam_mapper(bits_sw, M);
r_ch_sw   = apply_fir_channel(syms_sw, H_ISI);
bits_tx_pay_sw = bits_sw(LMS_N_TRAIN*k + 1 : N_sym_sweep*k);

for s = 1:N_snr
    esn0_s = snr_sweep(s) + 10*log10(k);
    r_noisy_s = add_awgn(r_ch_sw, esn0_s);

    for c = 1:N_cfg
        [y_c, ~]  = lms_core(r_noisy_s, syms_sw, LMS_MU, LMS_N_EQ, LMS_N_TRAIN, LMS_DELAY, cfg_types{c});
        y_c_d     = double(y_c);
        bits_rx_c = qam_demapper(y_c_d(pay_range), M);
        [ber_matrix(c, s), ~] = compute_ber_ser(bits_tx_pay_sw, bits_rx_c, k);
    end

end

%% 2. EVM and SQNR at 22 dB

rng(RNG_SEED + 1, 'twister');
bits_ref  = generate_bits(N_bits_ref, RNG_SEED + 1);
[syms_ref, ~] = qam_mapper(bits_ref, M);
r_ch_ref  = apply_fir_channel(syms_ref, H_ISI);
r_noisy_ref = add_awgn(r_ch_ref, esn0_ref);
bits_tx_pay_ref = bits_ref(LMS_N_TRAIN*k + 1 : N_sym_ref*k);

evm_vec  = zeros(N_cfg, 1);
sqnr_vec = zeros(N_cfg, 1);
ber_22   = zeros(N_cfg, 1);
const_syms = cell(N_cfg, 1);

[y_ref_fl, ~] = lms_core(r_noisy_ref, syms_ref, LMS_MU, LMS_N_EQ, LMS_N_TRAIN, LMS_DELAY, T_double);
y_fl_d = double(y_ref_fl);

for c = 1:N_cfg
    [y_c, ~]  = lms_core(r_noisy_ref, syms_ref, LMS_MU, LMS_N_EQ, LMS_N_TRAIN, LMS_DELAY, cfg_types{c});
    y_c_d     = double(y_c);

    evm_vec(c) = compute_evm(syms_ref(pay_range_ref), y_c_d(pay_range_ref));

    bits_rx_c = qam_demapper(y_c_d(pay_range_ref), M);
    [ber_22(c), ~] = compute_ber_ser(bits_tx_pay_ref, bits_rx_c, k);

    if c == 1
        sqnr_vec(c) = Inf; % Identical reference output: zero quantization error.
    else
        quant_err = y_fl_d(pay_range_ref) - y_c_d(pay_range_ref);
        sig_pow   = mean(abs(y_fl_d(pay_range_ref)).^2);
        noi_pow   = mean(abs(quant_err).^2);
        sqnr_vec(c) = 10*log10(sig_pow / max(noi_pow, 1e-15));
    end

    const_syms{c} = y_c_d(pay_range_ref);
end

word_lengths = [16, 14, 12, 10, 8];

%% 4. Figures 14, 15, 16

fig13 = figure('Name', 'fig14_fixedpoint_ber_waterfall', 'NumberTitle', 'off', ...
               'Position', [100, 100, 850, 500], 'Color', 'w');
ax13 = gca;
for c = 1:N_cfg
    semilogy(ax13, snr_sweep, max(ber_matrix(c,:), 1e-7), ...
             ['-' cfg_markers{c}], 'LineWidth', 1.8, 'Color', cfg_colors{c}, ...
             'MarkerFaceColor', cfg_colors{c}, 'MarkerSize', 7, ...
             'DisplayName', cfg_labels{c});
    hold(ax13, 'on');
end

set(ax13, 'Color', 'w', 'XColor', [0.15 0.15 0.15], 'YColor', [0.15 0.15 0.15], ...
          'LineWidth', 1.1, 'FontSize', 10, 'FontName', 'Helvetica');
grid(ax13, 'on'); set(ax13, 'GridColor', [0.75 0.75 0.75], 'GridAlpha', 0.4);
box(ax13, 'on');
xlabel(ax13, 'E_b/N_0 (dB)', 'FontWeight', 'bold', 'FontSize', 11, 'Color', [0.1 0.1 0.1]);
ylabel(ax13, 'Bit Error Rate (BER)', 'FontWeight', 'bold', 'FontSize', 11, 'Color', [0.1 0.1 0.1]);
title(ax13, '64-QAM BER Waterfall - Float vs. Fixed-Point Word Lengths', 'FontSize', 12, 'FontWeight', 'bold', 'Color', [0.05 0.05 0.05]);
lgd13 = legend(ax13, 'Location', 'southwest', 'FontSize', 10, 'Color', 'w', 'EdgeColor', [0.8 0.8 0.8]);
set(lgd13, 'TextColor', [0 0 0]);
ylim(ax13, [1e-6, 1.0]); xlim(ax13, [snr_sweep(1), snr_sweep(end)]);

fig14 = figure('Name', 'fig15_fixedpoint_evm_sqnr_bars', 'NumberTitle', 'off', ...
               'Position', [150, 150, 1050, 480], 'Color', 'w');

subplot(1,2,1);
ax14_1 = gca;
b1 = bar(ax14_1, 1:N_cfg, evm_vec, 0.55, 'FaceColor', 'flat');
for c = 1:N_cfg; b1.CData(c,:) = cfg_colors{c}; end
evm_reference = yline(ax14_1, 8.0, 'r--', 'LineWidth', 1.5);
legend(ax14_1, evm_reference, '8% EVM reference', 'Location', 'northwest', ...
       'FontSize', 9, 'TextColor', [0 0 0], 'Color', 'w', 'EdgeColor', [0.8 0.8 0.8]);
set(ax14_1, 'Color', 'w', 'XColor', [0.15 0.15 0.15], 'YColor', [0.15 0.15 0.15], ...
            'XTick', 1:N_cfg, 'XTickLabel', {'Float64','16-bit','14-bit','12-bit','10-bit','8-bit'}, 'FontSize', 9);
ylabel(ax14_1, 'EVM (%) at E_b/N_0 = 22 dB', 'FontWeight', 'bold', 'Color', [0.1 0.1 0.1]);
title(ax14_1, 'EVM vs. Hardware Word Length', 'FontWeight', 'bold', 'Color', [0.05 0.05 0.05]);
grid(ax14_1, 'on'); set(ax14_1, 'GridColor', [0.75 0.75 0.75], 'GridAlpha', 0.4);
box(ax14_1, 'on');
ylim(ax14_1, [0, max(evm_vec)*1.15 + 5]);
for c = 1:N_cfg
    text(ax14_1, c, evm_vec(c) + max(evm_vec)*0.07, sprintf('%.2f%%', evm_vec(c)), ...
         'HorizontalAlignment', 'center', 'FontWeight', 'bold', 'FontSize', 9, 'Color', [0.1 0.1 0.1]);
end

subplot(1,2,2);
ax14_2 = gca;
sqnr_disp = min(sqnr_vec, 100);
b2 = bar(ax14_2, 1:N_cfg, sqnr_disp, 0.55, 'FaceColor', 'flat');
for c = 1:N_cfg; b2.CData(c,:) = cfg_colors{c}; end
set(ax14_2, 'Color', 'w', 'XColor', [0.15 0.15 0.15], 'YColor', [0.15 0.15 0.15], ...
            'XTick', 1:N_cfg, 'XTickLabel', {'Float64','16-bit','14-bit','12-bit','10-bit','8-bit'}, 'FontSize', 9);
ylabel(ax14_2, 'Measured SQNR (dB)', 'FontWeight', 'bold', 'Color', [0.1 0.1 0.1]);
title(ax14_2, 'Measured SQNR by Word Length', 'FontWeight', 'bold', 'Color', [0.05 0.05 0.05]);
grid(ax14_2, 'on'); set(ax14_2, 'GridColor', [0.75 0.75 0.75], 'GridAlpha', 0.4);
box(ax14_2, 'on');
ylim(ax14_2, [-20, 112]);
for c = 1:N_cfg
    lbl = 'Ref (Inf)'; if c > 1; lbl = sprintf('%.1f dB', sqnr_vec(c)); end
    text(ax14_2, c, max(1, sqnr_disp(c)) + 2, lbl, ...
         'HorizontalAlignment', 'center', 'FontWeight', 'bold', 'FontSize', 9, 'Color', [0.1 0.1 0.1]);
end

fig15 = figure('Name', 'fig16_fixedpoint_constellations', 'NumberTitle', 'off', ...
               'Position', [160, 80, 1100, 980], 'Color', 'w');

panel_titles = { ...
    sprintf('Float64 ref  (EVM %.2f%%)', evm_vec(1)), ...
    sprintf('16-bit Q1.14  (EVM %.2f%%, SQNR %.1f dB)', evm_vec(2), sqnr_vec(2)), ...
    sprintf('14-bit Q1.12  (EVM %.2f%%, SQNR %.1f dB)', evm_vec(3), sqnr_vec(3)), ...
    sprintf('12-bit Q1.10  (EVM %.2f%%, SQNR %.1f dB)', evm_vec(4), sqnr_vec(4)), ...
    sprintf('10-bit Q1.8  (EVM %.2f%%, SQNR %.1f dB)', evm_vec(5), sqnr_vec(5)), ...
    sprintf('8-bit Q1.6  (EVM %.1f%%, SQNR %.1f dB)', evm_vec(6), sqnr_vec(6)) ...
};

tl15 = tiledlayout(fig15, 2, 3, 'TileSpacing', 'compact', 'Padding', 'compact');
for c = 1:N_cfg
    ax15 = nexttile(tl15, c);
    s_c = const_syms{c};
    if c >= 5
        N_pts = min(2600, length(s_c));
        marker_size = 7;
        marker_alpha = 0.30;
    else
        N_pts = min(3200, length(s_c));
        marker_size = 8;
        marker_alpha = 0.42;
    end

    scatter(ax15, real(s_c(1:N_pts)), imag(s_c(1:N_pts)), marker_size, cfg_colors{c}, ...
            'filled', 'MarkerFaceAlpha', marker_alpha, 'MarkerEdgeAlpha', marker_alpha);
    set(ax15, 'Color', 'w', ...
              'XColor', [0.15 0.15 0.15], ...
              'YColor', [0.15 0.15 0.15], ...
              'FontSize', 9, ...
              'LineWidth', 0.8);
    grid(ax15, 'on');
    axis(ax15, 'equal');
    xlim(ax15, [-1.5 1.5]);
    ylim(ax15, [-1.5 1.5]);
    box(ax15, 'on');

    if c > 3
        xlabel(ax15, 'In-Phase (I)', 'Color', [0.1 0.1 0.1], 'FontSize', 10);
    end
    if mod(c, 3) == 1
        ylabel(ax15, 'Quadrature (Q)', 'Color', [0.1 0.1 0.1], 'FontSize', 10);
    end
    title(ax15, panel_titles{c}, 'FontWeight', 'bold', 'FontSize', 10, 'Color', [0.05 0.05 0.05]);
end

if EXPORT_FIGS
    export_fig(fig13, REPORT_DIR, 'fig14_fixedpoint_ber_waterfall', FIG_RES);
    export_fig(fig14, REPORT_DIR, 'fig15_fixedpoint_evm_sqnr_bars', FIG_RES);
    export_fig(fig15, REPORT_DIR, 'fig16_fixedpoint_constellations', FIG_RES);
end

word_evm = evm_vec(2:end);
word_ber = ber_22(2:end);
word_sqnr = sqnr_vec(2:end);
output_dir = fullfile(projectRoot, 'results');
if ~isfolder(output_dir), mkdir(output_dir); end
save(fullfile(output_dir, 'wordlength_results.mat'), ...
     'word_lengths', 'word_evm', 'word_ber', 'word_sqnr', ...
     'snr_sweep', 'ber_matrix', 'cfg_labels');

fprintf('Experiment 3 complete.\n\n');
