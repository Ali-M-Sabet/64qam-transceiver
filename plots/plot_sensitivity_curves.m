function [fig_tap, fig_mismatch] = plot_sensitivity_curves(tap_vec, evm_taps, ber_taps, err_pct_vec, evm_mismatch, ber_mismatch)
% Plot sensitivity to tap count and channel perturbations.

    fig_tap = figure('Name', 'fig09_tap_length_sensitivity', 'NumberTitle', 'off', ...
                     'Color', 'w', 'Position', [100, 100, 950, 420]);

    subplot(1, 2, 1);
    ax1 = gca;
    plot(ax1, tap_vec, evm_taps, 'b-o', 'LineWidth', 2.0, 'MarkerSize', 7, ...
         'MarkerFaceColor', [0.00 0.45 0.85], 'Color', [0.00 0.45 0.85], ...
         'DisplayName', 'Measured EVM');
    hold(ax1, 'on');
    xline(ax1, 9, '--r', 'LineWidth', 1.8, 'DisplayName', 'Baseline Design (9 Taps)');

    set(ax1, 'Color', 'w', 'XColor', [0.15 0.15 0.15], 'YColor', [0.15 0.15 0.15], ...
             'LineWidth', 1.1, 'FontSize', 10, 'FontName', 'Helvetica');
    xlabel(ax1, 'Equalizer Filter Length N_{eq} (Taps)', 'FontSize', 11, 'FontWeight', 'bold', 'Color', [0.1 0.1 0.1]);
    ylabel(ax1, 'RMS EVM (%)', 'FontSize', 11, 'FontWeight', 'bold', 'Color', [0.1 0.1 0.1]);
    title(ax1, sprintf('EVM vs. Equalizer Tap Length (E_b/N_0 = 22 dB)\nBaseline Design at N_{eq} = 9'), ...
          'FontSize', 11, 'FontWeight', 'bold', 'Color', [0.05 0.05 0.05]);
    grid(ax1, 'on'); set(ax1, 'GridColor', [0.75 0.75 0.75], 'GridAlpha', 0.4);
    box(ax1, 'on');
    lgd1 = legend(ax1, 'Location', 'northeast', 'Color', 'w', 'EdgeColor', [0.8 0.8 0.8]);
    set(lgd1, 'TextColor', [0 0 0]);

    subplot(1, 2, 2);
    ax2 = gca;
    semilogy(ax2, tap_vec, max(ber_taps, 1e-7), 'r-s', 'LineWidth', 2.0, 'MarkerSize', 7, ...
             'MarkerFaceColor', [0.85 0.20 0.10], 'Color', [0.85 0.20 0.10], ...
             'DisplayName', 'Measured BER');
    hold(ax2, 'on');
    xline(ax2, 9, '--k', 'LineWidth', 1.8, 'DisplayName', 'Baseline Design (9 Taps)');

    set(ax2, 'Color', 'w', 'XColor', [0.15 0.15 0.15], 'YColor', [0.15 0.15 0.15], ...
             'LineWidth', 1.1, 'FontSize', 10, 'FontName', 'Helvetica');
    xlabel(ax2, 'Equalizer Filter Length N_{eq} (Taps)', 'FontSize', 11, 'FontWeight', 'bold', 'Color', [0.1 0.1 0.1]);
    ylabel(ax2, 'Bit Error Rate (BER)', 'FontSize', 11, 'FontWeight', 'bold', 'Color', [0.1 0.1 0.1]);
    title(ax2, sprintf('BER vs. Equalizer Tap Length (E_b/N_0 = 22 dB)\nZero Counts Shown at Display Floor'), ...
          'FontSize', 11, 'FontWeight', 'bold', 'Color', [0.05 0.05 0.05]);
    grid(ax2, 'on'); set(ax2, 'GridColor', [0.75 0.75 0.75], 'GridAlpha', 0.4);
    box(ax2, 'on');
    lgd2 = legend(ax2, 'Location', 'northeast', 'Color', 'w', 'EdgeColor', [0.8 0.8 0.8]);
    set(lgd2, 'TextColor', [0 0 0]);

    fig_mismatch = figure('Name', 'fig10_channel_mismatch_sensitivity', 'NumberTitle', 'off', ...
                          'Color', 'w', 'Position', [150, 150, 950, 420]);

    subplot(1, 2, 1);
    ax3 = gca;
    plot(ax3, err_pct_vec, evm_mismatch, 'm-d', 'LineWidth', 2.0, 'MarkerSize', 7, ...
         'MarkerFaceColor', [0.70 0.10 0.70], 'Color', [0.70 0.10 0.70]);

    set(ax3, 'Color', 'w', 'XColor', [0.15 0.15 0.15], 'YColor', [0.15 0.15 0.15], ...
             'LineWidth', 1.1, 'FontSize', 10, 'FontName', 'Helvetica');
    xlabel(ax3, 'Echo Perturbation (%)', 'FontSize', 11, 'FontWeight', 'bold', 'Color', [0.1 0.1 0.1]);
    ylabel(ax3, 'RMS EVM (%)', 'FontSize', 11, 'FontWeight', 'bold', 'Color', [0.1 0.1 0.1]);
    title(ax3, sprintf('EVM vs. Echo Perturbation\n64-QAM at E_b/N_0 = 22 dB'), ...
          'FontSize', 11, 'FontWeight', 'bold', 'Color', [0.05 0.05 0.05]);
    grid(ax3, 'on'); set(ax3, 'GridColor', [0.75 0.75 0.75], 'GridAlpha', 0.4);
    box(ax3, 'on');

    subplot(1, 2, 2);
    ax4 = gca;
    semilogy(ax4, err_pct_vec, max(ber_mismatch, 1e-7), 'k-^', 'LineWidth', 2.0, 'MarkerSize', 7, ...
             'MarkerFaceColor', [0.15 0.15 0.15], 'Color', [0.15 0.15 0.15]);

    set(ax4, 'Color', 'w', 'XColor', [0.15 0.15 0.15], 'YColor', [0.15 0.15 0.15], ...
             'LineWidth', 1.1, 'FontSize', 10, 'FontName', 'Helvetica');
    xlabel(ax4, 'Echo Perturbation (%)', 'FontSize', 11, 'FontWeight', 'bold', 'Color', [0.1 0.1 0.1]);
    ylabel(ax4, 'Bit Error Rate (BER)', 'FontSize', 11, 'FontWeight', 'bold', 'Color', [0.1 0.1 0.1]);
    title(ax4, sprintf('BER vs. Echo Perturbation\nStructured Channel Mismatch'), ...
          'FontSize', 11, 'FontWeight', 'bold', 'Color', [0.05 0.05 0.05]);
    grid(ax4, 'on'); set(ax4, 'GridColor', [0.75 0.75 0.75], 'GridAlpha', 0.4);
    box(ax4, 'on');
end
