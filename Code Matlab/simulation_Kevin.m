function [sigma_hat_i, k_hat_i, eta_hat_i] = simulation_Kevin(Rt, n_sim, deltaT, eta_hat, k_hat, sigma_hat)
% SIMULATION Performs Monte Carlo simulations of an OU process and re-estimates parameters.
%
% Generates `n_sim` simulated paths based on an Ornstein-Uhlenbeck process and
% re-calibrates each path to assess estimation variability.
%
% Inputs:
%   Rt        - Observed time series (used for length and initial value)
%   n_sim     - Number of Monte Carlo simulations
%   deltaT    - Time increment (in years)
%   eta_hat   - Estimated long-run mean (η)
%   k_hat     - Estimated mean-reversion speed (κ)
%   sigma_hat - Estimated volatility (σ)
%
% Outputs:
%   sigma_hat_i - Vector of estimated volatilities from simulations (1 × n_sim)
%   k_hat_i     - Vector of estimated speeds (κ) from simulations
%   eta_hat_i   - Vector of estimated long-run means (η) from simulations

    %% Step 1: Discretize OU parameters
    alpha = exp(-k_hat * deltaT);  % Decay factor
    beta = 1 - alpha;
    sd_noise = sigma_hat * sqrt((1 - alpha^2) / (2 * k_hat));

    %% Step 2: Simulate OU paths (AR(1) form)
    T = length(Rt);
    X0 = Rt(1);
    noise = sd_noise * randn(T - 1, n_sim);
    c = eta_hat * beta;
    X_sim = [X0 * ones(1, n_sim); filter(1, [1, -alpha], c + noise)];

    %% Step 3: Re-estimate parameters for each simulation
    eta_hat_i = zeros(1, n_sim);
    k_hat_i   = zeros(1, n_sim);
    zeta_hat_i = zeros(1, n_sim);
    inv_T = 1 / (T - 1);

    parfor j = 1:n_sim
        x = X_sim(:, j);
        x_prev = x(1:end-1);
        x_next = x(2:end);

        % First and second moments
        mu_prev = mean(x_prev);
        mu_next = mean(x_next);
        var_prev = mean(x_prev.^2) - mu_prev^2;
        covar = mean(x_prev .* x_next) - mu_prev * mu_next;
        var_next = mean(x_next.^2) - mu_next^2;

        % Estimate κ with numerical safeguard
        ratio = max(covar / (var_prev + eps), eps);
        k_hat_i(j) = -(1 / deltaT) * log(ratio);

        % Estimate η
        eta_hat_i(j) = mu_next + (x(end) - x(1)) * inv_T * covar / (var_prev - covar + eps);

        % Estimate residual variance
        zeta_hat_i(j) = max(var_next - (covar^2 / (var_prev + eps)), 0);
    end

    %% Step 4: Recover σ from residual variance
    denom = max(1 - exp(-2 * k_hat_i * deltaT), eps);
    sigma_hat_i = sqrt((2 * k_hat_i .* zeta_hat_i) ./ denom);
end
