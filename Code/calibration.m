function [eta_hat, k_hat, sigma_hat] = calibration(Rt, deltaT)
    % CALIBRATION Estimates Ornstein-Uhlenbeck (OU) process parameters from time series data
    %
    % Calibrates the OU process parameters using maximum likelihood estimation (MLE):
    %   dX_t = κ(η - X_t)dt + σdW_t
    %
    % Inputs:
    %   Rt     - Numeric vector of observed spread values (price ratio series)
    %   deltaT - Time step between observations (in years)
    %
    % Outputs:
    %   eta_hat   - Estimated mean-reversion level (η)
    %   k_hat     - Estimated mean-reversion speed (κ)
    %   sigma_hat - Estimated volatility (σ)

    %% Data Preparation
    x_min_one = Rt(1:end-1);  % Lagged values (X_{t-1})
    x_i = Rt(2:end);          % Current values (X_t)
    len = length(Rt)-1;       % Number of observed transitions

    %% Moment Calculations
    % First moments (means)
    Y_min = mean(x_min_one);   % E[X_{t-1}]
    Y_pls = mean(x_i);         % E[X_t]
    
    % Second moments
    Y_min_min = mean(x_min_one.^2);       % E[X_{t-1}^2]
    Y_pls_pls = mean(x_i.^2);             % E[X_t^2]
    Y_pls_min = (1/len) * sum(x_min_one.*x_i);  % E[X_{t-1}X_t] (autocovariance)
    
    %% OU Parameter Estimation
    % 1. Mean-reversion level (η)
    num = Y_pls_min - Y_min * Y_pls;  % Cov(X_t, X_{t-1})
    den = Y_min_min - Y_min^2;        % Var(X_{t-1})
    eta_hat = Y_pls + ((x_i(end) - x_min_one(1))/(len))*(num)/((den) - (num));
    
    % 2. Mean-reversion speed (κ)
    k_hat = -(1/deltaT)*log(num/den);  % Derived from OU autocorrelation function
    
    % 3. Volatility (σ)
    zeta_hat = Y_pls_pls - Y_pls^2 - num^2/den;  % Residual variance
    sigma_hat = sqrt((zeta_hat*2*k_hat)/(1-exp(-2*k_hat*deltaT)));  % OU variance formula
end