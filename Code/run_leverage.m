function [opt_lev, rtn, mu_vector] = run_leverage(X_OS, SIGMA, theta, c_bar, l, f_max, sigma_hat_i, k_hat_i, expected_C, d_star, u_star, value)
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

    % === 2. Test Multiple Leverage Levels ===
    % Define leverage levels to test (including optimal and extreme values)
    f = [1, 5, 10, opt_lev, 28, 35, 50, 65, 75, 90, 120, 150, 200, 250, 300, 400, 600];
    mu_vector = zeros(length(f),1);  % Store theoretical returns
    rtn = zeros(length(f),1);        % Store empirical returns

    % Evaluate strategy at each leverage level
    for j = 1:length(f)
        % Recompute optimal bands for current leverage
        [u_star_lev, d_star_lev] = bands(c_bar, l, SIGMA, theta, f(j));
        
        % Calculate theoretical return (%)
        mu_vector(j) = evaluate_mu(d_star_lev, u_star_lev, c_bar, theta, l, SIGMA, f(j))*100;
        
        % Simulate actual returns (annualized with factor 6)
        rtn(j) = billionaire(X_OS, d_star_lev, u_star_lev, l, c_bar, SIGMA, f(j), 6);
    end

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
    [ci_d, ci_u, ci_mu] = confidence_interval(sigma_hat_i, k_hat_i, l, expected_C, 1);

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