function fig = plot_channel_response(h, fig_tag)
% Plot the channel taps and frequency response.

    if nargin < 2 || isempty(fig_tag)
        fig_tag = 'fig_channel_response';
    end

    h = h(:);
    L = length(h);
    n_vec = 0:(L - 1);

    N_fft = 1024;
    w = linspace(0, pi, N_fft);
    H = freqz(h, 1, w);
    f_norm = w / (2 * pi);          % Normalized frequency: 0 to 0.5 (f / Fs)
    H_mag_dB = 20 * log10(abs(H));  % Magnitude in dB

    fig = figure('Name', fig_tag, 'NumberTitle', 'off', 'Color', 'w', ...
                 'Position', [100, 100, 850, 380]);

    subplot(1, 2, 1);
    ax1 = gca;
    stem(ax1, n_vec, h, 'filled', 'LineWidth', 1.8, 'MarkerSize', 7, ...
         'Color', [0.00 0.45 0.85], 'MarkerFaceColor', [0.00 0.20 0.50]);
    hold(ax1, 'on');

    for idx = 1:L
        text(ax1, n_vec(idx), h(idx) + 0.07 * sign(h(idx)), ...
             sprintf('h[%d] = %.4f', n_vec(idx), h(idx)), ...
             'HorizontalAlignment', 'center', 'FontSize', 9.5, ...
             'FontWeight', 'bold', 'Color', [0.15 0.15 0.15]);
    end

    set(ax1, 'Color', [1 1 1], ...
             'XColor', [0.15 0.15 0.15], ...
             'YColor', [0.15 0.15 0.15], ...
             'LineWidth', 1.1, ...
             'FontSize', 10, ...
             'FontName', 'Helvetica');

    xlabel(ax1, 'Tap Index (Delay in T_s)', 'FontSize', 11, 'FontWeight', 'bold', 'Color', [0.1 0.1 0.1]);
    ylabel(ax1, 'Tap Amplitude', 'FontSize', 11, 'FontWeight', 'bold', 'Color', [0.1 0.1 0.1]);
    title(ax1, sprintf('Channel Impulse Response h[n]\n||h||_2 = %.4f (Unit Energy)', norm(h)), ...
          'FontSize', 11, 'FontWeight', 'bold', 'Color', [0.05 0.05 0.05]);

    grid(ax1, 'on');
    set(ax1, 'GridColor', [0.75 0.75 0.75], 'GridAlpha', 0.4);
    box(ax1, 'on');
    xlim(ax1, [-0.5, L - 0.5]);
    ylim(ax1, [0, max(h) * 1.30]);
    set(ax1, 'XTick', n_vec);

    subplot(1, 2, 2);
    ax2 = gca;
    plot(ax2, f_norm, H_mag_dB, 'LineWidth', 2.0, 'Color', [0.85 0.20 0.10]);
    hold(ax2, 'on');

    plot(ax2, 0, H_mag_dB(1), 'ko', 'MarkerFaceColor', [0.1 0.1 0.1], 'MarkerSize', 6);
    text(ax2, 0.02, H_mag_dB(1), sprintf('DC: %+.2f dB', H_mag_dB(1)), ...
         'FontSize', 9.5, 'FontWeight', 'bold', 'Color', [0.1 0.1 0.1]);

    plot(ax2, 0.5, H_mag_dB(end), 'ko', 'MarkerFaceColor', [0.1 0.1 0.1], 'MarkerSize', 6);
    text(ax2, 0.33, H_mag_dB(end) - 0.4, sprintf('Nyquist: %.2f dB', H_mag_dB(end)), ...
         'FontSize', 9.5, 'FontWeight', 'bold', 'Color', [0.1 0.1 0.1]);

    gain_difference = H_mag_dB(1) - H_mag_dB(end);
    text(ax2, 0.18, (H_mag_dB(1) + H_mag_dB(end))/2, sprintf('DC-Nyquist: %.2f dB', gain_difference), ...
         'FontSize', 10, 'FontWeight', 'bold', 'Color', [0.75 0.10 0.10]);

    set(ax2, 'Color', [1 1 1], ...
             'XColor', [0.15 0.15 0.15], ...
             'YColor', [0.15 0.15 0.15], ...
             'LineWidth', 1.1, ...
             'FontSize', 10, ...
             'FontName', 'Helvetica');

    xlabel(ax2, 'Normalized Frequency (f / F_s)', 'FontSize', 11, 'FontWeight', 'bold', 'Color', [0.1 0.1 0.1]);
    ylabel(ax2, 'Magnitude |H(f)| (dB)', 'FontSize', 11, 'FontWeight', 'bold', 'Color', [0.1 0.1 0.1]);
    title(ax2, sprintf('Channel Frequency Response |H(e^{j\\omega})|\nDC-to-Nyquist Difference: %.2f dB', gain_difference), ...
          'FontSize', 11, 'FontWeight', 'bold', 'Color', [0.05 0.05 0.05]);

    grid(ax2, 'on');
    set(ax2, 'GridColor', [0.75 0.75 0.75], 'GridAlpha', 0.4);
    box(ax2, 'on');
    xlim(ax2, [0, 0.5]);
    ylim(ax2, [floor(min(H_mag_dB)) - 1, ceil(max(H_mag_dB)) + 1]);
end
