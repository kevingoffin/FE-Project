function [opt_lev] = optimalLeverage(SIGMA, theta, c, l, max_leverage)
    % OPTIMALLEVERAGE Computes the optimal leverage (f*) in a band trading strategy
    %
    % Inputs:
    %   SIGMA        - Stationary standard deviation of the OU process
    %   theta        - Mean reversion time scale (1/kappa)
    %   c            - Normalized transaction cost
    %   l            - Lower trading band (negative threshold)
    %   max_leverage - Maximum allowed leverage (risk control)
    %
    % Output:
    %   opt_lev      - Optimal leverage subject to maximum cap

    % === Auxiliary Function: Normalized imaginary error difference ===
    erfid = @(x, y) erfi(x / sqrt(2)) - erfi(y / sqrt(2));

    % === Transition Probabilities (Eq. 17) ===
    % Probability of exiting at upper band before lower band
    p_plus = @(d, u) erfid(d, l) / erfid(u, l);
    
    % Probability of exiting at lower band
    p_minus = @(d, u) 1 - p_plus(d, u);

    % === Payoff Functions (Eq. 7) ===
    % Return when exiting at upper band
    v_plus = @(d, u) exp(SIGMA * (u - d - c)) - 1;

    % Return when exiting at lower band (negative outcome)
    v_minus = @(d, u) exp(SIGMA * (l - d - c)) - 1;

    % === Optimal Leverage (Eq. 12) ===
    % Kelly-optimal leverage factor under the probabilistic setup
    f_star = @(d, u) -(p_plus(d, u) / v_minus(d, u) + p_minus(d, u) / v_plus(d, u));

    % === Expected Return (Eq. 23) ===
    % Average return per unit time across the band strategy
    mu = @(d, u) (2 / (theta * pi)) * ( ...
        log(1 + f_star(d, u) * v_plus(d, u)) / erfid(u, d) + ...
        log(1 + f_star(d, u) * v_minus(d, u)) / erfid(d, l) ...
    );

    % === Optimization Bounds ===
    % Constrain d and u:
    % - d must be below zero but above l
    % - u must be above d by at least c
    lb = [l + 0.01, l + c];  % Ensure separation between bands
    ub = [0, 3];             % d < 0, u > c + d

    % === Objective Function ===
    % We want to maximize expected return μ, so we minimize -μ
    objective = @(x) -mu(x(1), x(2));

    % === Initial Guess ===
    x0 = [-0.5, 0.5];  % Reasonable middle ground for d and u

    % === Optimization with fmincon ===
    options = optimoptions('fmincon', 'Display', 'off');  % Suppress output
    [opt_du, ~] = fmincon(objective, x0, [], [], [], [], lb, ub, [], options);

    % === Compute Final Optimal Leverage ===
    opt_d = opt_du(1);
    opt_u = opt_du(2);
    opt_f_star = f_star(opt_d, opt_u);         % Kelly-optimal leverage
    opt_lev = min(opt_f_star, max_leverage);   % Enforce leverage constraint

end
