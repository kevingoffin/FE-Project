function [sigma_hat_i, k_hat_i, eta_hat_i] = simulation(Rt, n_sim, deltaT, eta_hat, k_hat, sigma_hat)
% SIMULATION runs Monte Carlo simulations and re-estimates OU parameters
%
% Simulates multiple paths of an Ornstein-Uhlenbeck (OU) process from estimated parameters,
% and re-calibrates them to assess statistical estimation uncertainty.
%
% Inputs:
%   Rt        - Observed time series (used for initial condition and time length)
%   n_sim     - Number of Monte Carlo simulations
%   deltaT    - Time interval between observations
%   eta_hat   - Estimated long-run mean (η)
%   k_hat     - Estimated mean-reversion rate (κ)
%   sigma_hat - Estimated volatility (σ)
%
% Outputs:
%   sigma_hat_i - Simulated volatilities (1 × n_sim)
%   k_hat_i     - Simulated mean-reversion speeds (1 × n_sim)
%   eta_hat_i   - Simulated long-run means (1 × n_sim)

    %% 1. Convert continuous-time OU parameters to discrete-time AR(1) coefficients
    alpha = exp(-k_hat * deltaT);                         % Decay coefficient
    beta = 1 - alpha;                                     % Mean-reversion weight
    sd_noise = sigma_hat * sqrt((1 - alpha^2) / (2 * k_hat));  % Std of noise process
    
    %% 2. Simulate OU paths in vectorized form
    T = length(Rt);                          % Number of time steps
    X0 = Rt(1);                              
    noise = sd_noise * randn(T - 1, n_sim);  % Random innovations
    c = eta_hat * beta;                      % Constant term

    % Generate simulated OU paths using AR(1) filter: X_t = α X_{t−1} + c + ε_t
    X_tail = filter(1, [1, -alpha], c + noise);
    X = [X0 * ones(1, n_sim); X_tail];       % Add initial condition

    %% 3. Re-estimate OU parameters from each simulation
    eta_hat_i = zeros(1, n_sim);
    k_hat_i = zeros(1, n_sim);
    zeta_hat_i = zeros(1, n_sim);
    inv_Tm1 = 1 / (T - 1);

    parfor j = 1:n_sim
        x = X(:, j);                   % Single simulated path
        x_prev = x(1:end-1);
        x_next = x(2:end);

        % Sample moments
        mu_prev = mean(x_prev);
        mu_next = mean(x_next);
        var_prev = mean(x_prev.^2) - mu_prev^2;
        covar = mean(x_prev .* x_next) - mu_prev * mu_next;
        var_next = mean(x_next.^2) - mu_next^2;

        % Estimate kappa with protection against log(0) or negative
        ratio = max(covar / (var_prev + eps), eps);
        k_hat_i(j) = -(1 / deltaT) * log(ratio);

        % Estimate eta
        eta_hat_i(j) = mu_next + (x(end) - x(1)) * inv_Tm1 * covar / (var_prev - covar + eps);

        % Estimate residual variance (zeta)
        zeta_hat_i(j) = max(var_next - (covar^2 / (var_prev + eps)), 0);  % Ensure non-negativity
    end

    %% 4. Compute sigma from residual variance
    denom = max(1 - exp(-2 * k_hat_i * deltaT), eps);  % Avoid division by zero
    sigma_hat_i = sqrt((2 * zeta_hat_i .* k_hat_i) ./ denom);
end
