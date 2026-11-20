% Mentor studies of channel limits, DD handoff, and mixed precision.
clear; close all;
run(fullfile(fileparts(mfilename('fullpath')), '..', 'config.m'));

fprintf('Experiment 5: Mentor studies%s', newline);

fig_dir = REPORT_DIR;

%% A. Noise-free channel and practical equalizer length
N_a = 4000;
bits_a = generate_bits(N_a * k, RNG_SEED + 301);
[s_a, ~] = qam_mapper(bits_a, M);
h_cases = { [0 1 0], [1 0.5] / norm([1 0.5]), H_ISI };
h_names = {'Pure delay', 'Two-path', 'Three-tap dispersive'};
tap_candidates = [1 3 5 7 9 11];
evm_a = nan(numel(h_cases), numel(tap_candidates));
best_delay_a = nan(numel(h_cases), numel(tap_candidates));

for c = 1:numel(h_cases)
    h_c = h_cases{c};
    r_c = apply_fir_channel(s_a, h_c);
    for t = 1:numel(tap_candidates)
        n_eq = tap_candidates(t);
        delays = 0:(n_eq + length(h_c) - 2);
        for d = delays
            w_c = design_zf_equalizer(h_c, n_eq, d);
            y_c = align_and_trim(apply_fir_equalizer(r_c, w_c), N_a, d);
            candidate_evm = compute_evm(s_a, y_c);
            if isnan(evm_a(c,t)) || candidate_evm < evm_a(c,t)
                evm_a(c,t) = candidate_evm;
                best_delay_a(c,t) = d;
            end
        end
    end
end

fig19 = figure('Theme', 'light', 'Name', 'fig19_noisefree_channel_and_delay_study', ...
    'NumberTitle', 'off', 'Color', 'w', 'Position', [100 100 1100 760]);
tiledlayout(fig19, 2, 2, 'TileSpacing', 'compact', 'Padding', 'compact');
nexttile; hold on;
for c = 1:numel(h_cases)
    stem(0:length(h_cases{c})-1, h_cases{c}, 'LineWidth', 1.5, ...
        'DisplayName', h_names{c});
end
grid on; xlabel('Channel tap index'); ylabel('Amplitude');
title('Channel models used in the noise-free study'); legend('Location','northeast');
nexttile;
semilogy(tap_candidates, max(evm_a, 1e-8).', 'LineWidth', 1.5);
grid on; xlabel('Equalizer length (taps)'); ylabel('Minimum EVM (%)');
title('Minimum practical EVM versus equalizer length');
legend(h_names, 'Location', 'southwest');
nexttile;
plot(tap_candidates, best_delay_a.', 'o-', 'LineWidth', 1.5);
grid on; xlabel('Equalizer length (taps)'); ylabel('Selected delay');
title('Delay selected by least-squares evaluation');
legend(h_names, 'Location', 'best');
nexttile;
bar(categorical(h_names), evm_a(:, tap_candidates == 9));
grid on; ylabel('Minimum EVM (%)');
title('Reference comparison at nine taps');
if EXPORT_FIGS
    format_report_figure(fig19);
    export_fig(fig19, fig_dir, 'fig19_noisefree_channel_and_delay_study', FIG_RES);
end

%% B. Low-SNR LMS tap-length sensitivity
tap_b = [3 5 7 9 11 15];
snr_b = [10 12 14 22];
N_b = 7000;
bits_b = generate_bits(N_b * k, RNG_SEED + 302);
[s_b, ~] = qam_mapper(bits_b, M);
r_b_clean = apply_fir_channel(s_b, H_ISI);
evm_b = zeros(numel(snr_b), numel(tap_b));
ber_b = zeros(numel(snr_b), numel(tap_b));
T_double = lms_types('double');
for si = 1:numel(snr_b)
    r_b = add_awgn(r_b_clean, snr_b(si) + 10*log10(k));
    for ti = 1:numel(tap_b)
        d_b = floor((tap_b(ti)-1)/2);
        [y_b, ~, ~, ~] = lms_core(r_b, s_b, LMS_MU, tap_b(ti), LMS_N_TRAIN, d_b, T_double);
        pay = LMS_N_TRAIN+1:N_b;
        evm_b(si,ti) = compute_evm(s_b(pay), y_b(pay));
        [ber_b(si,ti), ~] = compute_ber_ser(bits_b(LMS_N_TRAIN*k+1:end), ...
            qam_demapper(y_b(pay), M), k);
    end
end

fig20 = figure('Theme', 'light', 'Name', 'fig20_low_snr_tap_length_sweep', ...
    'NumberTitle', 'off', 'Color', 'w', 'Position', [100 100 1050 700]);
tiledlayout(fig20, 2, 2, 'TileSpacing', 'compact', 'Padding', 'compact');
nexttile; plot(tap_b, evm_b.', 'o-', 'LineWidth', 1.5); grid on;
xlabel('Equalizer length (taps)'); ylabel('EVM (%)'); title('EVM versus length');
legend(strcat(string(snr_b), ' dB'), 'Location', 'best');
nexttile; semilogy(tap_b, max(ber_b, 1e-7).', 's-', 'LineWidth', 1.5); grid on;
xlabel('Equalizer length (taps)'); ylabel('BER'); title('BER versus length');
legend(strcat(string(snr_b), ' dB'), 'Location', 'best');
nexttile; plot(tap_b, evm_b(1:3,:).', 'o-', 'LineWidth', 1.5); grid on;
xlabel('Equalizer length (taps)'); ylabel('EVM (%)'); title('Low-SNR detail');
legend(strcat(string(snr_b(1:3)), ' dB'), 'Location', 'best');
nexttile; bar(categorical(strcat(string(snr_b), ' dB')), evm_b(:, tap_b == 9));
grid on; ylabel('EVM (%)'); title('Existing nine-tap baseline');
if EXPORT_FIGS
    format_report_figure(fig20);
    export_fig(fig20, fig_dir, 'fig20_low_snr_tap_length_sweep', FIG_RES);
end

%% C. Training to decision-directed transition
snr_c = [10 12 14 22];
N_c = 4000;
bits_c = generate_bits(N_c * k, RNG_SEED + 303);
[s_c, ~] = qam_mapper(bits_c, M);
r_c_clean = apply_fir_channel(s_c, H_ISI);
mse_c = zeros(numel(snr_c), N_c);
for si = 1:numel(snr_c)
    r_c = add_awgn(r_c_clean, snr_c(si) + 10*log10(k));
    [~, ~, ~, e_c] = lms_core(r_c, s_c, LMS_MU, LMS_N_EQ, LMS_N_TRAIN, LMS_DELAY, T_double);
    mse_c(si,:) = e_c(1:N_c).';
end
fig21 = figure('Theme', 'light', 'Name', 'fig21_lms_training_dd_transition', ...
    'NumberTitle', 'off', 'Color', 'w', 'Position', [100 100 1100 760]);
tiledlayout(fig21, 2, 2, 'TileSpacing', 'compact', 'Padding', 'compact');
for si = 1:numel(snr_c)
    nexttile; hold on;
    plot(1:N_c, mse_c(si,:), 'Color', [0.75 0.75 0.75], 'LineWidth', 0.5);
    plot(movmean(mse_c(si,:), 15), 'b', 'LineWidth', 1.2);
    plot(filter(0.3, [1 -0.7], mse_c(si,:)), 'r', 'LineWidth', 1.0);
    xline(LMS_N_TRAIN + LMS_DELAY, 'k--', 'LineWidth', 1.0);
    set(gca, 'YScale', 'log'); grid on;
    xlabel('Symbol index'); ylabel('Instantaneous squared error');
    title(sprintf('E_b/N_0 = %d dB', snr_c(si)));
    if si == 1; legend('Raw', '15-symbol mean', 'alpha = 0.70', 'DD switch', ...
            'Location', 'best'); end
end
if EXPORT_FIGS
    format_report_figure(fig21);
    export_fig(fig21, fig_dir, 'fig21_lms_training_dd_transition', FIG_RES);
end

%% D. Read the measured word-length sweep and choose the datapath width
result_file = fullfile(projectRoot, 'results', 'wordlength_results.mat');
if ~exist(result_file, 'file')
    error('Run exp3_fixedpoint_wordlength_study.m before exp5_mentor_study.m.');
end
R = load(result_file);
valid = R.word_evm <= 8 & R.word_ber <= 1e-3;
if any(valid)
    best_datapath_bits = min(R.word_lengths(valid));
else
    error('exp5:NoQualifiedDatapath', ...
        'No measured width passes EVM <= 8%% and BER <= 1e-3.');
end

fig22 = figure('Theme', 'light', 'Name', 'fig22_full_wordlength_sqnr_sweep', ...
    'NumberTitle', 'off', 'Color', 'w', 'Position', [100 100 1000 480]);
tiledlayout(fig22, 1, 2, 'TileSpacing', 'compact', 'Padding', 'compact');
nexttile; plot(R.word_lengths, R.word_evm, 'o-', 'LineWidth', 1.5, ...
    'Color', [0.00 0.45 0.74], 'MarkerFaceColor', [0.00 0.45 0.74]);
grid on; xlabel('Datapath word length (bits)'); ylabel('EVM (%) at 22 dB');
title('Measured EVM sweep');
nexttile; plot(R.word_lengths, R.word_sqnr, 's-', 'LineWidth', 1.5, ...
    'Color', [0.85 0.33 0.10], 'MarkerFaceColor', [0.85 0.33 0.10]);
grid on; xlabel('Datapath word length (bits)'); ylabel('Measured SQNR (dB)');
title('Measured SQNR sweep');
if EXPORT_FIGS
    format_report_figure(fig22);
    export_fig(fig22, fig_dir, 'fig22_full_wordlength_sqnr_sweep', FIG_RES);
end

%% E. Three-architecture mixed-precision comparison
N_e = 6000;
bits_e = generate_bits(N_e * k, RNG_SEED + 304);
[s_e, ~] = qam_mapper(bits_e, M);
r_e = add_awgn(apply_fir_channel(s_e, H_ISI), SNR_REF_DB + 10*log10(k));
arch_names = {'Full 8-bit', ...
    sprintf('%d-bit datapath + 16-bit update', best_datapath_bits), ...
    sprintf('%d-bit datapath + 24-bit update', best_datapath_bits)};
arch_data_bits = [8 best_datapath_bits best_datapath_bits];
arch_acc_bits = [8 16 24];
arch_evm = zeros(1,3); arch_ber = zeros(1,3); arch_stalls = zeros(1,3);
arch_mse = zeros(3,N_e);
pay_e = LMS_N_TRAIN+1:N_e;
for ai = 1:3
    [y_e, e_e, stalls_e] = mixed_precision_lms(r_e, s_e, ...
        LMS_MU, LMS_N_EQ, LMS_N_TRAIN, LMS_DELAY, arch_data_bits(ai), arch_acc_bits(ai));
    arch_evm(ai) = compute_evm(s_e(pay_e), y_e(pay_e));
    [arch_ber(ai), ~] = compute_ber_ser(bits_e(LMS_N_TRAIN*k+1:end), ...
        qam_demapper(y_e(pay_e), M), k);
    arch_mse(ai,:) = e_e(1:N_e).';
    arch_stalls(ai) = stalls_e;
end

% Width-squared scaling is only a first-order datapath estimate.  It is not
% a synthesis result and excludes routing, memory, clocking, and control.
area_est = (arch_data_bits / 16).^2;
area_saving_est = (1 - area_est) * 100;
arch_short = {'Full 8-bit', sprintf('%d-bit + 16-bit', best_datapath_bits), ...
    sprintf('%d-bit + 24-bit', best_datapath_bits)};
fig23 = figure('Theme', 'light', 'Name', 'fig23_mixed_precision_lms_comparison', ...
    'NumberTitle', 'off', 'Color', 'w', 'Position', [100 100 1100 760]);
tiledlayout(fig23, 2, 2, 'TileSpacing', 'compact', 'Padding', 'compact');
nexttile; semilogy(1:N_e, max(arch_mse, 1e-8).', 'LineWidth', 1.6); grid on;
xlabel('Symbol index'); ylabel('Instantaneous squared error');
title('Learning behavior'); legend(arch_names, 'Location', 'best');
nexttile; bar(1:3, arch_evm); grid on;
ylabel('EVM (%) at 22 dB'); title('Measured EVM');
set(gca, 'XTick', 1:3, 'XTickLabel', arch_short);
nexttile; bar(1:3, area_saving_est); grid on;
ylabel('Estimated datapath reduction (%)');
title('First-order width-squared estimate'); set(gca, 'XTick', 1:3, 'XTickLabel', arch_short);
nexttile; yyaxis left; bar(1:3, max(arch_ber, 1e-8)); set(gca, 'YScale', 'log');
ylabel('BER'); yyaxis right; plot(1:3, arch_stalls, 'ko-', 'LineWidth', 1.6, ...
    'MarkerFaceColor', [0.85 0.33 0.10]); ylabel('Update-stall events'); grid on;
title('BER and update stalls'); set(gca, 'XTick', 1:3, 'XTickLabel', arch_short);
if EXPORT_FIGS
    format_report_figure(fig23);
    export_fig(fig23, fig_dir, 'fig23_mixed_precision_lms_comparison', FIG_RES);
end

fprintf('Experiment 5 complete.%s', newline);

function [y_out, e_hist, stalls] = mixed_precision_lms(r_in, s_train, mu, N_eq, N_train, delay, data_bits, acc_bits)
% Quantized datapath with a wider internal weight/update accumulator.
N_rx = length(r_in); N_tx = length(s_train);
if N_rx < N_tx + delay
    r_in = [r_in; zeros(N_tx + delay - N_rx, 1)];
    N_rx = length(r_in);
end
y_raw = zeros(N_rx,1); e_hist = zeros(N_rx,1);
w_acc = complex(zeros(N_eq,1)); x = complex(zeros(N_eq,1)); stalls = 0;
for n = 1:N_rx
    x(2:end) = x(1:end-1); x(1) = qx(r_in(n), data_bits);
    w_data = qx(w_acc, data_bits);
    y = qx(sum(conj(w_data).*x), data_bits); y_raw(n) = y;
    tx_idx = n - delay;
    if tx_idx >= 1 && tx_idx <= N_tx
        if tx_idx <= N_train
            d = qx(s_train(tx_idx), data_bits);
        else
            scaled = [real(y), imag(y)] * sqrt(42);
            clipped = min(max(scaled, -7), 7);
            decisions = 2*round((clipped-1)/2) + 1;
            d = qx(complex(decisions(1), decisions(2))/sqrt(42), data_bits);
        end
        err = qx(d-y, data_bits);
        grad = qx(x.*conj(err), acc_bits);
        delta = qx(mu*grad, acc_bits);
        w_new = qx(w_acc + delta, acc_bits);
        stalls = stalls + sum(abs(qx(w_new, data_bits)-qx(w_acc, data_bits)) == 0);
        w_acc = w_new; e_hist(n) = abs(err)^2;
    end
end
y_out = align_and_trim(y_raw, N_tx, delay);
end

function y = qx(x, bits)
% Quantize at a register boundary, including complex components.
frac = max(1, bits - 2);
y = double(fi(double(x), 1, bits, frac, ...
    'RoundingMethod', 'Nearest', 'OverflowAction', 'Saturate'));
end

function format_report_figure(fig)
set(fig, 'Color', 'w');
axes_list = findall(fig, 'Type', 'axes');
for ax = axes_list(:).'
    set(ax, 'Color', 'w', 'XColor', [0.15 0.15 0.15], ...
        'YColor', [0.15 0.15 0.15], 'GridColor', [0.75 0.75 0.75], ...
        'GridAlpha', 0.4, 'MinorGridColor', [0.85 0.85 0.85], ...
        'MinorGridAlpha', 0.25, 'LineWidth', 1.1, ...
        'FontName', 'Helvetica', 'FontSize', 10);
    ax.YMinorGrid = 'on';
    set(get(ax, 'Title'), 'FontName', 'Helvetica', 'FontSize', 11, ...
        'FontWeight', 'bold', 'Color', [0.05 0.05 0.05]);
    set(get(ax, 'XLabel'), 'FontName', 'Helvetica', 'FontSize', 11, ...
        'FontWeight', 'bold', 'Color', [0.1 0.1 0.1]);
    set(get(ax, 'YLabel'), 'FontName', 'Helvetica', 'FontSize', 11, ...
        'FontWeight', 'bold', 'Color', [0.1 0.1 0.1]);
end
text_list = findall(fig, 'Type', 'text');
for tx = text_list(:).'
    set(tx, 'Color', [0.1 0.1 0.1]);
end
legend_list = findall(fig, 'Type', 'legend');
for lg = legend_list(:).'
    set(lg, 'Color', [1 1 1], 'TextColor', [0 0 0], ...
        'EdgeColor', [0.8 0.8 0.8], 'FontName', 'Helvetica', 'FontSize', 10);
end
end
