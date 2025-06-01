function [eta_hat, k_hat, sigma_hat] = calibration(Rt, deltaT)
% CALIBRATION Estimate Ornstein-Uhlenbeck (OU) process parameters using MLE.
%
% Models the time series `Rt` as an OU process:
%   dX_t = κ(η - X_t)dt + σdW_t
%
% Inputs:
%   Rt     - Time series vector (e.g., price spread or log-price ratio)
%   deltaT - Time increment between observations (in years)
%
% Outputs:
%   eta_hat   - Estimated long-run mean (η)
%   k_hat     - Estimated mean-reversion speed (κ)
%   sigma_hat - Estimated volatility (σ)

    %% Step 1: Prepare Lagged Data
    x_prev = Rt(1:end-1);  % X_{t-1}
    x_curr = Rt(2:end);    % X_t
    N = length(x_prev);    % Number of transitions

    %% Step 2: Compute Sample Moments
    mu_prev = mean(x_prev);
    mu_curr = mean(x_curr);
    
    var_prev = mean(x_prev.^2) - mu_prev^2;
    covar = mean(x_prev .* x_curr) - mu_prev * mu_curr;
    var_resid = mean(x_curr.^2) - mu_curr^2 - (covar^2 / var_prev);

    %% Step 3: Estimate OU Parameters
    % Mean-reversion speed (kappa)
    k_hat = -log(covar / var_prev) / deltaT;
    
    % Long-run mean (eta)
    eta_hat = mu_curr + ((x_curr(end) - x_prev(1)) / N) * (covar / (var_prev - covar));
    
    % Volatility (sigma)
    sigma_hat = sqrt((2 * k_hat * var_resid) / (1 - exp(-2 * k_hat * deltaT)));

end