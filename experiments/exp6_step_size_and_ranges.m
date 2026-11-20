% Step-size comparison and ranges at the LMS register casts.
clear; close all;
run(fullfile(fileparts(mfilename('fullpath')), '..', 'config.m'));
output_dir = fullfile(projectRoot, 'results');
if ~isfolder(output_dir), mkdir(output_dir); end
fprintf('Experiment 6: Step size and ranges\n');

mu_values = [0.005, 0.01, 0.02, 0.04];
mu_snr = [14, 22];
mu_seeds = [42, 100, 2026];
mu_symbols = 20000;
mu_payload_bits = (mu_symbols - LMS_N_TRAIN) * k;
mu_ber = zeros(numel(mu_values), numel(mu_snr), numel(mu_seeds));
mu_evm = zeros(size(mu_ber));
mu_tail_mse = zeros(size(mu_ber));
learning_mse = zeros(mu_symbols, numel(mu_values), numel(mu_snr));
rows = zeros(numel(mu_ber), 7);
row = 0;
T_double = lms_types('double');
payload = LMS_N_TRAIN + 1 : mu_symbols;

for seed_index = 1:numel(mu_seeds)
    bits = generate_bits(mu_symbols * k, mu_seeds(seed_index));
    symbols = qam_mapper(bits, M);
    received = apply_fir_channel(symbols, H_ISI);
    for snr_index = 1:numel(mu_snr)
        noisy = add_awgn(received, mu_snr(snr_index) + 10*log10(k));
        for mu_index = 1:numel(mu_values)
            y = lms_core(noisy, symbols, mu_values(mu_index), ...
                LMS_N_EQ, LMS_N_TRAIN, LMS_DELAY, T_double);
            detected = qam_demapper(y(payload), M);
            mu_ber(mu_index,snr_index,seed_index) = compute_ber_ser( ...
                bits(LMS_N_TRAIN*k + 1:end), detected, k);
            mu_evm(mu_index,snr_index,seed_index) = compute_evm(symbols(payload), y(payload));
            true_error = abs(y - symbols).^2;
            mu_tail_mse(mu_index,snr_index,seed_index) = ...
                compute_mse(symbols(end-4999:end), y(end-4999:end));
            learning_mse(:,mu_index,snr_index) = learning_mse(:,mu_index,snr_index) + ...
                movmean(true_error, [99, 0]) / numel(mu_seeds);
            row = row + 1;
            rows(row,:) = [mu_seeds(seed_index), mu_snr(snr_index), mu_values(mu_index), ...
                mu_payload_bits, mu_ber(mu_index,snr_index,seed_index), ...
                mu_evm(mu_index,snr_index,seed_index), mu_tail_mse(mu_index,snr_index,seed_index)];
        end
    end
end
step_table = array2table(rows, 'VariableNames', ...
    {'Seed','EbN0_dB','Mu','PayloadBits','BER','EVM_percent','Last5000MSE'});
writetable(step_table, fullfile(output_dir, 'step_size_sweep.csv'));

fig = figure('Theme', 'light', 'Color', 'w', 'Position', [100, 100, 1100, 750]);
tiledlayout(2, 2, 'TileSpacing', 'compact');
labels = compose('mu = %.3f', mu_values);
for snr_index = 1:numel(mu_snr)
    nexttile;
    semilogy(1:mu_symbols, learning_mse(:,:,snr_index), 'LineWidth', 1);
    xline(LMS_N_TRAIN, '--', 'DD start', 'HandleVisibility', 'off');
    grid on;
    xlabel('Aligned symbol index'); ylabel('Known-symbol MSE');
    title(sprintf('%d dB: 100-symbol smoothing, three-seed mean', mu_snr(snr_index)));
    legend(labels, 'Location', 'northeast');
end
nexttile;
plot(mu_values, mean(mu_evm, 3), '-o', 'LineWidth', 1.2);
grid on; xlabel('Step size'); ylabel('Mean payload EVM (%)');
legend(compose('%d dB', mu_snr), 'Location', 'northwest');
nexttile;
semilogy(mu_values, mean(mu_tail_mse, 3), '-o', 'LineWidth', 1.2);
grid on; xlabel('Step size'); ylabel('Mean last-5000-symbol MSE');
legend(compose('%d dB', mu_snr), 'Location', 'northwest');
if EXPORT_FIGS
    export_fig(fig, REPORT_DIR, 'fig24_lms_step_size_sweep', FIG_RES);
end

range_signals = {'r'; 's_train'; 'mu'; 'scale_factor'; 'inv_scale'; 'x'; ...
    'y_hat'; 'd'; 'err'; 'grad'; 'update_vec'; 'w_next'; 'w'};
range_modes = {'double', '16-bit', '14-bit', '12-bit', '10-bit', '8-bit'};
range_widths = [64, 16, 14, 12, 10, 8];
range_snr = [14, 22];
range_seed = 44;
range_symbols = 2000;
range_runs = numel(range_modes) * numel(range_snr);
range_values = zeros(13, 7, range_runs);
range_formats = NaN(13, 2, range_runs);
range_tables = cell(range_runs, 1);
bits = generate_bits(range_symbols * k, range_seed);
symbols = qam_mapper(bits, M);
received = apply_fir_channel(symbols, H_ISI);
run_index = 0;
for snr_index = 1:numel(range_snr)
    noisy = add_awgn(received, range_snr(snr_index) + 10*log10(k));
    for mode_index = 1:numel(range_modes)
        if mode_index == 1
            T = T_double;
        else
            T = lms_types('FxPt', range_widths(mode_index));
        end
        [~, ~, ~, ~, measured] = lms_core(noisy, symbols, LMS_MU, ...
            LMS_N_EQ, LMS_N_TRAIN, LMS_DELAY, T);
        run_index = run_index + 1;
        formats = [64*ones(13,1), NaN(13,1)];
        if mode_index > 1
            for signal_index = 1:numel(range_signals)
                prototype = T.(range_signals{signal_index});
                formats(signal_index,:) = [prototype.WordLength, prototype.FractionLength];
            end
        end
        range_values(:,:,run_index) = measured;
        range_formats(:,:,run_index) = formats;
        range_tables{run_index} = [table(repmat(range_modes(mode_index),13,1), ...
            repmat(range_snr(snr_index),13,1), repmat(range_seed,13,1), ...
            repmat(range_symbols,13,1), range_signals, ...
            'VariableNames', {'Mode','EbN0_dB','Seed','Symbols','Signal'}), ...
            array2table([formats, measured], 'VariableNames', ...
            {'WordLength','FractionLength','InputMin','InputMax','StoredMin','StoredMax', ...
             'Components','LowSaturations','HighSaturations'})];
    end
end
range_table = vertcat(range_tables{:});
writetable(range_table, fullfile(output_dir, 'lms_ranges.csv'));
save(fullfile(output_dir, 'step_size_and_ranges.mat'), ...
    'mu_values','mu_snr','mu_seeds','mu_symbols','mu_payload_bits', ...
    'mu_ber','mu_evm','mu_tail_mse','learning_mse', ...
    'range_signals','range_modes','range_widths','range_snr','range_seed', ...
    'range_symbols','range_values','range_formats');
fprintf('Step-size sweep: %d runs, %d payload bits per run.\n', height(step_table), mu_payload_bits);
fprintf('Range report: 13 cast boundaries, %d runs of %d symbols.\n', range_runs, range_symbols);
