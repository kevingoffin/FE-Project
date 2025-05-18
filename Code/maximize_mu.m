function [d_vals, u_vals] = maximize_mu(c_vals, l, sigma, theta, f)
% MAXIMIZE_MU Optimizes thresholds (d,u) to maximize expected return μ
% Inputs:
%   c_vals  - Array of transaction cost values
%   l       - Lower bound for d
%   sigma   - Volatility parameter
%   theta   - Time scaling parameter
%   flag    - 1: linear return model, else: logarithmic return model
%   f       - Leverage factor (used when flag ~= 1)
% Outputs:
%   d_vals  - Optimal d values for each c
%   u_vals  - Optimal u values for each c

    % === Define helper function erfid(x,y) via integral (real) ===
    % Computes difference of imaginary error functions
    erfid = @(x, y) erfi(x./sqrt(2)) - erfi(y./sqrt(2));
    
    % === Define objective function μ(d,u,c) ===
    if f == 1
        % Linear return model
        mu = @(d, u, c) (sigma/(theta*pi))*...
             (((u - d - c) ./ erfid(u, d)) + ...
              ((l - d - c) ./ erfid(d, l)));
    else 
        % Logarithmic return model with leverage
        mu = @(d, u, c) (1/(theta*pi))*...
             ((log(1+f*(exp(sigma*(u - d - c))-1)) ./ erfid(u, d)) + ...
              (log(1+f*(exp(sigma*(l - d - c))-1)) ./ erfid(d, l)));
    end
    
    % === Preallocate results ===
    n = length(c_vals);
    d_vals = zeros(n, 1);
    u_vals = zeros(n, 1);
    mu_vals = zeros(n, 1);
    
    % === Optimization for each c value ===
    for i = 1:n
        c = c_vals(i);
    
        % Objective to maximize (fmincon minimizes, so we negate)
        obj = @(x) -mu(x(1), x(2), c);   % x(1) = d, x(2) = u
    
        % Bounds (d > l, u > d + c)
        lb = [l + 0.01, l + c];  % d lower bound, u lower bound
        ub = [0.6, 3];           % d upper bound, u upper bound
    
        % Nonlinear constraints: u - d > c, d > l, d < u
        constraints = @(x) deal([c - (x(2) - x(1)); l - x(1); x(1) - x(2)], []);
    
        % Initial guess (reasonable starting point)
        x0 = [-0.5, 0.5];
    
        % Optimization options
        opts = optimoptions('fmincon', ...
            'Display', 'off', ...
            'Algorithm', 'interior-point', ...
            'MaxIterations', 500, ...
            'OptimalityTolerance', 1e-8);
    
        % Solve optimization problem
        try
            [xopt, fval] = fmincon(obj, x0, [], [], [], [], lb, ub, constraints, opts);
            d_vals(i) = xopt(1);
            u_vals(i) = xopt(2);
            mu_vals(i) = -fval;  % Return actual μ value (remove negation)
        catch
            % Handle failures (return NaN)
            d_vals(i) = NaN;
            u_vals(i) = NaN;
            mu_vals(i) = NaN;
        end
    end
end