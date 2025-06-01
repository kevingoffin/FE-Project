function plot_leveragesVSreturns(f, rtn, opt_lev, mu_vector)
    % PLOT_LEVERAGESVSRETURNS Visualizes empirical and theoretical returns versus leverage
    %
    % Inputs:
    %   f         : Vector of leverage levels
    %   rtn       : Vector of empirical out-of-sample returns (in decimal form)
    %   opt_lev   : Optimal leverage (from theoretical optimization)
    %   mu_vector : Vector of theoretical returns for each leverage level

    % === 1. Plot Empirical Returns ===
    figure;
    plot(f, rtn * 100, '-o', 'LineWidth', 1.8, 'MarkerSize', 6, ...
         'Color', [0.2 0.4 0.7]);  % Convert to percentage
    hold on;

    % Highlight standard leverage levels
    xline(1, '--k', 'LineWidth', 1);
    xline(2, '--k', 'LineWidth', 1);
    xline(5, '--k', 'LineWidth', 1);

    % Mark optimal leverage
    xline(opt_lev, 'r', 'LineWidth', 2);
    yline(0, '--k', 'LineWidth', 0.8); % zero-return line

    % Add labels and styling
    xlabel('Leverage Level (f)', 'FontSize', 12);
    ylabel('Empirical OS Return (%)', 'FontSize', 12);
    title('Empirical Out-of-Sample Returns vs Leverage', 'FontSize', 14);
    legend('Empirical Return', 'Standard Leverages (1,2,5)', 'Optimal Leverage', ...
           'Location', 'best');
    grid on;
    box on;

    % === 2. Plot Theoretical Returns ===
    figure;
    plot(f, mu_vector * 100, '-s', 'LineWidth', 1.8, 'MarkerSize', 6, ...
         'Color', [0.1 0.6 0.3]);  % Convert to percentage
    hold on;

    % Highlight standard leverage levels
    xline(1, '--k', 'LineWidth', 1);
    xline(2, '--k', 'LineWidth', 1);
    xline(5, '--k', 'LineWidth', 1);

    % Mark optimal leverage
    xline(opt_lev, 'r', 'LineWidth', 2);
    yline(0, '--k', 'LineWidth', 0.8); % zero-return line

    % Add labels and styling
    xlabel('Leverage Level (f)', 'FontSize', 12);
    ylabel('Theoretical Return (%)', 'FontSize', 12);
    title('Theoretical Returns vs Leverage', 'FontSize', 14);
    legend('Theoretical Return', 'Standard Leverages (1,2,5)', 'Optimal Leverage', ...
           'Location', 'best');
    grid on;
    box on;
end
