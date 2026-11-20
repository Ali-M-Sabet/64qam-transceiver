function [fig_step, fig_drift, fig_const] = plot_channel_tracking(...
            time_vec_step, h_step_mat, mse_lms_step, w_hist_step, ...
            time_vec_drift, h_drift_mat, evm_frozen_drift, evm_lms_drift, ...
            y_pre_lms, y_post_frozen, y_post_lms, y_drift_lms, switch_idx, mse_frozen_step)
% Plot step/drift tracking and the output constellations.

    %% Figure 11: Channel step
    fig_step = figure('Name', 'fig11_channel_step_tracking', 'NumberTitle', 'off', ...
                      'Color', 'w', 'Position', [100, 80, 1100, 750]);

    subplot(3, 1, 1);
    ax1 = gca;
    plot(ax1, time_vec_step, h_step_mat(1, :), 'LineWidth', 2.0, 'Color', [0 0.45 0.74], 'DisplayName', 'h_0 (Main Path)');
    hold(ax1, 'on');
    plot(ax1, time_vec_step, h_step_mat(2, :), 'LineWidth', 2.0, 'Color', [0.85 0.33 0.10], 'DisplayName', 'h_1 (Echo 1)');
    plot(ax1, time_vec_step, h_step_mat(3, :), 'LineWidth', 2.0, 'Color', [0.93 0.69 0.13], 'DisplayName', 'h_2 (Echo 2)');
    xline(ax1, switch_idx, '--r', 'LineWidth', 1.8, 'DisplayName', sprintf('Channel Switch (n = %d)', switch_idx));

    set(ax1, 'Color', 'w', 'XColor', [0.15 0.15 0.15], 'YColor', [0.15 0.15 0.15], ...
             'LineWidth', 1.1, 'FontSize', 10, 'FontName', 'Helvetica');
    ylabel(ax1, 'Channel Tap Gain', 'FontSize', 10, 'FontWeight', 'bold', 'Color', [0.1 0.1 0.1]);
    title(ax1, 'Channel transition (h_1 \rightarrow h_2 at n_{switch})', 'FontSize', 11, 'FontWeight', 'bold', 'Color', [0.05 0.05 0.05]);
    grid(ax1, 'on'); set(ax1, 'GridColor', [0.75 0.75 0.75], 'GridAlpha', 0.4);
    box(ax1, 'on');
    lgd1 = legend(ax1, 'Location', 'northeast', 'NumColumns', 2, 'Color', 'w', 'EdgeColor', [0.8 0.8 0.8]);
    set(lgd1, 'TextColor', [0 0 0]);
    xlim(ax1, [1, max(time_vec_step)]);

    subplot(3, 1, 2);
    ax2 = gca;
    if nargin >= 14 && ~isempty(mse_frozen_step)
        semilogy(ax2, time_vec_step, mse_frozen_step, 'r--', 'LineWidth', 1.8, 'DisplayName', 'Frozen MMSE (known-symbol error)');
        hold(ax2, 'on');
    end
    semilogy(ax2, time_vec_step, mse_lms_step, 'Color', [0.15 0.70 0.15], 'LineWidth', 1.8, 'DisplayName', 'Adaptive LMS (known-symbol error)');
    hold(ax2, 'on');
    xline(ax2, switch_idx, '--r', 'LineWidth', 1.8, 'DisplayName', 'Channel Switch Point');
    yline(ax2, 0.005, ':k', 'LineWidth', 1.2, 'DisplayName', 'MSE reference (0.005)');

    set(ax2, 'Color', 'w', 'XColor', [0.15 0.15 0.15], 'YColor', [0.15 0.15 0.15], ...
             'LineWidth', 1.1, 'FontSize', 10, 'FontName', 'Helvetica');
    ylabel(ax2, 'Smoothed true symbol MSE', 'FontSize', 10, 'FontWeight', 'bold', 'Color', [0.1 0.1 0.1]);
    title(ax2, 'Known-Symbol MSE After Channel Step', 'FontSize', 11, 'FontWeight', 'bold', 'Color', [0.05 0.05 0.05]);
    grid(ax2, 'on'); set(ax2, 'GridColor', [0.75 0.75 0.75], 'GridAlpha', 0.4);
    box(ax2, 'on');
    lgd2 = legend(ax2, 'Location', 'northeast', 'Color', 'w', 'EdgeColor', [0.8 0.8 0.8]);
    set(lgd2, 'TextColor', [0 0 0]);
    xlim(ax2, [1, max(time_vec_step)]);
    ylim(ax2, [1e-3, 2e-1]);

    subplot(3, 1, 3);
    ax3 = gca;
    center_tap = ceil(size(w_hist_step, 1)/2); % index 5 (w_4)
    plot(ax3, time_vec_step, real(w_hist_step(center_tap, :)), 'r-', 'LineWidth', 2.0, 'DisplayName', sprintf('Real(w_{%d}) [Main Center Tap]', center_tap-1));
    hold(ax3, 'on');
    if center_tap < size(w_hist_step, 1)
        plot(ax3, time_vec_step, real(w_hist_step(center_tap+1, :)), 'Color', [0.49 0.18 0.56], 'LineWidth', 2.0, 'DisplayName', sprintf('Real(w_{%d}) [Postcursor Tap]', center_tap));
    end
    if center_tap > 1
        plot(ax3, time_vec_step, real(w_hist_step(center_tap-1, :)), 'Color', [0 0.5 0], 'LineWidth', 1.5, 'DisplayName', sprintf('Real(w_{%d}) [Precursor Tap]', center_tap-2));
    end
    xline(ax3, switch_idx, '--r', 'LineWidth', 1.8, 'DisplayName', 'Channel Switch Point');

    set(ax3, 'Color', 'w', 'XColor', [0.15 0.15 0.15], 'YColor', [0.15 0.15 0.15], ...
             'LineWidth', 1.1, 'FontSize', 10, 'FontName', 'Helvetica');
    xlabel(ax3, 'Symbol Iteration n', 'FontSize', 10, 'FontWeight', 'bold', 'Color', [0.1 0.1 0.1]);
    ylabel(ax3, 'Tap Weight Value', 'FontSize', 10, 'FontWeight', 'bold', 'Color', [0.1 0.1 0.1]);
    title(ax3, 'Equalizer coefficient trajectories', 'FontSize', 11, 'FontWeight', 'bold', 'Color', [0.05 0.05 0.05]);
    grid(ax3, 'on'); set(ax3, 'GridColor', [0.75 0.75 0.75], 'GridAlpha', 0.4);
    box(ax3, 'on');
    lgd3 = legend(ax3, 'Location', 'east', 'NumColumns', 2, 'Color', 'w', 'EdgeColor', [0.8 0.8 0.8]);
    set(lgd3, 'TextColor', [0 0 0]);
    xlim(ax3, [1, max(time_vec_step)]);

    %% Figure 12: Channel drift
    fig_drift = figure('Name', 'fig12_channel_drift_tracking', 'NumberTitle', 'off', ...
                       'Color', 'w', 'Position', [120, 100, 1100, 600]);

    subplot(2, 1, 1);
    ax4 = gca;
    plot(ax4, time_vec_drift, h_drift_mat(1, :), 'b-', 'LineWidth', 2.0, 'DisplayName', 'h_0(t) [Main Path]');
    hold(ax4, 'on');
    plot(ax4, time_vec_drift, h_drift_mat(2, :), 'r-', 'LineWidth', 2.0, 'DisplayName', 'h_1(t) [Echo 1]');
    plot(ax4, time_vec_drift, h_drift_mat(3, :), 'g-', 'LineWidth', 2.0, 'DisplayName', 'h_2(t) [Echo 2]');

    set(ax4, 'Color', 'w', 'XColor', [0.15 0.15 0.15], 'YColor', [0.15 0.15 0.15], ...
             'LineWidth', 1.1, 'FontSize', 10, 'FontName', 'Helvetica');
    ylabel(ax4, 'Channel Tap Gain', 'FontSize', 10, 'FontWeight', 'bold', 'Color', [0.1 0.1 0.1]);
    title(ax4, 'Channel-tap drift', 'FontSize', 11, 'FontWeight', 'bold', 'Color', [0.05 0.05 0.05]);
    grid(ax4, 'on'); set(ax4, 'GridColor', [0.75 0.75 0.75], 'GridAlpha', 0.4);
    box(ax4, 'on');
    lgd4 = legend(ax4, 'Location', 'northeast', 'NumColumns', 3, 'Color', 'w', 'EdgeColor', [0.8 0.8 0.8]);
    set(lgd4, 'TextColor', [0 0 0]);
    xlim(ax4, [1, max(time_vec_drift)]);

    subplot(2, 1, 2);
    ax5 = gca;
    plot(ax5, time_vec_drift, evm_frozen_drift, 'r--', 'LineWidth', 2.0, 'DisplayName', 'Frozen MMSE');
    hold(ax5, 'on');
    plot(ax5, time_vec_drift, evm_lms_drift, 'b-', 'LineWidth', 2.0, 'DisplayName', 'Adaptive LMS (DD mode)');
    yline(ax5, 8.0, ':k', 'LineWidth', 1.6, 'DisplayName', '8% EVM design reference');

    set(ax5, 'Color', 'w', 'XColor', [0.15 0.15 0.15], 'YColor', [0.15 0.15 0.15], ...
             'LineWidth', 1.1, 'FontSize', 10, 'FontName', 'Helvetica');
    xlabel(ax5, 'Symbol Iteration n', 'FontSize', 10, 'FontWeight', 'bold', 'Color', [0.1 0.1 0.1]);
    ylabel(ax5, 'Block EVM (%)', 'FontSize', 10, 'FontWeight', 'bold', 'Color', [0.1 0.1 0.1]);
    title(ax5, 'Drift tracking: frozen MMSE and adaptive LMS', 'FontSize', 11, 'FontWeight', 'bold', 'Color', [0.05 0.05 0.05]);
    grid(ax5, 'on'); set(ax5, 'GridColor', [0.75 0.75 0.75], 'GridAlpha', 0.4);
    box(ax5, 'on');
    lgd5 = legend(ax5, 'Location', 'northwest', 'Color', 'w', 'EdgeColor', [0.8 0.8 0.8]);
    set(lgd5, 'TextColor', [0 0 0]);
    xlim(ax5, [1, max(time_vec_drift)]);
    ylim(ax5, [0, max(max(evm_frozen_drift)*1.15, 15)]);

    %% Figure 13: 4-Panel Constellation Comparison
    fig_const = figure('Name', 'fig13_tv_constellations_comparison', 'NumberTitle', 'off', ...
                       'Color', 'w', 'Position', [140, 120, 950, 850]);

    n_disp = min(5000, length(y_pre_lms));
    grid_bound = 1.6;

    subplot(2, 2, 1);
    ax6 = gca;
    plot(ax6, real(y_pre_lms(1:n_disp)), imag(y_pre_lms(1:n_disp)), '.', 'Color', [0 0.45 0.74], 'MarkerSize', 5);
    set(ax6, 'Color', 'w', 'XColor', [0.15 0.15 0.15], 'YColor', [0.15 0.15 0.15]);
    title(ax6, sprintf('1. Pre-Switch Channel h_1\nAdaptive LMS'), 'FontSize', 10, 'FontWeight', 'bold', 'Color', [0.05 0.05 0.05]);
    xlabel(ax6, 'In-Phase (I)', 'Color', [0.1 0.1 0.1]); ylabel(ax6, 'Quadrature (Q)', 'Color', [0.1 0.1 0.1]);
    xlim(ax6, [-grid_bound grid_bound]); ylim(ax6, [-grid_bound grid_bound]);
    axis(ax6, 'square'); grid(ax6, 'on'); box(ax6, 'on');

    subplot(2, 2, 2);
    ax7 = gca;
    plot(ax7, real(y_post_frozen(1:n_disp)), imag(y_post_frozen(1:n_disp)), '.', 'Color', [0.85 0.20 0.10], 'MarkerSize', 5);
    set(ax7, 'Color', 'w', 'XColor', [0.15 0.15 0.15], 'YColor', [0.15 0.15 0.15]);
    title(ax7, sprintf('2. Post-Switch Channel h_2\nFrozen MMSE'), 'FontSize', 10, 'FontWeight', 'bold', 'Color', [0.05 0.05 0.05]);
    xlabel(ax7, 'In-Phase (I)', 'Color', [0.1 0.1 0.1]); ylabel(ax7, 'Quadrature (Q)', 'Color', [0.1 0.1 0.1]);
    xlim(ax7, [-grid_bound grid_bound]); ylim(ax7, [-grid_bound grid_bound]);
    axis(ax7, 'square'); grid(ax7, 'on'); box(ax7, 'on');

    subplot(2, 2, 3);
    ax8 = gca;
    plot(ax8, real(y_post_lms(1:n_disp)), imag(y_post_lms(1:n_disp)), '.', 'Color', [0.20 0.70 0.20], 'MarkerSize', 5);
    set(ax8, 'Color', 'w', 'XColor', [0.15 0.15 0.15], 'YColor', [0.15 0.15 0.15]);
    title(ax8, sprintf('3. Post-Switch Channel h_2\nAdaptive LMS'), 'FontSize', 10, 'FontWeight', 'bold', 'Color', [0.05 0.05 0.05]);
    xlabel(ax8, 'In-Phase (I)', 'Color', [0.1 0.1 0.1]); ylabel(ax8, 'Quadrature (Q)', 'Color', [0.1 0.1 0.1]);
    xlim(ax8, [-grid_bound grid_bound]); ylim(ax8, [-grid_bound grid_bound]);
    axis(ax8, 'square'); grid(ax8, 'on'); box(ax8, 'on');

    subplot(2, 2, 4);
    ax9 = gca;
    plot(ax9, real(y_drift_lms(1:n_disp)), imag(y_drift_lms(1:n_disp)), '.', 'Color', [0.49 0.18 0.56], 'MarkerSize', 5);
    set(ax9, 'Color', 'w', 'XColor', [0.15 0.15 0.15], 'YColor', [0.15 0.15 0.15]);
    title(ax9, sprintf('4. Continuous Drift Channel\nAdaptive LMS'), 'FontSize', 10, 'FontWeight', 'bold', 'Color', [0.05 0.05 0.05]);
    xlabel(ax9, 'In-Phase (I)', 'Color', [0.1 0.1 0.1]); ylabel(ax9, 'Quadrature (Q)', 'Color', [0.1 0.1 0.1]);
    xlim(ax9, [-grid_bound grid_bound]); ylim(ax9, [-grid_bound grid_bound]);
    axis(ax9, 'square'); grid(ax9, 'on'); box(ax9, 'on');
end
