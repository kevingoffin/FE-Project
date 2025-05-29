function [ci_d, ci_u, ci_mu] = confidenceIntervalAdv(sigma_hat_i, k_hat_i, l, expected_C, f, alpha, CostUpperBound)
    % CONFIDENCEINTERVALADV Computes confidence intervals for trading strategy parameters
    % using bootstrapped estimates of OU process parameters.
    %
    % Inputs:
    %   sigma_hat_i : Vector of bootstrapped volatility estimates
    %   k_hat_i     : Vector of bootstrapped mean-reversion rate estimates
    %   l           : Stop-loss level
    %   expected_C  : Expected transaction cost
    %   f           : Trading frequency
    %
    % Outputs:
    %   ci_d  : 95% confidence interval for lower trading band (d*)
    %   ci_u  : 95% confidence interval for upper trading band (u*)
    %   ci_mu : 95% confidence interval for expected return (μ*)

    % === 1. Vectorized Parameter Calculations ===
    % Compute derived parameters for all bootstrap samples simultaneously
    SIGMA_vec = sigma_hat_i ./ sqrt(2 * k_hat_i);  % Stationary volatility
    theta_vec = 1 ./ k_hat_i;                      % Mean-reversion timescale
    c_bar_vec = expected_C ./ SIGMA_vec;           % Normalized transaction cost
    
    n = length(sigma_hat_i);  % Number of bootstrap samples

    % === 2. Setup Reduced Parameter Grid ===
    % Trade-off between accuracy and speed - reduced grid size for optimization
    c_vals = linspace(0.001, CostUpperBound, 20);  % Coarse grid of normalized costs
    n_c = length(c_vals);

    % === 3. Pre-allocate Memory ===
    % Stores optimal (d,u) pairs for each bootstrap sample and c value
    D_matrix = zeros(n, n_c);  % Will contain d* values
    U_matrix = zeros(n, n_c);  % Will contain u* values

    % === 4. Parallel Parameter Optimization ===
    % Compute optimal bands for all (bootstrap sample × c value) combinations
    fprintf('Computing maximize_mu for %d parameter sets...\n', n);
    parfor i = 1:n
        % Get optimal (d,u) for current bootstrap sample across all c_vals
        [D_matrix(i,:), U_matrix(i,:)] = maximize_mu(c_vals, l, SIGMA_vec(i), theta_vec(i), f);
    end

    % === 5. Interpolation to c_bar Values ===
    fprintf('Interpolating results...\n');
    d_star = zeros(n, 1);
    u_star = zeros(n, 1);
    
    parfor i = 1:n
        d_star(i) = interp1(c_vals, D_matrix(i,:), c_bar_vec(i), 'linear', 'extrap');
        u_star(i) = interp1(c_vals, U_matrix(i,:), c_bar_vec(i), 'linear', 'extrap');
    end
        
    % Compute expected return for these optimal bands
    mu_star = evaluate_mu(d_star, u_star, c_bar_vec, theta_vec, l, SIGMA_vec, f);

    % === 6. Compute Confidence Intervals ===
    % Extract 95% confidence intervals (2.5th to 97.5th percentiles)
    ci_d = prctile(d_star, [alpha * 50, 100 - alpha * 50]);   % CI for lower band
    ci_u = prctile(u_star, [alpha * 50, 100 - alpha * 50]);   % CI for upper band
    ci_mu = prctile(mu_star, [alpha * 50, 100 - alpha * 50]); % CI for expected return
end