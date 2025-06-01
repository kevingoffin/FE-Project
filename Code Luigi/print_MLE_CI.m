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

    %% Plot histograms with confidence intervals
    plot_histogram(k_hat_i,    ci_k,    'k',    'k');
    plot_histogram(sigma_hat_i, ci_sigma, 'sigma', '\sigma');
    plot_histogram(eta_hat_i,  ci_eta,  'eta',  '\eta');

    %% Console output: MLE and confidence intervals
    fprintf('=== MLE Estimates ===\n');
    fprintf('k_hat     = %.15f\n', k_hat);
    fprintf('eta_hat   = %.15f\n', eta_hat);
    fprintf('sigma_hat = %.15f\n\n', sigma_hat);

    fprintf('=== %.0f-%.0f Hour Confidence Intervals (%.0f%%) ===\n', ...
            start_hour, end_hour, 100 * (1 - alpha));
    fprintf('CI for k_hat:     [%.15f, %.15f]\n', ci_k(1), ci_k(2));
    fprintf('CI for eta_hat:   [%.15f, %.15f]\n', ci_eta(1), ci_eta(2));
    fprintf('CI for sigma_hat: [%.15f, %.15f]\n', ci_sigma(1), ci_sigma(2));
end