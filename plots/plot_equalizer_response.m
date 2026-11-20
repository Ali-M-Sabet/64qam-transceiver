function fig = plot_equalizer_response(h, w_zf, w_mmse, fig_tag)
% Plot the equalizer taps and frequency responses.

    if nargin < 4 || isempty(fig_tag)
        fig_tag = 'fig_equalizer_responses';
    end

    N_eq  = length(w_zf);
    n_vec = 0:(N_eq - 1);
    delay = floor((N_eq - 1) / 2);
    N_fft = 1024;

    [H_ch, w]   = freqz(h, 1, N_fft);
    [W_zf, ~]   = freqz(w_zf, 1, N_fft);

    f_norm     = w / (2 * pi);                     % 0 to 0.5 (f / Fs)
    H_mag_dB   = 20 * log10(abs(H_ch));
    W_zf_dB    = 20 * log10(abs(W_zf));
    Comb_zf_dB = H_mag_dB + W_zf_dB;               % Combined response H * W_zf

    fig = figure('Name', fig_tag, 'NumberTitle', 'off', 'Color', 'w', ...
                 'Position', [100, 100, 950, 420]);

    subplot(1, 2, 1);
    ax1 = gca;
    stem(ax1, n_vec - 0.12, w_zf, 'filled', 'LineWidth', 1.6, 'MarkerSize', 6, ...
         'Color', [0.00 0.45 0.85], 'MarkerFaceColor', [0.00 0.45 0.85], ...
         'DisplayName', sprintf('ZF (||w|| = %.3f)', norm(w_zf)));
    hold(ax1, 'on');
    stem(ax1, n_vec + 0.12, w_mmse, 'filled', 'LineWidth', 1.6, 'MarkerSize', 6, ...
         'Color', [0.85 0.33 0.10], 'MarkerFaceColor', [0.85 0.33 0.10], ...
         'DisplayName', sprintf('MMSE (||w|| = %.3f)', norm(w_mmse)));

    set(ax1, 'Color', [1 1 1], ...
             'XColor', [0.15 0.15 0.15], ...
             'YColor', [0.15 0.15 0.15], ...
             'LineWidth', 1.1, ...
             'FontSize', 10, ...
             'FontName', 'Helvetica');

    xlabel(ax1, 'Equalizer Tap Index k', 'FontSize', 11, 'FontWeight', 'bold', 'Color', [0.1 0.1 0.1]);
    ylabel(ax1, 'Filter Weight w[k]', 'FontSize', 11, 'FontWeight', 'bold', 'Color', [0.1 0.1 0.1]);
    title(ax1, sprintf('Equalizer Impulse Responses (N_{eq} = %d, D = %d)\nPrecursor & Postcursor Cancellation', N_eq, delay), ...
          'FontSize', 11, 'FontWeight', 'bold', 'Color', [0.05 0.05 0.05]);

    grid(ax1, 'on');
    set(ax1, 'GridColor', [0.75 0.75 0.75], 'GridAlpha', 0.4);
    box(ax1, 'on');
    xlim(ax1, [-0.5, N_eq - 0.5]);
    lgd1 = legend(ax1, 'Location', 'northeast', 'FontSize', 9.5, 'Color', 'w', 'EdgeColor', [0.8 0.8 0.8]);
    set(lgd1, 'TextColor', [0 0 0]);

    subplot(1, 2, 2);
    ax2 = gca;
    plot(ax2, f_norm, H_mag_dB, 'LineWidth', 2.0, 'Color', [0.85 0.20 0.10], ...
         'DisplayName', 'Channel |H(f)| (Ripple)');
    hold(ax2, 'on');
    plot(ax2, f_norm, W_zf_dB, '--', 'LineWidth', 2.0, 'Color', [0.00 0.45 0.85], ...
         'DisplayName', 'ZF Equalizer |W_{ZF}(f)| (Inverse)');
    plot(ax2, f_norm, Comb_zf_dB, 'k-', 'LineWidth', 2.2, ...
         'DisplayName', 'Combined |H(f) \cdot W_{ZF}(f)| (Near 0 dB)');

    set(ax2, 'Color', [1 1 1], ...
             'XColor', [0.15 0.15 0.15], ...
             'YColor', [0.15 0.15 0.15], ...
             'LineWidth', 1.1, ...
             'FontSize', 10, ...
             'FontName', 'Helvetica');

    xlabel(ax2, 'Normalized Frequency (f / F_s)', 'FontSize', 11, 'FontWeight', 'bold', 'Color', [0.1 0.1 0.1]);
    ylabel(ax2, 'Magnitude (dB)', 'FontSize', 11, 'FontWeight', 'bold', 'Color', [0.1 0.1 0.1]);
    title(ax2, sprintf('Channel Inversion & Spectral Flattening\nCombined Response Near 0 dB'), ...
          'FontSize', 11, 'FontWeight', 'bold', 'Color', [0.05 0.05 0.05]);

    grid(ax2, 'on');
    set(ax2, 'GridColor', [0.75 0.75 0.75], 'GridAlpha', 0.4);
    box(ax2, 'on');
    xlim(ax2, [0, 0.5]);
    ylim(ax2, [-6, 6]);
    lgd2 = legend(ax2, 'Location', 'southwest', 'FontSize', 9.5, 'Color', 'w', 'EdgeColor', [0.8 0.8 0.8]);
    set(lgd2, 'TextColor', [0 0 0]);
end
