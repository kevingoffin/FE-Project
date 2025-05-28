function [d_vals, u_vals] = maximize_mu(c_vals, l, sigma, theta, f)
    % MAXIMIZE_MU Optimizes trading bands for statistical arbitrage strategy
    %
    % This function computes optimal entry (d) and exit (u) bands for a mean-reverting 
    % trading strategy with stop-loss and transaction costs, maximizing long-run returns.
    %
    % Inputs:
    %   c_vals  - Array of transaction costs (in price units)
    %   l       - Stop-loss level (negative value)
    %   sigma   - Volatility parameter of OU process
    %   theta   - Time-scale parameter (1/kappa)
    %   f       - Leverage factor (fraction of wealth invested)
    %
    % Outputs:
    %   d_vals  - Optimal entry levels for each transaction cost
    %   u_vals  - Optimal exit levels for each transaction cost

    % === Function erfid(x,y) via real integral ===
    % Calculates the difference between imaginary error functions
    % Used in OU process probability calculations
    erfid = @(x, y) erfi(x./sqrt(2)) - erfi(y./sqrt(2));

    % === Define the long-run return function ===
    % Computes the strategy's return given bands d (lower) and u (upper)
    % Incorporates: leverage (f), transaction costs (c), and OU parameters
    mu = @(d, u, c) (2/(theta*pi))*((log(1+f*(exp(sigma*(u - d - c))-1)) ./ erfid(u, d)) + ...
                    ((log(1+f*(exp(sigma*(l - d - c))-1)) ./ erfid(d, l))));

    % === Preallocate results ===
    length_c_vals = length(c_vals);
    d_vals = zeros(1, length_c_vals);  % Optimal lower bands (entry points)
    u_vals = zeros(1, length_c_vals);  % Optimal upper bands (exit points)
    % Note: mu_vals commented out as not returned, but available for debugging

    % Initial guess (reasonable starting point for optimization)
    % Chosen based on typical values for mean-reverting spreads
    x0 = [-0.5, 0.5];  % [d_initial, u_initial]
    
    % Optimization options for fmincon
    opts = optimoptions('fmincon', ...
                        'Display', 'off', ...          % Suppress output
                        'Algorithm', 'interior-point', ...  % Robust for constraints
                        'MaxIterations', 500, ...      % Sufficient for convergence
                        'OptimalityTolerance', 1e-8);  % High precision
    
    % === Parallel optimization loop ===
    % Uses parfor for efficient processing of multiple cost values
    parfor i = 1:length_c_vals
        c = c_vals(i);  % Current transaction cost
    
        % Objective function to maximize (fmincon minimizes, so we negate)
        obj = @(x) -mu(x(1), x(2), c);   % x(1) = d, x(2) = u
    
        % Lower and upper bounds:
        % - d must be slightly above stop-loss level (l)
        % - u must be above d plus transaction costs
        lb = [l + 0.01, l+c];  % Minimum values for [d, u]
        ub = [0.6, 3];         % Maximum values for [d, u]
    
        % Nonlinear constraints (must return [c, ceq]):
        % 1. u - d > c (exit must exceed entry by at least cost)
        % 2. d > l (entry must be above stop-loss)
        % 3. d < u (entry must be below exit)
        nonlcon = @(x) deal([c - (x(2) - x(1));  % u-d must exceed c
                             l - x(1);           % d must exceed l
                             x(1) - x(2)], []);  % d must be less than u
    
        % Solve constrained optimization problem
        try
            [xopt, ~] = fmincon(obj, x0, [], [], [], [], lb, ub, nonlcon, opts);
            
            % Store results
            d_vals(i) = xopt(1);    % Optimal entry level
            u_vals(i) = xopt(2);    % Optimal exit level
            % Note: Uncomment to store return values:
            % mu_vals(i) = -fval;   % Convert back to positive return
            
        catch
            % Handle optimization failures gracefully
            d_vals(i) = NaN;  % Mark failed optimizations
            u_vals(i) = NaN;
            % mu_vals(i) = NaN;
        end
    end
end