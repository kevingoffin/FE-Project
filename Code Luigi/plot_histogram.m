function plot_histogram(samples, ci, tex_label, alpha)
    % PLOT_HISTOGRAM Plots a histogram with confidence interval lines
    %
    % Inputs:
    %   samples    - Vector of simulated parameter values
    %   ci         - Confidence interval [lower, upper]
    %   tex_label  - LaTeX-formatted parameter name (e.g., 'k', '\eta')
    %   alpha      - Significance level (e.g., 0.05 for 95% CI)

    figure;
    histogram(samples, 100, 'Normalization', 'pdf');
    title(sprintf('Distribution of $\\hat{%s}$', tex_label), ...
          'Interpreter', 'latex', 'FontSize', 14);

    % Add CI lines
    xline(ci(1), 'r-', ...
          sprintf('%.1f%% = %.3f', 100 * alpha / 2, ci(1)), ...
          'LineWidth', 2, 'LabelHorizontalAlignment', 'left');
    xline(ci(2), 'r-', ...
          sprintf('%.1f%% = %.3f', 100 * (1 - alpha / 2), ci(2)), ...
          'LineWidth', 2, 'LabelHorizontalAlignment', 'right');
end
