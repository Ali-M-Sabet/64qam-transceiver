function fig = plot_lms_learning(mse_hist, w_hist, N_train, mu, N_plot, fig_tag, delay)
% Plot LMS error and coefficient histories.

    if nargin < 5 || isempty(N_plot)
        N_plot = min(length(mse_hist), 6000);
    end
    if nargin < 6 || isempty(fig_tag)
        fig_tag = 'fig08_lms_learning_curve';
    end

    iter_vec = 1:N_plot;
    N_eq = size(w_hist, 1);
    if nargin < 7 || isempty(delay), delay = floor((N_eq - 1)/2); end
    handoff_index = N_train + delay;
    center_tap = floor((N_eq - 1) / 2) + 1;

    fig = figure('Name', fig_tag, 'NumberTitle', 'off', ...
                 'Color', 'w', 'Position', [100, 100, 1050, 440]);

    subplot(1, 2, 1);
    ax1 = gca;
    semilogy(ax1, iter_vec, mse_hist(1:N_plot), 'LineWidth', 2.0, 'Color', [0.00 0.45 0.74], ...
             'DisplayName', 'Smoothed MSE');
    hold(ax1, 'on');

    xline(ax1, handoff_index, '--r', 'LineWidth', 1.8, 'DisplayName', sprintf('DD After n = %d', handoff_index));

    set(ax1, 'Color', 'w', 'XColor', [0.15 0.15 0.15], 'YColor', [0.15 0.15 0.15], ...
             'LineWidth', 1.1, 'FontSize', 10, 'FontName', 'Helvetica');
    xlabel(ax1, 'Symbol Iteration (n)', 'FontSize', 11, 'FontWeight', 'bold', 'Color', [0.1 0.1 0.1]);
    ylabel(ax1, 'Mean Squared Error (MSE)', 'FontSize', 11, 'FontWeight', 'bold', 'Color', [0.1 0.1 0.1]);
    title(ax1, sprintf('LMS learning curve (\\mu = %.4f)', mu), ...
          'FontSize', 11, 'FontWeight', 'bold', 'Color', [0.05 0.05 0.05]);
    grid(ax1, 'on'); set(ax1, 'GridColor', [0.75 0.75 0.75], 'GridAlpha', 0.4);
    box(ax1, 'on');
    lgd1 = legend(ax1, 'Location', 'northeast', 'Color', 'w', 'EdgeColor', [0.8 0.8 0.8]);
    set(lgd1, 'TextColor', [0 0 0]);

    subplot(1, 2, 2);
    ax2 = gca;

    plot(ax2, iter_vec, real(w_hist(center_tap, 1:N_plot)), 'LineWidth', 2.2, ...
         'Color', [0.85 0.20 0.10], 'DisplayName', sprintf('Center Tap w_{%d} (Main)', center_tap-1));
    hold(ax2, 'on');

    if center_tap - 1 >= 1
        plot(ax2, iter_vec, real(w_hist(center_tap-1, 1:N_plot)), 'LineWidth', 1.6, ...
             'Color', [0.20 0.65 0.20], 'DisplayName', sprintf('Precursor w_{%d}', center_tap-2));
    end

    if center_tap + 1 <= N_eq
        plot(ax2, iter_vec, real(w_hist(center_tap+1, 1:N_plot)), 'LineWidth', 1.6, ...
             'Color', [0.50 0.10 0.80], 'DisplayName', sprintf('Postcursor w_{%d}', center_tap));
    end

    if center_tap + 2 <= N_eq
        plot(ax2, iter_vec, real(w_hist(center_tap+2, 1:N_plot)), 'LineWidth', 1.6, ...
             'Color', [0.90 0.60 0.00], 'DisplayName', sprintf('Postcursor w_{%d}', center_tap+1));
    end

    xline(ax2, handoff_index, '--r', 'LineWidth', 1.8, 'DisplayName', 'DD Handoff');

    set(ax2, 'Color', 'w', 'XColor', [0.15 0.15 0.15], 'YColor', [0.15 0.15 0.15], ...
             'LineWidth', 1.1, 'FontSize', 10, 'FontName', 'Helvetica');
    xlabel(ax2, 'Symbol Iteration (n)', 'FontSize', 11, 'FontWeight', 'bold', 'Color', [0.1 0.1 0.1]);
    ylabel(ax2, 'Real Part of Tap Weight', 'FontSize', 11, 'FontWeight', 'bold', 'Color', [0.1 0.1 0.1]);
    title(ax2, sprintf('%d-tap coefficient trajectories', N_eq), ...
          'FontSize', 11, 'FontWeight', 'bold', 'Color', [0.05 0.05 0.05]);
    grid(ax2, 'on'); set(ax2, 'GridColor', [0.75 0.75 0.75], 'GridAlpha', 0.4);
    box(ax2, 'on');
    lgd2 = legend(ax2, 'Location', 'southeast', 'Color', 'w', 'EdgeColor', [0.8 0.8 0.8]);
    set(lgd2, 'TextColor', [0 0 0]);
end
