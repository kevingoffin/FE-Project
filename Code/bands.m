function [u_star, d_star, mu_star] = bands(c_bar, l, SIGMA, theta, f_vec)
    % BANDS Computes optimal trading bands (u*, d*) and expected return rate (μ*)
    % for a pairs trading strategy given a vector of leverage values.
    %
    % Inputs:
    %   c_bar   - Normalized transaction cost (cost-to-volatility ratio)
    %   l       - Lower bound of spread (typically negative)
    %   SIGMA   - Stationary volatility of the Ornstein-Uhlenbeck (OU) process
    %   theta   - Mean-reversion timescale (theta = 1/k, where k is the mean-reversion rate)
    %   f_vec   - Vector of leverage levels to evaluate
    %
    % Outputs:
    %   u_star  - Vector of optimal upper trading bands (same length as f_vec)
    %   d_star  - Vector of optimal lower trading bands
    %   mu_star - Vector of expected return rates for each leverage

    % === 1. Define Grid of Candidate c Values ===
    % Create a fine grid of normalized cost values (c_vals) for band search
    c_vals = linspace(0.001, 0.75, 100);

    % === 2. Initialize Output Vectors ===
    n = length(f_vec);
    u_star = zeros(1, n);
    d_star = zeros(1, n);
    mu_star = zeros(1, n);

    % === 3. Loop Over Each Leverage Value ===
    for i = 1:n
        f = f_vec(i);

        % Compute optimal bands for all c_vals at current leverage
        [d_vals, u_vals] = maximize_mu(c_vals, l, SIGMA, theta, f);

        % Find index closest to input c_bar
        [~, idx] = min(abs(c_vals - c_bar));

        % Extract optimal bands for c_bar
        d_star(i) = d_vals(idx);
        u_star(i) = u_vals(idx);

        % Evaluate expected return at optimal bands
        mu_star(i) = evaluate_mu(d_star(i), u_star(i), c_bar, theta, l, SIGMA, f);
    end
end
