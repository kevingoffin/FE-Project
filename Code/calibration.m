function [eta_hat, k_hat, sigma_hat] = calibration(Rt_IS_NY_Filtered, deltaT)
% CALIBRATION Calibrates parameters (η, κ, σ) for a mean-reverting process using Rt data.
%
% Inputs:
%   Rt_IS_NY_Filtered - Input data (table or array) containing Rt values
%   deltaT            - Time step between observations (in consistent units)
%
% Outputs:
%   eta_hat    - Estimated long-term mean (η) of the process
%   k_hat      - Estimated mean reversion rate (κ)
%   sigma_hat  - Estimated volatility (σ)

    % --- DATA EXTRACTION ---
    % Input is a plain array
    x_i_minus_1 = Rt_IS_NY_Filtered(1:end-1);  % R_{t-1} values
    x_i = Rt_IS_NY_Filtered(2:end);          % R_t values
    len = size(Rt_IS_NY_Filtered,1) - 1;       % Number of observations

    % --- MOMENT CALCULATIONS ---
    Y_min = mean(x_i_minus_1);      % E[R_{t-1}]
    Y_pls = mean(x_i);              % E[R_t]

    Y_min_min = mean(x_i_minus_1.^2);  % E[R_{t-1}^2]
    Y_pls_pls = mean(x_i.^2);          % E[R_t^2]

    Y_min_plus = mean(x_i_minus_1.*x_i);  % Cross-moment E[R_{t-1}*R_t]

    % --- PARAMETER ESTIMATION ---
    % Numerator and denominator for κ calculation
    num = Y_min_plus - Y_min * Y_pls;  % Covariance-like term
    den = Y_min_min - Y_min^2;        % Variance-like term

    % 1. Estimate long-term mean (η)
    eta_hat = Y_pls + ((x_i(end) - x_i_minus_1(1))/len)*num/(den - num);

    % 2. Estimate residual variance (ζ)
    zeta_hat = Y_pls_pls - Y_pls^2 - num^2/den;

    % 3. Estimate mean reversion rate (κ)
    k_hat = -(1/deltaT)*log(num/den);      

    % 4. Estimate volatility (σ) from Ornstein-Uhlenbeck dynamics
    sigma_hat = sqrt((zeta_hat*2*k_hat)/(1-exp(-2*k_hat*deltaT)));
end