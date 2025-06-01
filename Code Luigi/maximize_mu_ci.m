function [d_vals, u_vals] = maximize_mu_ci(c_vals, l, sigma, theta, f)
    % MAXIMIZE_MU_CI Optimizes the (d,u) parameters to maximize μ(d,u) for given c values
    %
    % Inputs:
    %   c_vals  - Vector of concentration values to evaluate
    %   l       - Lower bound parameter
    %   sigma   - Standard deviation parameter
    %   theta   - Scaling parameter
    %   f       - Function handle for additional calculations
    %
    % Outputs:
    %   d_vals  - Optimized d values for each c in c_vals
    %   u_vals  - Optimized u values for each c in c_vals

    % Precompute constant terms for efficiency
    factor = 2 / (theta * pi);  % Normalization factor
    sqrt2 = sqrt(2);            % Precompute square root of 2
    
    % Create lookup table for erfi function to accelerate computations
    % We approximate erfi(x/sqrt(2)) using interpolation over a fixed grid
    x_min = -3; x_max = 3;                  % Domain for interpolation
    x_grid = linspace(x_min, x_max, 500);   % Grid points
    erfi_grid = erfi(x_grid);               % Precompute erfi values
    
    % Define efficient erfid function using interpolation
    % erfid(x,y) = erfi(x/sqrt(2)) - erfi(y/sqrt(2))
    erfid = @(x,y) interp_erfi(x, x_grid, erfi_grid, sqrt2) - ...
                   interp_erfi(y, x_grid, erfi_grid, sqrt2);

    % Initialize output arrays
    n = length(c_vals);
    d_vals = zeros(size(c_vals));
    u_vals = zeros(size(c_vals));
    x0_prev = [l + 0.1, l + mean(c_vals)];  % Initial guess for warm starting
    
    % Configure optimization settings (shared for all iterations)
    opts = optimoptions('fmincon',...
        'Display', 'none',...               % Suppress optimization output
        'Algorithm', 'sqp',...              % Sequential Quadratic Programming
        'MaxIterations', 150,...            % Limit iterations
        'SpecifyObjectiveGradient', false,...% No analytic gradient provided
        'OptimalityTolerance', 1e-5,...      % Stopping criteria
        'StepTolerance', 1e-5,...
        'UseParallel', false);

    % Main optimization loop for each concentration value
    for i = 1:n
        c = c_vals(i);
        
        % Linear constraints: A*x ≤ b
        % 1. u - d ≤ -c  (equivalent to d - u ≥ c)
        % 2. -d ≤ -l     (equivalent to d ≥ l)
        % 3. d - u ≤ 0   (equivalent to d ≤ u)
        A = [1, -1; -1, 0; 1, -1];
        b = [-c; -l; 0];
        
        % Dynamic bounds for optimization variables [d, u]
        lb = [l + 0.01, l + c];             % Lower bounds
        ub = [min(0.6, l + 2), 3];          % Upper bounds with safety limits
        
        % Objective function μ(d,u) to maximize
        % We minimize -μ to achieve maximization
        mu = @(x) factor * (...
            log_term(x(1), x(2), c, sigma, f) ./ erfid(x(2), x(1)) + ...
            log_term(x(1), l, c, sigma, f) ./ erfid(x(1), l));
        
        % Perform constrained optimization
        try
            [xopt, ~] = fmincon(@(x)-mu(x), x0_prev, A, b, [], [], lb, ub, [], opts);
            d_vals(i) = xopt(1);
            u_vals(i) = xopt(2);
            x0_prev = xopt;  % Update warm start for next iteration
        catch
            % Fallback linear interpolation if optimization fails
            d_vals(i) = interp1([0, max(c_vals)], [lb(1), ub(1)], c, 'linear');
            u_vals(i) = interp1([0, max(c_vals)], [lb(2), ub(2)], c, 'linear');
        end
    end
end