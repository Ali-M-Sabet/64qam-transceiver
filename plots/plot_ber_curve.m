function fig = plot_ber_curve(EbN0_dB_vec, BER_cell, legend_strs, title_str, fig_tag)
% Plot the BER curves on logarithmic axes.

    STYLES = {
        'b-o', [0.00 0.45 0.85], 6, 1.6;
        'r--', [0.85 0.20 0.10], 0, 1.8;
        'g-s', [0.15 0.70 0.30], 6, 1.6;
        'm-^', [0.75 0.10 0.75], 6, 1.6;
        'k-d', [0.20 0.20 0.20], 6, 1.6;
        'c-v', [0.00 0.55 0.65], 6, 1.6;
    };

    fig = figure('Name', fig_tag, 'NumberTitle', 'off', 'Color', 'w', ...
                 'Position', [100, 100, 720, 540]);
    ax = gca;
    hold(ax, 'on');

    set(ax, 'YScale', 'log', ...
            'Color', [1 1 1], ...
            'XColor', [0.15 0.15 0.15], ...
            'YColor', [0.15 0.15 0.15], ...
            'LineWidth', 1.1, ...
            'FontSize', 10, ...
            'FontName', 'Helvetica');

    for c = 1:length(BER_cell)
        ber_raw  = BER_cell{c};
        ber_plot = ber_raw;
        ber_plot(ber_plot <= 0) = NaN; % Prevent log scale break on exact zero

        style_spec = STYLES{mod(c-1, size(STYLES,1)) + 1, 1};
        color_spec = STYLES{mod(c-1, size(STYLES,1)) + 1, 2};
        msize      = STYLES{mod(c-1, size(STYLES,1)) + 1, 3};
        lwidth     = STYLES{mod(c-1, size(STYLES,1)) + 1, 4};

        if msize > 0
            semilogy(ax, EbN0_dB_vec, ber_plot, style_spec, ...
                'Color', color_spec, 'LineWidth', lwidth, ...
                'MarkerSize', msize, 'MarkerFaceColor', color_spec, ...
                'DisplayName', legend_strs{c});
        else
            semilogy(ax, EbN0_dB_vec, ber_plot, style_spec, ...
                'Color', color_spec, 'LineWidth', lwidth, ...
                'DisplayName', legend_strs{c});
        end
    end

    xlabel(ax, 'E_b/N_0 (dB)', 'FontSize', 11, 'FontWeight', 'bold', 'Color', [0.1 0.1 0.1]);
    ylabel(ax, 'Bit Error Rate (BER)', 'FontSize', 11, 'FontWeight', 'bold', 'Color', [0.1 0.1 0.1]);
    title(ax, title_str, 'FontSize', 11, 'FontWeight', 'bold', 'Color', [0.05 0.05 0.05]);

    set(ax, 'YScale', 'log');
    ylim(ax, [1e-6, 1]);
    xlim(ax, [min(EbN0_dB_vec) - 0.5, max(EbN0_dB_vec) + 0.5]);
    set(ax, 'YTick', 10.^(-6:0));

    grid(ax, 'on');
    set(ax, 'GridColor', [0.75 0.75 0.75], 'GridAlpha', 0.4, ...
            'MinorGridColor', [0.85 0.85 0.85], 'MinorGridAlpha', 0.25);
    ax.YMinorGrid = 'on';

    box(ax, 'on');
    lgd = legend(ax, 'Location', 'southwest', 'FontSize', 10, 'Box', 'on', ...
                 'Color', [1 1 1], 'EdgeColor', [0.8 0.8 0.8]);
    set(lgd, 'TextColor', [0 0 0]);
end
