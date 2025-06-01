function [opt_lev, rtn, mu_vector] = run_leverage(X_OS, SIGMA, theta, c_bar, l, f_max, sigma_hat_i, k_hat_i, expected_C, d_star, u_star, value, f, w0, scaling_factor, verbose_optimizeReturn, alpha)
    % RUN_LEVERAGE Analyzes strategy performance across different leverage levels
    % and computes confidence intervals for key parameters.
    %
    % Inputs:
    %   X_OS        : Normalized out-of-sample spread process
    %   SIGMA       : Stationary volatility of OU process
    %   theta       : Mean-reversion timescale (1/k)
    %   c_bar       : Normalized transaction cost
    %   l           : Stop-loss level (in σ units)
    %   f_max       : Maximum allowed leverage
    %   sigma_hat_i : Bootstrapped volatility estimates
    %   k_hat_i     : Bootstrapped mean-reversion rates
    %   expected_C  : Expected transaction cost
    %   d_star      : Optimal lower trading band
    %   u_star      : Optimal upper trading band
    %   value       : Theoretical expected return
    %
    % Outputs:
    %   opt_lev    : Optimal leverage level
    %   rtn        : Vector of empirical returns for each leverage
    %   mu_vector  : Vector of theoretical returns for each leverage

    % === 1. Compute Optimal Leverage ===
    % Calculate theoretically optimal leverage based on strategy parameters
    [opt_lev] = optimalLeverage(SIGMA, theta, c_bar, l, f_max);
    f(end) = opt_lev; f = sort(f);

    % === 2. Test Multiple Leverage Levels ===
    [u_star_lev, d_star_lev] = bands(c_bar, l, SIGMA, theta, f);
    mu_vector = evaluate_mu(d_star_lev, u_star_lev, c_bar, theta, l, SIGMA, f) * 100;
    rtn = optimizedReturn(X_OS, d_star_lev, u_star_lev, l, c_bar, SIGMA, f, scaling_factor, w0, verbose_optimizeReturn);

    % === 3. Plot Empirical Returns vs Leverage ===
    figure;
    plot(f, rtn*100); 
    hold on;
    % Mark common leverage levels
    xline(1, '--', '1x');      % No leverage
    xline(2, '--', '2x');      % 2x leverage
    xline(5, '--', '5x');      % 5x leverage
    xline(opt_lev, "red", 'LineWidth', 1.5, 'Label', 'Optimal'); % Optimal leverage
    xlabel('Leverage Multiple');
    ylabel('Out-of-Sample Return (%)');
    title('Strategy Returns Across Leverage Levels');
    grid on;

    % === 4. Plot Theoretical Returns vs Leverage ===
    figure;
    plot(f, mu_vector); 
    hold on;
    xline(1, '--', '1x');
    xline(2, '--', '2x');
    xline(5, '--', '5x');
    xline(opt_lev, "red", 'LineWidth', 1.5, 'Label', 'Optimal');
    xlabel('Leverage Multiple');
    ylabel('Theoretical Return (%)');
    title('Expected Returns Across Leverage Levels');
    grid on;

    % === 5. Compute Confidence Intervals ===
    % Get 95% CIs for key parameters from bootstrap distributions
    n_ci = length(sigma_hat_i);
    u_star_ci = zeros(n_ci, 1);
    d_star_ci = zeros(n_ci, 1);
    mu_star_ci = zeros(n_ci, 1);
    SIGMA = sigma_hat_i ./ sqrt(2*k_hat_i);
    theta = 1./k_hat_i;
    c_bar = expected_C ./ SIGMA;
    for j=1:n_ci
        [u_star_ci(j), d_star_ci(j), mu_star_ci(j)] = bands(c_bar(j), l, SIGMA(j), theta(j), 1);
    end

    bound = alpha * 50;
    ci_d = prctile(d_star_ci,     [bound, 100 - bound]);
    ci_u = prctile(u_star_ci,     [bound, 100 - bound]);
    ci_mu = prctile(mu_star_ci,   [bound, 100 - bound]);

    % === 6. Display Key Results ===
    fprintf('\n=== Optimal Strategy Parameters ===\n');
    fprintf('d*: %.15f\n', d_star);
    fprintf('u*: %.15f\n', u_star);
    fprintf('μ:  %.15f\n\n', value);

    fprintf('=== 95%% Confidence Intervals ===\n');
    fprintf('d* CI: [%.15f, %.15f]\n', ci_d(1), ci_d(2));
    fprintf('u* CI: [%.15f, %.15f]\n', ci_u(1), ci_u(2));
    fprintf('μ CI:  [%.15f, %.15f]\n', ci_mu(1), ci_mu(2));
end