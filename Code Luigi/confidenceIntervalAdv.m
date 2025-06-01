function [ci_d, ci_u, ci_mu] = confidenceIntervalAdv(sigma_hat_i, k_hat_i, l, expected_C, f)
    % Vector parameters
    SIGMA_vec = sigma_hat_i ./ sqrt(2 * k_hat_i);
    theta_vec = 1 ./ k_hat_i;
    c_bar_vec = expected_C ./ SIGMA_vec;
    n = numel(sigma_hat_i);

    % Dynamically adjust c_vals based on c_bar_vec to minimize extrapolation
    c_min = min(c_bar_vec);
    c_max = max(c_bar_vec);
    buffer = 0.01 * (c_max - c_min); % 1% buffer
    c_min_adj = max(0.001, c_min - buffer);
    c_max_adj = c_max + buffer;
    c_vals = linspace(c_min_adj, c_max_adj, 15); % Reduced grid points

    % Preallocate result vectors
    d_star  = zeros(n, 1);
    u_star  = zeros(n, 1);
    mu_star = zeros(n, 1);

    % Parallel loop with optimized operations
    parfor i = 1:n
        % Vectorized grid processing for current i
        [D_i, U_i] = maximize_mu_ci(c_vals, l, SIGMA_vec(i), theta_vec(i), f);
        
        % Interpolation without extrapolation (ensure c_vals covers ci)
        ci = c_bar_vec(i);
        d_star(i) = interp1(c_vals, D_i, ci, 'linear');
        u_star(i) = interp1(c_vals, U_i, ci, 'linear');

        % Vectorized evaluation of mu
        mu_star(i) = evaluate_mu(d_star(i), u_star(i), ci, theta_vec(i), l, SIGMA_vec(i), f);
    end

    % Compute percentiles
    ci_d  = prctile(d_star,  [2.5, 97.5]);
    ci_u  = prctile(u_star,  [2.5, 97.5]);
    ci_mu = prctile(mu_star, [2.5, 97.5]);
end