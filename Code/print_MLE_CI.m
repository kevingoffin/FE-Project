function print_MLE_CI(k_hat, eta_hat, sigma_hat, alpha, ci_k, ci_sigma, ci_eta, k_hat_i, sigma_hat_i, eta_hat_i, start_hour, end_hour)
    % ==============================================================
    % FUNCTION:  print_MLE_CI
    % PURPOSE:   Plots histograms of MLE parameter distributions and prints 
    %            their confidence intervals (CIs) to the console.
    % INPUTS:
    %   - k_hat, eta_hat, sigma_hat: MLE estimates (scalars).
    %   - alpha: Significance level (e.g., 0.05 for 95% CIs).
    %   - ci_k, ci_sigma, ci_eta: Confidence intervals (2-element vectors).
    %   - k_hat_i, sigma_hat_i, eta_hat_i: Bootstrap/empirical distributions 
    %     of the parameters (vectors).
    %   - start: Identifier (e.g., sample size) for labeling CIs.
    % OUTPUTS:
    %   - Figures: Histograms with CIs marked.
    %   - Console: Printed MLE estimates and CIs.
    % ==============================================================

    % --- Plot histogram for k_hat distribution ---
    figure; 
    histogram(k_hat_i, 100, 'Normalization', 'pdf'); 
    title('Distribution of $\hat{k}$', 'Interpreter', 'latex', 'FontSize', 14);
    % Add left CI bound (lower percentile)
    xline(ci_k(1), 'r-', sprintf('%.2f%% = %.3f', 100*alpha/2, ci_k(1)), ...
          'LineWidth', 2, 'LabelHorizontalAlignment', 'left');
    % Add right CI bound (upper percentile)
    xline(ci_k(2), 'r-', sprintf('%.2f%% = %.3f', 100*(1-alpha/2), ci_k(2)), ...
          'LineWidth', 2, 'LabelHorizontalAlignment', 'right');

    % --- Plot histogram for sigma_hat distribution ---
    figure; 
    histogram(sigma_hat_i, 100, 'Normalization', 'pdf'); 
    title('Distribution of $\hat{\sigma}$', 'Interpreter', 'latex', 'FontSize', 14);
    % Add left CI bound (lower percentile)
    xline(ci_sigma(1), 'r-', sprintf('%.2f%% = %.3f', 100*alpha/2, ci_sigma(1)), ...
          'LineWidth', 2, 'LabelHorizontalAlignment', 'left');
    % Add right CI bound (upper percentile)
    xline(ci_sigma(2), 'r-', sprintf('%.2f%% = %.3f', 100*(1-alpha/2), ci_sigma(2)), ...
          'LineWidth', 2, 'LabelHorizontalAlignment', 'right');

    % --- Plot histogram for eta_hat distribution ---
    figure; 
    histogram(eta_hat_i, 100, 'Normalization', 'pdf');  
    title('Distribution of $\hat{\eta}$', 'Interpreter', 'latex', 'FontSize', 14);
    % Add left CI bound (lower percentile)
    xline(ci_eta(1), 'r-', sprintf('%.2f%% = %.3f', 100*alpha/2, ci_eta(1)), ...
          'LineWidth', 2, 'LabelHorizontalAlignment', 'left');
    % Add right CI bound (upper percentile)
    xline(ci_eta(2), 'r-', sprintf('%.2f%% = %.3f', 100*(1-alpha/2), ci_eta(2)), ...
          'LineWidth', 2, 'LabelHorizontalAlignment', 'right');

    % --- Print MLE estimates to console ---
    fprintf('===MLE Parameters===\n');
    fprintf('k_MLE:   %.15f\n', k_hat);
    fprintf('eta_MLE:   %.15f\n', eta_hat);
    fprintf('sigma_MLE:   %.15f\n', sigma_hat);

    % --- Print confidence intervals to console ---
    fprintf('===Confidence intervals for %.0f-%.0f===\n', start_hour, end_hour);
    fprintf('95%% CI per k_hat:     [%.15f, %.15f]\n', ci_k(1), ci_k(2));
    fprintf('95%% CI per eta_hat:   [%.15f, %.15f]\n', ci_eta(1), ci_eta(2));
    fprintf('95%% CI per sigma_hat: [%.15f, %.15f]\n', ci_sigma(1), ci_sigma(2));
end