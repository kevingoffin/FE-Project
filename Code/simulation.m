function [sigma_hat_i, k_hat_i, eta_hat_i] = simulation(Rt_0, T, n_sim, deltaT, eta_hat, k_hat, sigma_hat,alpha_CI)
% SIMULATION Performs Monte Carlo simulation of a mean-reverting process and recalibrates parameters
%
% Inputs:
%   Rt_0      - First initial Rt values of the time series
%   n_sim     - Number of Monte Carlo simulations
%   deltaT    - Time step between observations
%   eta_hat   - Estimated long-term mean from calibration
%   k_hat     - Estimated mean reversion rate from calibration
%   sigma_hat - Estimated volatility from calibration
%   alpha_CI  - Parameter of the confidence interval
%
% Outputs:
%   sigma_hat_i - Recalibrated volatility for each simulation
%   k_hat_i     - Recalibrated mean reversion rate for each simulation
%   eta_hat_i   - Recalibrated long-term mean for each simulation
    
    % --- Precompute model parameters ---
    alpha = exp(-k_hat*deltaT);     % Decay factor: e^{-κΔt}
    beta = 1 - alpha;               % 1 - e^{-κΔt}
    sd = sigma_hat * sqrt((1 - alpha^2)/(2*k_hat));  % Scaled noise standard deviation

    % --- Monte Carlo Simulation ---
    eta_hat_i = zeros(1, n_sim);
    k_hat_i = zeros(1, n_sim);
    sigma_hat_i = zeros(1, n_sim);

    % Simulates the OU dynamics n_sim times
    X = zeros(T,1);
    for j = 1:n_sim
        % First value corresponds to Rt_0
        X(1) = Rt_0;

        % Ornstein-Uhlenbeck dynamics:
        X(2:end) = X(1:end-1)*alpha ...       % Mean-reverting component
                   + eta_hat*beta ...         % Long-term mean component
                   + sd*randn(T-1, 1);               % Random noise
        [eta_hat_i(j), k_hat_i(j), sigma_hat_i(j)] = calibration(X, deltaT);
    end

    % WEIIIIIIIRD
    eta_hat_i = real(eta_hat_i); k_hat_i = real(k_hat_i); sigma_hat_i = real(sigma_hat_i);
    
    % Display the distributions
    figure; histogram(k_hat_i, 100,'Normalization','pdf'); title('k\_hat');
    figure; histogram(sigma_hat_i, 100,'Normalization','pdf'); title('\sigma\_hat');
    figure; histogram(eta_hat_i, 100,'Normalization','pdf');  title('\eta\_hat');
    
    
    % Confidence Intervals 95%
    ci_k     = prctile(k_hat_i,     [alpha_CI, 100-alpha_CI]);
    ci_sigma = prctile(sigma_hat_i, [alpha_CI, 100-alpha_CI]);
    ci_eta   = prctile(eta_hat_i,   [alpha_CI, 100-alpha_CI]);
    
    fprintf('===Confidence intervals===\n')
    fprintf('95%% CI per k_hat:     [%.15f, %.15f]\n', ci_k(1),     ci_k(2));
    fprintf('95%% CI per sigma_hat: [%.15f, %.15f]\n', ci_sigma(1), ci_sigma(2));
    fprintf('95%% CI per eta_hat:   [%.15f, %.15f]\n', ci_eta(1),   ci_eta(2));
end